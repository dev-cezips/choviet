class StoriesController < ApplicationController
  def index
    # Users with stories, ordered by recent activity
    @users_with_stories = User.where.not(story: [nil, ""])
                              .includes(:posts, avatar_attachment: :blob)
                              .order(updated_at: :desc)
                              .page(params[:page])
                              .per(10)

    # For tab navigation
    @active_tab = :stories
  end
end
