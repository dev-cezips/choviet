# frozen_string_literal: true

class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :check_onboarding_completed, only: [ :show, :update ]

  def show
    @step = params[:step]&.to_i || determine_current_step
    render_step(@step)
  end

  def update
    @step = params[:step].to_i

    case @step
    when 1
      # Language selection
      if params[:locale].present? && %w[vi ko en].include?(params[:locale])
        current_user.update(locale: params[:locale])
        I18n.locale = params[:locale]
        redirect_to onboarding_path(step: 2)
      else
        redirect_to onboarding_path(step: 1), alert: "Please select a language"
      end
    when 2
      # Location selection
      if params[:location_code].present?
        current_user.update(location_code: params[:location_code])
        redirect_to onboarding_path(step: 3)
      else
        redirect_to onboarding_path(step: 2), alert: "Please select a location"
      end
    when 3
      # Complete onboarding
      current_user.update(onboarding_completed: true)
      redirect_to root_path, notice: t("onboarding.complete")
    else
      redirect_to root_path
    end
  end

  def skip
    current_user.update(onboarding_completed: true)
    redirect_to root_path
  end

  private

  def check_onboarding_completed
    redirect_to root_path if current_user.onboarding_completed?
  end

  def determine_current_step
    return 1 if current_user.locale.blank?
    return 2 if current_user.location_code.blank?
    3
  end

  def render_step(step)
    case step
    when 1 then render :step_language
    when 2 then render :step_location
    when 3 then render :step_welcome
    else redirect_to root_path
    end
  end
end
