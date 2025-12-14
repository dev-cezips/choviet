class CommunitiesController < ApplicationController
  def index
    @communities = Community.public_communities.includes(:members)
    @communities = @communities.by_location(params[:location]) if params[:location].present?
  end

  def show
    @community = Community.find_by!(slug: params[:id])
    @posts = @community.posts.active.recent.includes(:user)
    @is_member = user_signed_in? && @community.member?(current_user)
  end
  
  def join
    @community = Community.find_by!(slug: params[:id])
    authenticate_user!
    
    if @community.add_member(current_user)
      redirect_to @community, notice: t('communities.joined')
    else
      redirect_to @community, alert: t('communities.join_error')
    end
  end
  
  def leave
    @community = Community.find_by!(slug: params[:id])
    authenticate_user!
    
    if @community.remove_member(current_user)
      redirect_to @community, notice: t('communities.left')
    else
      redirect_to @community, alert: t('communities.leave_error')
    end
  end
end
