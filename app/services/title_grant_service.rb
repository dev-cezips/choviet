class TitleGrantService
  def initialize(user)
    @user = user
  end
  
  def evaluate!
    grant_behavior_titles
    grant_seller_titles
    grant_community_titles
    grant_level_titles
  end
  
  private
  
  def grant(title_key)
    @user.grant_title!(title_key)
  end
  
  def grant_behavior_titles
    # Phản Hồi Nhanh - Reply within 3 minutes at least 10 times
    if quick_response_count >= 10
      grant(:quick_responder)
    end
    
    # Người Lịch Sự - Complete transactions politely
    if polite_transaction_count >= 5
      grant(:polite_person)
    end
    
    # Đúng Giờ - No late or no-show reports (placeholder - need report reason implementation)
    if @user.posts.count >= 5
      grant(:punctual)
    end
    
    # Người An Toàn - Never been reported (placeholder)
    if account_age_days >= 30
      grant(:safe_person)
    end
  end
  
  def grant_seller_titles
    # Người Bán Dễ Thương - 5 good reviews
    if good_review_count >= 5
      grant(:cute_seller)
    end
    
    # Người Bán Uy Tín - 10 successful transactions
    if successful_transaction_count >= 10
      grant(:trusted_seller)
    end
    
    # Siêu Người Bán - 10 consecutive 5-star reviews
    if consecutive_five_star_reviews >= 10
      grant(:super_seller)
    end
    
    # Bán Hàng An Tâm - Clean record
    if @user.posts.where(status: 'sold').count >= 5 && complaint_count == 0
      grant(:reliable_seller)
    end
  end
  
  def grant_community_titles
    # Người Giúp Đỡ - Answer 5 helpful questions
    if helpful_answers_count >= 5
      grant(:helper)
    end
    
    # Tấm Lòng Vàng - 30 thanks received
    if thanks_received_count >= 30
      grant(:golden_heart)
    end
    
    # Bảo Vệ Cộng Đồng - 3 accurate reports
    if accurate_reports_count >= 3
      grant(:community_guardian)
    end
    
    # Thành Viên Nhiệt Tình - Top 10% active users
    if in_top_activity_percentage?(10)
      grant(:enthusiastic_member)
    end
  end
  
  def grant_level_titles
    # Level titles are granted automatically when leveling up
    # This method can be used for special level-related achievements
    
    # Grant level titles based on current level
    Title.level_titles.for_level(@user.level).each do |title|
      grant(title.key)
    end
  end
  
  # Helper methods for checking conditions
  
  def quick_response_count
    # Count messages responded within 3 minutes
    # For now, return a placeholder
    0
  end
  
  def polite_transaction_count
    # Count transactions with positive feedback about politeness
    @user.posts.where(status: 'sold').count
  end
  
  def account_age_days
    (Date.current - @user.created_at.to_date).to_i
  end
  
  def good_review_count
    # Placeholder for review system
    @user.posts.where(status: 'sold').count
  end
  
  def successful_transaction_count
    @user.posts.where(status: 'sold').count
  end
  
  def consecutive_five_star_reviews
    # Placeholder for review system
    0
  end
  
  def complaint_count
    # Placeholder for complaint system
    0
  end
  
  def helpful_answers_count
    # Count helpful answers in Q&A posts
    @user.posts.where(post_type: 'question').count
  end
  
  def thanks_received_count
    # Placeholder for thanks system
    @user.likes.count
  end
  
  def accurate_reports_count
    # Placeholder for report system
    0
  end
  
  def in_top_activity_percentage?(percentage)
    # Check if user is in top X% of active users
    # Placeholder implementation
    @user.posts.count >= 10
  end
end