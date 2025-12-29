class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_post, only: %i[ show edit update destroy ]

  # GET /posts or /posts.json
  def index
    @keyword = params[:q]
    @search_url = posts_path
    @posts = build_posts_query

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /feed - Location-based feed
  def feed
    @keyword = params[:q]
    @search_url = feed_posts_path

    # Try to show posts near user's location first
    if user_signed_in? && current_user.has_location?
      @posts = Post.active.near_location(current_user.latitude, current_user.longitude)
    else
      # Fallback to all active posts
      @posts = Post.active
    end

    # Apply filters
    @posts = apply_filters(@posts)

    # Include necessary associations
    @posts = @posts.includes(:user, :location, :product, images_attachments: :blob)

    # Paginate
    @posts = @posts.page(params[:page])

    render :index # Reuse index view
  end

  # GET /posts/1 or /posts/1.json
  def show
    # Increment view count
    @post.increment!(:views_count)

    track_event("post_viewed", {
      post_id: @post.id,
      post_type: @post.post_type,
      has_images: @post.images.attached?,
      author_id: @post.user_id
    })
  end

  # GET /posts/new
  def new
    @post = current_user.posts.build
    @post.post_type ||= "question" # Default to question type
    @post.location = current_user.location
    @post.latitude = current_user.latitude
    @post.longitude = current_user.longitude
    @post.build_product if @post.marketplace? # Initialize product only for marketplace posts
  end

  # GET /posts/1/edit
  def edit
    @post.build_product unless @post.product # Build product if it doesn't exist
  end

  # POST /posts or /posts.json
  def create
    Rails.logger.info "[CREATE] raw post_type: #{params.dig(:post, :post_type).inspect}"
    permitted_params = post_params
    Rails.logger.info "[CREATE] permitted params include product_attributes: #{permitted_params.key?(:product_attributes)}"
    @post = current_user.posts.build(permitted_params)

    # Whitelist and normalize post_type (2nd lock)
    type = @post.post_type.to_s
    @post.post_type = Post.post_types.key?(type) ? type : "question"
    Rails.logger.info "[CREATE] Final post_type after normalization: #{@post.post_type}"

    # Set location from current user if not provided
    if @post.latitude.blank? && current_user.has_location?
      @post.location = current_user.location
      @post.latitude = current_user.latitude
      @post.longitude = current_user.longitude
    end

    # Build product if marketplace but product attributes not provided
    if @post.marketplace? && !@post.product
      @post.build_product
    end

    # Final safety check - ensure no product for non-marketplace posts
    @post.product = nil unless @post.marketplace?

    # Handle draft saving
    if params[:commit] == "save_draft"
      @post.status = "draft"
    else
      @post.status = "active"
    end

    respond_to do |format|
      if @post.save
        track_event("post_created", {
          post_id: @post.id,
          post_type: @post.post_type,
          has_images: @post.images.attached?,
          has_location: @post.location.present?,
          target_korean: @post.target_korean,
          status: @post.status
        })

        if @post.draft?
          format.html { redirect_to edit_post_path(@post), notice: "Bài viết đã được lưu nháp!" }
        else
          format.html { redirect_to @post, notice: I18n.t("posts.created") }
        end
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    # Handle draft/publish status
    if params[:commit] == "save_draft"
      params[:post][:status] = "draft"
    elsif params[:commit] == "Cập nhật" && @post.draft?
      params[:post][:status] = "active"
    end

    respond_to do |format|
      if @post.update(post_params)
        if @post.draft?
          format.html { redirect_to edit_post_path(@post), notice: "Bài viết đã được lưu nháp!", status: :see_other }
        else
          format.html { redirect_to @post, notice: "Bài viết đã được cập nhật!", status: :see_other }
        end
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy!

    respond_to do |format|
      format.html { redirect_to posts_path, notice: "Post was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def post_params
      # Base parameters that are always allowed
      base_params = [ :title, :content, :post_type, :location_id,
                     :latitude, :longitude, :target_korean,
                     :community_id, :status, images: [] ]

      raw = params.dig(:post, :post_type).to_s

      # Get marketplace value from enum map to avoid hardcoding
      marketplace_value = Post.post_types.fetch("marketplace").to_s
      is_marketplace = (raw == "marketplace" || raw == marketplace_value)

      Rails.logger.info "[PARAMS] raw post_type=#{raw.inspect} marketplace_value=#{marketplace_value.inspect} is_marketplace=#{is_marketplace}"
      Rails.logger.info "[DEBUG] Post.post_types=#{Post.post_types.inspect}"

      # Only add product_attributes to permit list if it's a marketplace post
      permitted = if is_marketplace
        Rails.logger.info "[PARAMS] Permitting product_attributes for marketplace post"
        params.require(:post).permit(*base_params,
                                     product_attributes: [ :id, :name, :description, :price,
                                                         :condition, :currency, :_destroy ])
      else
        Rails.logger.info "[PARAMS] NOT permitting product_attributes"
        params.require(:post).permit(*base_params)
      end

      # Last safety check - remove product_attributes unless marketplace
      permitted.delete(:product_attributes) unless is_marketplace
      permitted
    end

    def build_posts_query
      posts = Post.active

      # Apply filters
      posts = apply_filters(posts)

      # Include associations
      posts.includes(:user, :location, :product, images_attachments: :blob)
    end

    def apply_filters(posts)
      # TODO: Extract to PostQuery or Posts::Query object to share with UsersController
      # Search keyword
      posts = posts.search_keyword(@keyword) if @keyword.present?

      # Filter by post type
      posts = posts.where(post_type: params[:type]) if params[:type].present?

      # Filter by location
      posts = posts.by_location_id(params[:location_id]) if params[:location_id].present?

      # Filter by price range (marketplace only)
      if params[:min_price].present? || params[:max_price].present?
        posts = posts.joins(:product)
        posts = posts.where("products.price >= ?", params[:min_price]) if params[:min_price].present?
        posts = posts.where("products.price <= ?", params[:max_price]) if params[:max_price].present?
      end

      # Filter by condition (marketplace only)
      if params[:condition].present?
        posts = posts.joins(:product).where(products: { condition: params[:condition] })
      end

      # Apply sorting
      case params[:sort]
      when "popular"
        posts = posts.by_popularity
      when "price_low"
        posts = posts.by_price_low_to_high
      when "price_high"
        posts = posts.by_price_high_to_low
      else
        posts = posts.recent # Default to newest first
      end

      posts
    end
end
