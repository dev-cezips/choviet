class Message < ApplicationRecord
  include Reportable

  belongs_to :chat_room
  belongs_to :sender, class_name: "User", foreign_key: "sender_id", optional: true

  # Validations
  validates :content_raw, presence: true, length: { maximum: 1000 }
  validates :src_lang, presence: true
  validates :sender, presence: true, unless: :system_message?

  # Callbacks
  before_validation :set_src_lang
  after_create :check_for_suspicious_content, unless: :system_message?

  # Turbo Stream broadcast with sender_id for echo bug prevention
  after_create_commit do
    # ActionCable을 통해 sender_id를 포함한 데이터 전송
    ChatRoomChannel.broadcast_to(
      chat_room,
      {
        html: ApplicationController.renderer.render(
          partial: "messages/message",
          locals: { message: self, current_user: nil }
        ),
        sender_id: sender_id,
        message_id: id
      }
    )
  end

  # Instance methods
  def display_content
    content_translated.presence || content_raw
  end

  def from_seller?
    sender_id == chat_room.seller_id
  end

  def from_buyer?
    sender_id == chat_room.buyer_id
  end

  def suspicious?
    ApplicationController.helpers.suspicious_message?(display_content)
  end

  private

  def set_src_lang
    self.src_lang ||= sender&.locale || "vi"
  end

  def check_for_suspicious_content
    return unless suspicious?

    # Count suspicious messages from this sender in this chat room
    suspicious_count = chat_room.messages
                               .where(sender_id: sender_id)
                               .where.not(id: id) # Don't count this message yet
                               .select { |m| m.suspicious? }
                               .count

    # If this is the 2nd suspicious message (1 previous + this one), create system message
    if suspicious_count == 1
      create_system_warning_message
    end
  end

  def create_system_warning_message
    # Create a system message (from the system, not from any user)
    system_message = chat_room.messages.create!(
      sender_id: nil, # System message has no sender
      content_raw: "⚠️ Hệ thống phát hiện các tin nhắn có thể không an toàn. Hãy cẩn thận với:\n• Yêu cầu chuyển tiền trước\n• Chia sẻ thông tin cá nhân\n• Giao dịch ngoài ứng dụng\n\nLuôn gặp mặt ở nơi công cộng và kiểm tra hàng trước khi thanh toán.",
      content_translated: "⚠️ System detected potentially unsafe messages. Please be careful with:\n• Requests for advance payment\n• Sharing personal information\n• Transactions outside the app\n\nAlways meet in public places and check items before payment.",
      src_lang: "vi",
      system_message: true
    )
  end
end
