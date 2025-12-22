class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_post, only: %i[ show edit update destroy ]

  # GET /posts or /posts.json
  def index
    @keyword = params[:q]

    # For MVP, show all posts regardless of location
    @posts = Post.active
                 .includes(:user, :location, images_attachments: :blob)
                 .order(created_at: :desc)

    # Apply search filter if keyword present
    @posts = @posts.search_keyword(@keyword) if @keyword.present?

    # Filter by post type if specified
    @posts = @posts.where(post_type: params[:type]) if params[:type].present?

    # Paginate results
    @posts = @posts.page(params[:page])

    respond_to do |format|
      format.html
      format.turbo_stream
    end
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

    # Set default post_type if blank (safety net)
    @post.post_type = "question" if @post.post_type.blank?

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
end
