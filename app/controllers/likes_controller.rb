class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    @post.likes.create(user: current_user)
    
    track_event("post_liked", {
      post_id: @post.id,
      post_type: @post.post_type,
      author_id: @post.user_id
    })
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  end

  def destroy
    @post.likes.find_by(user: current_user)&.destroy
    
    track_event("post_unliked", {
      post_id: @post.id,
      post_type: @post.post_type,
      author_id: @post.user_id
    })
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
