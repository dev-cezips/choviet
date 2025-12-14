json.extract! post, :id, :user_id, :category, :title, :content, :location_code, :target_korean, :status, :created_at, :updated_at
json.url post_url(post, format: :json)
