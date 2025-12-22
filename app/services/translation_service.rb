class TranslationService
  # Teencode mapping for common Vietnamese slang
  TEENCODE_MAP = {
    "mjk" => "mình",
    "mjnh" => "mình",
    "m" => "mình",
    "bn" => "bạn",
    "b" => "bạn",
    "ko" => "không",
    "k" => "không",
    "hok" => "không",
    "hong" => "không",
    "dc" => "được",
    "đc" => "được",
    "z" => "vậy",
    "v" => "vậy",
    "vạy" => "vậy",
    "ck" => "chồng",
    "vk" => "vợ",
    "a" => "anh",
    "e" => "em",
    "c" => "chị",
    "j" => "gì",
    "r" => "rồi",
    "wa" => "quá",
    "oy" => "ơi",
    "uk" => "ừ",
    "uh" => "ừ",
    "ah" => "à",
    "ntn" => "như thế nào",
    "bik" => "biết",
    "bit" => "biết",
    "tks" => "thanks",
    "cam on" => "cảm ơn"
  }

  # For MVP, we'll use simple translation mappings
  # In production, this would call OpenAI API
  def self.translate(text, from:, to:)
    new.translate(text, from: from, to: to)
  end

  def translate(text, from:, to:)
    # Normalize teencode if Vietnamese
    normalized_text = from == "vi" ? self.class.normalize_teencode(text) : text

    # For MVP, return mock translations
    case [ from, to ]
    when [ "vi", "ko" ]
      self.class.translate_vi_to_ko(normalized_text)
    when [ "ko", "vi" ]
      self.class.translate_ko_to_vi(text)
    else
      text # Return original if unsupported language pair
    end
  end

  def contains_teencode?(text)
    return false unless text.present?

    # Check if any teencode patterns exist in the text
    TEENCODE_MAP.keys.any? { |teencode| text.downcase.include?(teencode) }
  end

  private

  def self.normalize_teencode(text)
    normalized = text.downcase

    # Replace teencode with standard Vietnamese
    TEENCODE_MAP.each do |teencode, standard|
      normalized = normalized.gsub(/\b#{teencode}\b/i, standard)
    end

    # Restore capitalization for first letter
    normalized[0] = normalized[0].upcase if normalized.present?
    normalized
  end

  def self.translate_vi_to_ko(text)
    # Mock translations for common phrases
    translations = {
      "xin chào" => "안녕하세요",
      "cảm ơn" => "감사합니다",
      "còn hàng không?" => "아직 있나요?",
      "giá bao nhiêu?" => "얼마예요?",
      "ở đâu?" => "어디에 있나요?",
      "khi nào?" => "언제요?",
      "được" => "됩니다",
      "không" => "안 됩니다",
      "tôi muốn mua" => "구매하고 싶습니다",
      "có thể xem hàng không?" => "물건을 볼 수 있나요?",
      "tình trạng thế nào?" => "상태가 어떤가요?"
    }

    # Try to find matching phrase
    normalized = text.downcase
    translations.each do |vi, ko|
      if normalized.include?(vi)
        return text.gsub(/#{vi}/i, ko)
      end
    end

    # Default translation with note
    "[번역됨] #{text}"
  end

  def self.translate_ko_to_vi(text)
    # Mock translations for common Korean phrases
    translations = {
      "안녕하세요" => "Xin chào",
      "감사합니다" => "Cảm ơn",
      "아직 있나요?" => "Còn hàng không?",
      "얼마예요?" => "Giá bao nhiêu?",
      "어디에 있나요?" => "Ở đâu?",
      "언제요?" => "Khi nào?",
      "됩니다" => "Được",
      "안 됩니다" => "Không được",
      "구매하고 싶습니다" => "Tôi muốn mua",
      "물건을 볼 수 있나요?" => "Có thể xem hàng không?",
      "상태가 어떤가요?" => "Tình trạng thế nào?"
    }

    # Try to find matching phrase
    translations.each do |ko, vi|
      if text.include?(ko)
        return text.gsub(ko, vi)
      end
    end

    # Default translation with note
    "[Đã dịch] #{text}"
  end
end
