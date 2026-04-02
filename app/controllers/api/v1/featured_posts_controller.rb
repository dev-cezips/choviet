# frozen_string_literal: true

module Api
  module V1
    class FeaturedPostsController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :verify_api_key

      # GET /api/v1/featured_posts
      # Returns featured posts for external services (Facebook agent, etc.)
      def index
        posts = Post.active
                    .marketplace_posts
                    .includes(:user, :location, images_attachments: :blob)
                    .by_popularity
                    .limit(params[:limit] || 10)

        # Filter by recency if requested
        if params[:since].present?
          posts = posts.where("posts.created_at > ?", Time.parse(params[:since]))
        end

        # Filter by category if requested
        if params[:category].present?
          posts = posts.joins(:product).where(products: { category: params[:category] })
        end

        render json: {
          posts: posts.map { |post| serialize_post(post) },
          total: posts.size,
          fetched_at: Time.current.iso8601
        }
      end

      # GET /api/v1/featured_posts/random
      # Returns random posts for variety in social media posting
      def random
        posts = Post.active
                    .marketplace_posts
                    .includes(:user, :location, images_attachments: :blob)
                    .where("posts.created_at > ?", 7.days.ago)
                    .order("RANDOM()")
                    .limit(params[:limit] || 5)

        render json: {
          posts: posts.map { |post| serialize_post(post) },
          total: posts.size,
          fetched_at: Time.current.iso8601
        }
      end

      private

      def verify_api_key
        api_key = request.headers["X-Api-Key"] || params[:api_key]

        unless api_key.present? && ActiveSupport::SecurityUtils.secure_compare(
          api_key,
          Rails.application.credentials.dig(:api, :agent_key) || ENV["CHOVIET_AGENT_API_KEY"] || ""
        )
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def serialize_post(post)
        {
          id: post.id,
          title: post.title,
          body: post.body.to_s.truncate(200),
          price: post.price,
          price_formatted: format_price(post.price),
          currency: "₩",
          location: post.location&.name_vi || post.location&.name_ko,
          user: {
            name: post.user.name || "Người dùng",
            reputation: post.user.reputation_score || 36.5
          },
          images: post.images.map { |img| rails_blob_url(img, only_path: false) rescue nil }.compact,
          url: "https://choviet.chat/posts/#{post.id}",
          created_at: post.created_at.iso8601,
          likes_count: post.likes_count,
          views_count: post.views_count
        }
      end

      def format_price(price)
        return "Thỏa thuận" if price.nil? || price.zero?
        "#{number_with_delimiter(price)}₩"
      end

      def number_with_delimiter(number)
        number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      end

      def rails_blob_url(blob, options = {})
        Rails.application.routes.url_helpers.rails_blob_url(blob, options.merge(host: "choviet.chat", protocol: "https"))
      end
    end
  end
end
