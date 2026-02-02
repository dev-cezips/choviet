# frozen_string_literal: true

module Me
  class InquiriesController < ApplicationController
    before_action :authenticate_user!

    def index
      @status = params[:status].presence_in(%w[pending read replied]) || "all"

      @inquiries = current_user.received_inquiries
                               .includes(:sender, :post)
                               .order(created_at: :desc)

      @inquiries = @inquiries.where(status: @status) unless @status == "all"

      # 상태별 카운트 (필터 UI용)
      @counts = {
        all: current_user.received_inquiries.count,
        pending: current_user.received_inquiries.pending.count,
        read: current_user.received_inquiries.read.count,
        replied: current_user.received_inquiries.replied.count
      }
    end

    def show
      @inquiry = current_user.received_inquiries.find(params[:id])

      # 처음 보는 문의는 자동으로 읽음 처리
      @inquiry.mark_as_read! if @inquiry.pending?
    end

    def update
      @inquiry = current_user.received_inquiries.find(params[:id])

      case params[:inquiry][:status]
      when "replied"
        @inquiry.mark_as_replied!
        redirect_to me_inquiry_path(@inquiry), notice: t("inquiries.dashboard.marked_replied")
      when "converted"
        @inquiry.mark_as_converted!
        redirect_to me_inquiry_path(@inquiry), notice: t("inquiries.dashboard.marked_converted")
      else
        redirect_to me_inquiry_path(@inquiry), alert: t("inquiries.dashboard.invalid_status")
      end
    end
  end
end
