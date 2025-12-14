class TranslateMessageJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find(message_id)
    
    # Don't translate if translation already exists
    return if message.content_translated.present?
    
    # Get sender and recipient locales
    sender = message.sender
    recipient = message.chat_room.other_user(sender)
    
    # Only translate if locales are different
    return if sender.locale == recipient.locale
    
    # Translate the message
    translated_content = translate_content(
      message.content_raw,
      from: sender.locale,
      to: recipient.locale
    )
    
    # Update message with translation
    message.update!(content_translated: translated_content)
    
    # Track translation event
    AnalyticsEvent.create!(
      user_id: sender.id,
      event_type: "translation_completed",
      properties: {
        message_id: message.id,
        chat_room_id: message.chat_room_id,
        original_length: message.content_raw.length,
        translated_length: translated_content.length,
        source_lang: sender.locale,
        target_lang: recipient.locale,
        contains_teencode: TranslationService.new.contains_teencode?(message.content_raw)
      },
      request_details: {}
    )
  rescue StandardError => e
    Rails.logger.error "Translation failed for message #{message_id}: #{e.message}"
    # Don't retry - show original message if translation fails
  end
  
  private
  
  def translate_content(text, from:, to:)
    # Use our translation service (mock for MVP, OpenAI in production)
    TranslationService.translate(text, from: from, to: to)
  end
end