class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :listings ]
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
    if @user.update(user_params)
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
end

