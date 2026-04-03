# frozen_string_literal: true

require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Kakao < OmniAuth::Strategies::OAuth2
      option :name, "kakao"

      option :client_options, {
        site: "https://kauth.kakao.com",
        authorize_url: "/oauth/authorize",
        token_url: "/oauth/token",
        auth_scheme: :request_body
      }

      # Kakao API endpoint for user info
      option :user_info_url, "https://kapi.kakao.com/v2/user/me"

      uid { raw_info["id"].to_s }

      info do
        {
          name: kakao_account_profile["nickname"],
          email: kakao_account["email"],
          image: kakao_account_profile["profile_image_url"]
        }
      end

      extra do
        {
          raw_info: raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get(options.user_info_url).parsed
      end

      def kakao_account
        raw_info["kakao_account"] || {}
      end

      def kakao_account_profile
        kakao_account["profile"] || {}
      end

      # Kakao uses Bearer token in Authorization header
      def callback_url
        full_host + callback_path
      end
    end
  end
end
