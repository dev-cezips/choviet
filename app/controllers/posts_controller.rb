class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
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
    @post.location = current_user.location
    @post.latitude = current_user.latitude
    @post.longitude = current_user.longitude
    @post.build_product # Initialize product for marketplace posts
  end

  # GET /posts/1/edit
  def edit
    @post.build_product unless @post.product # Build product if it doesn't exist
  end

  # POST /posts or /posts.json
  def create
    @post = current_user.posts.build(post_params)
    
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
    
    # Handle draft saving
    if params[:commit] == "save_draft"
      @post.status = 'draft'
    else
      @post.status = 'active'
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
          format.html { redirect_to edit_post_path(@post), notice: 'Bài viết đã được lưu nháp!' }
        else
          format.html { redirect_to @post, notice: I18n.t('posts.created') }
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
      params[:post][:status] = 'draft'
    elsif params[:commit] == "Cập nhật" && @post.draft?
      params[:post][:status] = 'active'
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
      params.require(:post).permit(:title, :content, :post_type, :location_id, 
                                   :latitude, :longitude, :target_korean, 
                                   :community_id, :status, images: [],
                                   product_attributes: [:id, :name, :description, :price, 
                                                       :condition, :currency, :_destroy])
    end
end
