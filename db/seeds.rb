# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating locations..."

# Create main cities
seoul = Location.find_or_create_by!(code: "seoul") do |location|
  location.name_ko = "서울"
  location.name_vi = "Seoul"
  location.lat = 37.5665
  location.lng = 126.9780
  location.level = 1
end

gyeonggi = Location.find_or_create_by!(code: "gyeonggi") do |location|
  location.name_ko = "경기도"
  location.name_vi = "Gyeonggi"
  location.lat = 37.4138
  location.lng = 127.5183
  location.level = 1
end

# Create districts
ansan = Location.find_or_create_by!(code: "ansan") do |location|
  location.name_ko = "안산시"
  location.name_vi = "Ansan"
  location.lat = 37.3236
  location.lng = 126.8219
  location.parent = gyeonggi
  location.level = 2
end

suwon = Location.find_or_create_by!(code: "suwon") do |location|
  location.name_ko = "수원시"
  location.name_vi = "Suwon"
  location.lat = 37.2636
  location.lng = 127.0286
  location.parent = gyeonggi
  location.level = 2
end

# Seoul districts
gangnam = Location.find_or_create_by!(code: "gangnam") do |location|
  location.name_ko = "강남구"
  location.name_vi = "Gangnam"
  location.lat = 37.5172
  location.lng = 127.0473
  location.parent = seoul
  location.level = 2
end

dongdaemun = Location.find_or_create_by!(code: "dongdaemun") do |location|
  location.name_ko = "동대문구"
  location.name_vi = "Dongdaemun"
  location.lat = 37.5744
  location.lng = 127.0396
  location.parent = seoul
  location.level = 2
end

puts "Creating categories..."

# Root categories
marketplace_category = Category.find_or_create_by!(name_vi: "Mua bán") do |category|
  category.name_ko = "중고거래"
  category.icon = "shopping-cart"
  category.position = 1
end

community_category = Category.find_or_create_by!(name_vi: "Cộng đồng") do |category|
  category.name_ko = "커뮤니티"
  category.icon = "users"
  category.position = 2
end

job_category = Category.find_or_create_by!(name_vi: "Việc làm") do |category|
  category.name_ko = "구인구직"
  category.icon = "briefcase"
  category.position = 3
end

housing_category = Category.find_or_create_by!(name_vi: "Nhà ở") do |category|
  category.name_ko = "부동산"
  category.icon = "home"
  category.position = 4
end

# Subcategories for marketplace
Category.find_or_create_by!(name_vi: "Điện tử", parent: marketplace_category) do |category|
  category.name_ko = "전자제품"
  category.icon = "laptop"
  category.position = 1
end

Category.find_or_create_by!(name_vi: "Thời trang", parent: marketplace_category) do |category|
  category.name_ko = "패션"
  category.icon = "tshirt"
  category.position = 2
end

Category.find_or_create_by!(name_vi: "Nội thất", parent: marketplace_category) do |category|
  category.name_ko = "가구"
  category.icon = "couch"
  category.position = 3
end

Category.find_or_create_by!(name_vi: "Thực phẩm Việt", parent: marketplace_category) do |category|
  category.name_ko = "베트남 식품"
  category.icon = "utensils"
  category.position = 4
end

puts "Creating communities..."

# Communities
ansan_viet = Community.find_or_create_by!(slug: "nguoi-viet-ansan") do |community|
  community.name = "Người Việt Ansan"
  community.description = "Cộng đồng người Việt tại Ansan, Gyeonggi"
  community.location_code = "ansan"
  community.member_count = 0
  community.is_private = false
end

seoul_students = Community.find_or_create_by!(slug: "sinh-vien-viet-seoul") do |community|
  community.name = "Sinh viên Việt Seoul"
  community.description = "Nhóm sinh viên và du học sinh Việt Nam tại Seoul"
  community.location_code = "seoul"
  community.member_count = 0
  community.is_private = false
end

viet_moms = Community.find_or_create_by!(slug: "me-viet-tai-han") do |community|
  community.name = "Mẹ Việt tại Hàn"
  community.description = "Cộng đồng các mẹ Việt Nam đang sinh sống tại Hàn Quốc"
  community.location_code = "all"
  community.member_count = 0
  community.is_private = false
end

puts "Creating users..."

# Create admin user
admin = User.find_or_create_by!(email: "admin@choviet.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.name = "Admin Chợ Việt"
  user.locale = "vi"
  user.admin = true
  user.location_code = "seoul"
  user.location = seoul
  user.latitude = 37.5665
  user.longitude = 126.9780
  user.location_radius = 5
  user.phone = "010-0000-0000"
  user.bio = "Quản trị viên Chợ Việt"
  user.verified = true
  user.reputation_score = 100
end
puts "  Created admin user: #{admin.email}"

# Vietnamese users
lien = User.find_or_create_by!(email: "lien@example.com") do |user|
  user.password = "password123"
  user.name = "Trần Thị Liên"
  user.locale = "vi"
  user.location_code = "ansan"
  user.location = ansan
  user.latitude = 37.3219
  user.longitude = 126.8308
  user.location_radius = 3
  user.phone = "010-1234-5678"
  user.bio = "Mẹ bỉm sữa tại Ansan. Rất vui được làm quen với mọi người!"
  user.verified = true
  user.reputation_score = 85
end

minh = User.find_or_create_by!(email: "minh@example.com") do |user|
  user.password = "password123"
  user.name = "Nguyễn Văn Minh"
  user.locale = "vi"
  user.location_code = "dongdaemun"
  user.location = dongdaemun
  user.latitude = 37.5838
  user.longitude = 127.0507
  user.location_radius = 5
  user.phone = "010-9876-5432"
  user.bio = "Sinh viên năm 3 tại Seoul. Thích khám phá ẩm thực và giao lưu."
  user.verified = false
  user.reputation_score = 45
end

# Korean user
korean_user = User.find_or_create_by!(email: "korean@example.com") do |user|
  user.password = "password123"
  user.name = "김민수"
  user.locale = "ko"
  user.location_code = "gangnam"
  user.location = gangnam
  user.latitude = 37.4979
  user.longitude = 127.0276
  user.location_radius = 5
  user.phone = "010-5555-6666"
  user.bio = "베트남 문화에 관심이 많은 한국인입니다."
  user.verified = true
  user.reputation_score = 60
end

puts "Adding users to communities..."

# Add members to communities
ansan_viet.add_member(lien, 'admin') unless ansan_viet.members.include?(lien)
seoul_students.add_member(minh, 'admin') unless seoul_students.members.include?(minh)
viet_moms.add_member(lien, 'member') unless viet_moms.members.include?(lien)
seoul_students.add_member(korean_user, 'member') unless seoul_students.members.include?(korean_user)

puts "Creating posts..."

# Clear existing posts and products to ensure fresh data
Post.destroy_all
Product.destroy_all

# Marketplace post by Lien
post1 = Post.create!(
  user: lien,
  post_type: "marketplace",
  community: ansan_viet,
  title: "Bán xe đạp cho bé",
  content: "Mình cần bán xe đạp cho bé 4-6 tuổi. Mua được 6 tháng, còn rất mới. 
  Lý do bán: con mình lớn nhanh quá không vừa nữa.
  
  - Màu hồng xinh xắn
  - Có bánh phụ 2 bên
  - Giỏ xe phía trước
  - Còn nguyên hộp và phiếu bảo hành
  
  Giá: 50,000 won (mua mới 120,000 won)
  Địa điểm: Gần ga Ansan
  
  Liên hệ qua tin nhắn nhé!",
  location_code: "ansan",
  location: ansan,
  latitude: lien.latitude,
  longitude: lien.longitude,
  target_korean: false,
  status: "active"
)

# Create product for the marketplace post
Product.create!(
  post: post1,
  name: "Xe đạp trẻ em màu hồng",
  description: "Xe đạp cho bé 4-6 tuổi, còn rất mới",
  price: 50000,
  currency: "KRW",
  condition: "like_new",
  sold: false
)

# Community post by Minh
post2 = Post.create!(
  user: minh,
  post_type: "free_talk",
  community: seoul_students,
  title: "Tìm bạn cùng học tiếng Hàn",
  content: "Hello mọi người! Mình đang học TOPIK level 3, muốn tìm bạn cùng luyện speaking và writing.

  Mình có thể:
  - Học cùng nhau ở thư viện
  - Chia sẻ tài liệu
  - Luyện tập hội thoại
  
  Ai quan tâm thì comment hoặc nhắn tin cho mình nhé!
  카톡 ID: vietminh23",
  location_code: "dongdaemun",
  location: dongdaemun,
  latitude: minh.latitude,
  longitude: minh.longitude,
  target_korean: false,
  status: "active"
)

# Question post
post3 = Post.create!(
  user: korean_user,
  post_type: "question",
  community: seoul_students,
  title: "베트남 음식점 추천해주세요",
  content: "강남 근처에 맛있는 베트남 음식점 있나요?
  
  특히 쌀국수(포)와 반미를 잘하는 곳을 찾고 있어요.
  가격대는 상관없습니다.
  
  추천 부탁드립니다!",
  location_code: "gangnam",
  location: gangnam,
  latitude: korean_user.latitude,
  longitude: korean_user.longitude,
  target_korean: false,
  status: "active"
)

puts "Creating quick replies..."

# Clear existing quick replies to ensure fresh data
QuickReply.destroy_all

QuickReply.create!([
  { category: "greeting", content_vi: "Xin chào!", content_ko: "안녕하세요!" },
  { category: "greeting", content_vi: "Chào bạn!", content_ko: "안녕!" },
  { category: "availability", content_vi: "Còn hàng không ạ?", content_ko: "아직 있나요?" },
  { category: "availability", content_vi: "Đã bán chưa?", content_ko: "팔렸나요?" },
  { category: "price", content_vi: "Giá có thương lượng không?", content_ko: "가격 협의 가능한가요?" },
  { category: "price", content_vi: "Giá cố định ạ?", content_ko: "가격은 고정인가요?" },
  { category: "location", content_vi: "Ở khu vực nào vậy?", content_ko: "어느 지역인가요?" },
  { category: "location", content_vi: "Giao hàng được không?", content_ko: "배송 가능한가요?" },
  { category: "condition", content_vi: "Tình trạng thế nào?", content_ko: "상태가 어떤가요?" },
  { category: "condition", content_vi: "Dùng được bao lâu rồi?", content_ko: "사용한지 얼마나 되었나요?" },
  { category: "thanks", content_vi: "Cảm ơn bạn!", content_ko: "감사합니다!" },
  { category: "thanks", content_vi: "Cảm ơn nhiều!", content_ko: "정말 감사합니다!" },
  { category: "interest", content_vi: "Mình quan tâm", content_ko: "관심있습니다" },
  { category: "interest", content_vi: "Mình muốn mua", content_ko: "구매하고 싶습니다" },
  { category: "meeting", content_vi: "Khi nào gặp được?", content_ko: "언제 만날 수 있나요?" },
  { category: "meeting", content_vi: "Hẹn cuối tuần được không?", content_ko: "주말에 만날 수 있나요?" }
])

puts "Seed data created successfully!"
puts "Created:"
puts "- #{Location.count} locations"
puts "- #{Category.count} categories"
puts "- #{Community.count} communities"
puts "- #{User.count} users"
puts "- #{Post.count} posts"
puts "- #{Product.count} products"
puts "- #{QuickReply.count} quick replies"
puts "\nYou can login with:"
puts "Admin: admin@choviet.com / password123 (Admin Dashboard: /admin/dashboard)"
puts "Vietnamese user: lien@example.com / password123 (Location: Ansan)"
puts "Vietnamese student: minh@example.com / password123 (Location: Dongdaemun)"
puts "Korean user: korean@example.com / password123 (Location: Gangnam)"
