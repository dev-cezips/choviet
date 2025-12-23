class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    @favorite = current_user.favorites.build(post: @post)

    if @favorite.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("favorite_#{@post.id}", partial: "posts/favorite_button", locals: { post: @post }) }
        format.html { redirect_back(fallback_location: @post, notice: "Đã thêm vào danh sách yêu thích") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("favorite_#{@post.id}", partial: "posts/favorite_button", locals: { post: @post }) }
        format.html { redirect_back(fallback_location: @post, alert: "Không thể thêm vào danh sách yêu thích") }
      end
    end
  end

  def destroy
    @favorite = current_user.favorites.find_by(post: @post)

    if @favorite&.destroy
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("favorite_#{@post.id}", partial: "posts/favorite_button", locals: { post: @post }) }
        format.html { redirect_back(fallback_location: @post, notice: "Đã xóa khỏi danh sách yêu thích") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("favorite_#{@post.id}", partial: "posts/favorite_button", locals: { post: @post }) }
        format.html { redirect_back(fallback_location: @post, alert: "Không thể xóa khỏi danh sách yêu thích") }
      end
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
