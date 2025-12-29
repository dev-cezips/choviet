module ReportsHelper
  def reportable_type_name(reportable)
    case reportable
    when Post
      current_user.vietnamese? ? "bài viết" : "게시글"
    when User
      current_user.vietnamese? ? "người dùng" : "사용자"
    when ConversationMessage
      current_user.vietnamese? ? "tin nhắn" : "메시지"
    else
      current_user.vietnamese? ? "nội dung" : "콘텐츠"
    end
  end

  def report_path_for(reportable)
    case reportable
    when Post
      new_post_report_path(reportable)
    when User
      new_user_report_path(reportable)
    when Message
      new_message_report_path(reportable)
    when ConversationMessage
      new_conversation_message_report_path(reportable)
    else
      "#"
    end
  end

  def report_categories_for_select
    if current_user.vietnamese?
      [
        [ "Spam / Quảng cáo", "spam" ],
        [ "Quấy rối / Lạm dụng", "harassment" ],
        [ "Lừa đảo", "fraud" ],
        [ "Nội dung không phù hợp", "inappropriate" ],
        [ "Khác", "other" ]
      ]
    else
      [
        [ "스팸 / 광고", "spam" ],
        [ "괴롭힘 / 남용", "harassment" ],
        [ "사기", "fraud" ],
        [ "부적절한 콘텐츠", "inappropriate" ],
        [ "기타", "other" ]
      ]
    end
  end
end
