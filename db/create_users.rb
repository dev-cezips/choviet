# 사용자 1: 한국인 사용자
user1 = User.create!(
  email: 'kim.minji@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'Kim Min-ji',
  locale: 'ko',
  location_code: 'seoul_gangnam'
)
puts "Created user: #{user1.email}"

# 사용자 2: 베트남 사용자
user2 = User.create!(
  email: 'nguyen.thu@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'Nguyen Thu',
  locale: 'vi',
  location_code: 'seoul_mapo'
)
puts "Created user: #{user2.email}"

# 각 사용자에 대한 샘플 게시물 생성
post1 = Post.create!(
  user: user1,
  title: '한국어 교환 수업 찾습니다',
  content: '안녕하세요! 베트남어를 배우고 싶은 한국인입니다. 한국어를 배우고 싶은 베트남 분과 언어 교환하고 싶습니다. 주 2회 정도 카페에서 만나서 1시간씩 대화하면 좋겠습니다.',
  post_type: 'question',
  location_code: 'seoul_gangnam'
)
puts "Created post: #{post1.title}"

post2 = Post.create!(
  user: user2,
  title: 'Tìm bạn học tiếng Hàn',
  content: 'Xin chào! Tôi là người Việt Nam đang sống ở Seoul. Tôi muốn tìm bạn Hàn Quốc để học tiếng Hàn. Tôi có thể dạy tiếng Việt cho bạn. Hẹn gặp cuối tuần nhé!',
  post_type: 'free_talk',
  location_code: 'seoul_mapo'
)
puts "Created post: #{post2.title}"

# 판매 게시물도 추가
product_post = Post.new(
  user: user2,
  title: 'Bán điện thoại Samsung Galaxy S21',
  content: 'Mình cần bán điện thoại Samsung Galaxy S21, máy còn mới 95%, đầy đủ phụ kiện. Lý do bán: đổi máy mới. Giá cả thương lượng.',
  post_type: 'marketplace',
  location_code: 'seoul_mapo'
)

# 상품 정보를 먼저 추가
product_post.build_product(
  price: 350000,
  condition: 'like_new',
  currency: 'KRW'
)

# 이제 저장
product_post.save!
puts "Created marketplace post: #{product_post.title}"

puts "\n=== 생성된 사용자 계정 ==="
puts "1. Email: kim.minji@example.com / Password: password123"
puts "2. Email: nguyen.thu@example.com / Password: password123"
puts "\n기존 계정:"
puts "3. Email: user@example.com / Password: password (이전에 생성된 계정)"