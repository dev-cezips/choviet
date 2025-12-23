class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :listings, :favorites ]
  before_action :authenticate_user!, only: [ :edit, :update ]
  before_action :set_current_user, only: [ :edit, :update ]

  def show
    # 판매 중인 상품
    @selling_posts = @user.posts.where(status: "active").order(created_at: :desc)

    # 판매 완료된 상품
    @sold_posts = @user.posts.where(status: "sold").order(created_at: :desc).limit(5)

    # 통계
    @total_posts = @user.posts.count
    @total_sold = @user.posts.where(status: "sold").count
    @member_since_days = (Date.current - @user.created_at.to_date).to_i

    # 매너 온도 (일단 기본값 36.5로 시작)
    @manner_temp = @user.reputation_score || 36.5

    # 받은 좋아요 수
    @received_likes = @user.posts.joins(:likes).count
  end

  def edit
  end

  def update
    attrs = user_params.to_h

    # Auto-detect location from GPS coordinates if provided
    if attrs["latitude"].present? && attrs["longitude"].present?
      detected_location = detect_location_from_coordinates(
        attrs["latitude"].to_f,
        attrs["longitude"].to_f
      )

      # Inject detected location_code if not already provided
      if detected_location && attrs["location_code"].blank?
        attrs["location_code"] = detected_location.code
      end
    end

    if @user.update(attrs)
      redirect_to user_path(@user), notice: I18n.t("users.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def listings
    @posts = @user.posts.includes(:product, images_attachments: :blob)
                  .where(status: "active")
                  .order(created_at: :desc)
                  .page(params[:page])
  end

  def favorites
    @posts = @user.favorite_posts.active
                  .includes(:user, :product, :location, images_attachments: :blob)
                  .order("favorites.created_at DESC")
                  .page(params[:page])

    render "posts/index" # Reuse posts index view
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_current_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:name, :bio, :phone, :location_code, :avatar, :locale, :latitude, :longitude)
  end

  def detect_location_from_coordinates(lat, lng)
    # Simple distance-based detection
    # In a real app, you'd use geocoder gem with Location.near([lat, lng], radius).first

    locations = Location.all
    closest_location = nil
    min_distance = Float::INFINITY

    locations.each do |location|
      next unless location.lat && location.lng

      # Simple distance calculation (not accurate for large distances, but OK for Korea)
      distance = Math.sqrt((location.lat - lat)**2 + (location.lng - lng)**2)

      if distance < min_distance && distance < 0.5 # ~50km radius
        min_distance = distance
        closest_location = location
      end
    end

    closest_location
  end
end
