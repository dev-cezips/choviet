class PushEndpoint < ApplicationRecord
  belongs_to :user

  enum :platform, {
    web: 0,      # PWA/Web Push
    android: 1,  # FCM for Android
    ios: 2       # FCM via APNS for iOS
  }

  validates :token, presence: true
  validates :endpoint_url, presence: true, if: :web?
  validates :keys, presence: true, if: :web?

  # Ensure unique token per user/platform/device
  validates :token, uniqueness: {
    scope: [ :user_id, :platform ],
    conditions: -> { where(device_id: nil) },
    if: -> { device_id.nil? }
  }
  validates :device_id, uniqueness: {
    scope: [ :user_id, :platform ],
    allow_nil: true
  }

  scope :active, -> { where(active: true) }
  scope :web_push, -> { where(platform: :web) }
  scope :mobile_push, -> { where(platform: [ :android, :ios ]) }

  # Update last seen when endpoint is used
  def touch_last_seen!
    update_columns(last_seen_at: Time.current)
  end

  # Deactivate old endpoints (> 30 days)
  def self.deactivate_stale!
    where(active: true)
      .where("last_seen_at < ?", 30.days.ago)
      .update_all(active: false)
  end

  # Web push specific helpers
  def web_push_keys
    return {} unless web? && keys.present?
    {
      p256dh: keys["p256dh"],
      auth: keys["auth"]
    }
  end
end
