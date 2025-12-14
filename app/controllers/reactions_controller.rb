class ReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_review
  before_action :set_reaction, only: [:update, :destroy]
  
  def create
    @reaction = @review.review_reactions.build(reaction_params)
    @reaction.user = current_user
    
    if @reaction.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: update_reaction_ui }
        format.json { render json: { helpful_count: @review.helpful_count, unhelpful_count: @review.unhelpful_count } }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("review_#{@review.id}_error", partial: "shared/error", locals: { message: @reaction.errors.full_messages.first }) }
        format.json { render json: { error: @reaction.errors.full_messages.first }, status: :unprocessable_entity }
      end
    end
  end
  
  def update
    if @reaction.update(reaction_params)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: update_reaction_ui }
        format.json { render json: { helpful_count: @review.helpful_count, unhelpful_count: @review.unhelpful_count } }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("review_#{@review.id}_error", partial: "shared/error", locals: { message: @reaction.errors.full_messages.first }) }
        format.json { render json: { error: @reaction.errors.full_messages.first }, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @reaction.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: update_reaction_ui }
      format.json { render json: { helpful_count: @review.helpful_count, unhelpful_count: @review.unhelpful_count } }
    end
  end
  
  private
  
  def set_review
    @review = Review.find(params[:review_id])
  end
  
  def set_reaction
    @reaction = @review.review_reactions.find_by(user: current_user)
    redirect_to root_path, alert: "Reaction not found" unless @reaction
  end
  
  def reaction_params
    params.require(:review_reaction).permit(:helpful)
  end
  
  def update_reaction_ui
    turbo_stream.replace("review_#{@review.id}_reactions", 
                        partial: "reviews/reaction_buttons", 
                        locals: { review: @review })
  end
end