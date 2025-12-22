# Titles Seed Data for ChợViệt

puts "Creating titles..."

# Behavior Titles
behavior_titles = [
  {
    key: 'polite_person',
    name_vi: 'Người Lịch Sự',
    description: 'Luôn giữ thái độ tốt khi giao dịch',
    category: 'behavior',
    icon: '🤝',
    color: 'blue'
  },
  {
    key: 'quick_responder',
    name_vi: 'Phản Hồi Nhanh',
    description: 'Trả lời tin nhắn < 3 phút trong ≥ 10 lần',
    category: 'behavior',
    icon: '⚡',
    color: 'yellow'
  },
  {
    key: 'punctual',
    name_vi: 'Đúng Giờ',
    description: 'Không có báo chậm trễ hoặc bom hàng',
    category: 'behavior',
    icon: '⏰',
    color: 'green'
  },
  {
    key: 'safe_person',
    name_vi: 'Người An Toàn',
    description: 'Chưa từng bị báo cáo từ người dùng khác',
    category: 'behavior',
    icon: '🛡️',
    color: 'green'
  }
]

# Seller Titles
seller_titles = [
  {
    key: 'cute_seller',
    name_vi: 'Người Bán Dễ Thương',
    description: 'Nhận nhiều lời khen "Thân thiện", "Tốt bụng"',
    category: 'seller',
    icon: '😊',
    color: 'pink'
  },
  {
    key: 'trusted_seller',
    name_vi: 'Người Bán Uy Tín',
    description: '10 giao dịch thành công, không có giao dịch hủy',
    category: 'seller',
    icon: '✅',
    color: 'blue'
  },
  {
    key: 'super_seller',
    name_vi: 'Siêu Người Bán',
    description: '10 đánh giá liền đạt 5★',
    category: 'seller',
    icon: '🌟',
    color: 'yellow'
  },
  {
    key: 'reliable_seller',
    name_vi: 'Bán Hàng An Tâm',
    description: 'Hồ sơ trong sạch, không có khiếu nại',
    category: 'seller',
    icon: '💯',
    color: 'green'
  }
]

# Community Titles
community_titles = [
  {
    key: 'helper',
    name_vi: 'Người Giúp Đỡ',
    description: '≥ 5 câu trả lời hữu ích trong mục Hỏi Đáp',
    category: 'community',
    icon: '🤲',
    color: 'blue'
  },
  {
    key: 'golden_heart',
    name_vi: 'Tấm Lòng Vàng',
    description: '≥ 30 lượt cảm ơn từ cộng đồng',
    category: 'community',
    icon: '💛',
    color: 'yellow'
  },
  {
    key: 'community_guardian',
    name_vi: 'Bảo Vệ Cộng Đồng',
    description: '≥ 3 báo cáo chính xác giúp làm sạch cộng đồng',
    category: 'community',
    icon: '🛡️',
    color: 'red'
  },
  {
    key: 'enthusiastic_member',
    name_vi: 'Thành Viên Nhiệt Tình',
    description: 'Top 10% tương tác trong cộng đồng',
    category: 'community',
    icon: '🔥',
    color: 'orange'
  }
]

# Level Titles
level_titles = [
  {
    key: 'newcomer',
    name_vi: 'Người Mới',
    description: 'Chào mừng đến với ChợViệt!',
    category: 'level',
    level_required: 1,
    icon: '🌱',
    color: 'gray'
  },
  {
    key: 'friendly_neighbor',
    name_vi: 'Hàng Xóm Thân Thiện',
    description: 'Đã quen thuộc với cộng đồng',
    category: 'level',
    level_required: 3,
    icon: '🏘️',
    color: 'green'
  },
  {
    key: 'choviet_citizen',
    name_vi: 'Cư Dân ChợViệt',
    description: 'Thành viên chính thức của cộng đồng',
    category: 'level',
    level_required: 5,
    icon: '🏪',
    color: 'blue'
  },
  {
    key: 'diligent_trader',
    name_vi: 'Người Giao Dịch Chăm Chỉ',
    description: 'Hoạt động tích cực trong chợ',
    category: 'level',
    level_required: 10,
    icon: '💼',
    color: 'purple'
  },
  {
    key: 'professional_seller',
    name_vi: 'Người Bán Chuyên Nghiệp',
    description: 'Người bán được tin tưởng',
    category: 'level',
    level_required: 15,
    icon: '🏆',
    color: 'gold'
  },
  {
    key: 'area_leader',
    name_vi: 'Trưởng Khu',
    description: 'Người dẫn đầu khu vực',
    category: 'level',
    level_required: 20,
    icon: '👑',
    color: 'purple'
  },
  {
    key: 'community_pillar',
    name_vi: 'Cột Trụ Cộng Đồng',
    description: 'Trụ cột của ChợViệt',
    category: 'level',
    level_required: 30,
    icon: '🏛️',
    color: 'indigo'
  },
  {
    key: 'choviet_president',
    name_vi: 'Hội Trưởng ChợViệt',
    description: 'Lãnh đạo cao nhất của cộng đồng',
    category: 'level',
    level_required: 40,
    icon: '🎖️',
    color: 'red'
  }
]

# Create all titles
all_titles = behavior_titles + seller_titles + community_titles + level_titles

all_titles.each do |title_data|
  Title.find_or_create_by!(key: title_data[:key]) do |title|
    title.name_vi = title_data[:name_vi]
    title.description = title_data[:description]
    title.category = title_data[:category]
    title.level_required = title_data[:level_required]
    title.icon = title_data[:icon]
    title.color = title_data[:color]
  end
end

puts "Created #{Title.count} titles!"

# Grant initial titles to existing users
puts "Granting initial titles to existing users..."

User.find_each do |user|
  # Grant level 1 title to all users
  user.grant_title!('newcomer')

  # Set it as primary if user has no primary title
  if user.primary_title.nil?
    user.set_primary_title!('newcomer')
  end

  # Run title evaluation
  TitleGrantService.new(user).evaluate!
end

puts "Title seeding complete!"
