class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @my_posts = current_user.posts.where(status: 'active').order(created_at: :desc)
    @draft_posts = current_user.posts.where(status: 'draft').order(updated_at: :desc)
    @liked_posts = current_user.likes.includes(:post).map(&:post)
  end
end