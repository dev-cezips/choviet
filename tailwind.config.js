module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        // 🌈 1. Core Brand Colors (브랜드 핵심색)
        'primary': '#0068FF',           // Zalo Blue - 주요 버튼, 액션 강조
        'primary-hover': '#0052CC',     // 버튼 호버/누름 시
        'primary-light': '#E5F0FF',     // 라벨/뱃지 배경
        
        // Legacy support (기존 코드 호환)
        'zalo-blue': '#0068FF',
        'zalo-blue-dark': '#0052CC',
        'zalo-blue-light': '#E5F0FF',
        
        // ⚫ 2. Neutral Colors (중립색)
        'text-strong': '#1A1A1A',      // 제목, 핵심 정보
        'text-medium': '#555555',       // 일반 본문
        'text-light': '#999999',        // 서브 텍스트
        'border': '#E5E5E5',            // 섹션 구분선
        'bg-light': '#F7F9FC',          // 전체 배경
        'card': '#FFFFFF',              // 카드 UI 기본
        
        // ❤️ 3. Semantic Colors (의미 전달색)
        'success': '#28C76F',           // Thành công - 성공, 확인
        'warning': '#FFB300',           // Cảnh báo - 주의 상황
        'danger': '#FF4D4D',            // Báo động - 신고, 오류
        'like': '#FF3366',              // Thích - 좋아요 하트
        
        // ⭐ 5. Level & Badge Colors (레벨/칭호 컬러)
        'level-1': '#A0AEC0',           // Người mới - 초보자
        'level-2': '#38BDF8',           // Hàng xóm thân thiện
        'level-3': '#0068FF',           // Người có uy tín
        'level-4': '#7C3AED',           // Trợ lý khu phố
        'level-5': '#FACC15',           // Anh hùng cộng đồng
        
        // Legacy colors (기존 호환)
        'soft-coral': '#FF6B6B',
        'off-white': '#F9FAFB',
        'pure-white': '#FFFFFF',
        'charcoal': '#111827',
        'error': '#EF4444',
        'info': '#0068FF',
        
        // Additional utility colors
        'light-gray': '#E5E5E5',
        'medium-gray': '#999999',
        'dark-gray': '#333333',
        'golden-yellow': '#FFCC00',
        'success-green': '#28C76F',
        'warning-yellow': '#FFB300',
        'danger-red': '#FF4D4D',
      },
      fontFamily: {
        // Be Vietnam Pro for Vietnamese support
        'vietnam': ['"Be Vietnam Pro"', 'system-ui', 'sans-serif'],
        'sans': ['"Be Vietnam Pro"', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        // Custom font sizes for Vietnamese text
        'xs': ['0.75rem', { lineHeight: '1.2rem' }],
        'sm': ['0.875rem', { lineHeight: '1.4rem' }],
        'base': ['1rem', { lineHeight: '1.6rem' }],
        'lg': ['1.125rem', { lineHeight: '1.8rem' }],
        'xl': ['1.25rem', { lineHeight: '2rem' }],
        '2xl': ['1.5rem', { lineHeight: '2.2rem' }],
      },
      borderRadius: {
        'pill': '9999px',  // For pill-shaped inputs
        'card': '12px',    // For cards (📐 권장값)
        'button': '10px',  // For buttons (📐 권장값)
      },
      boxShadow: {
        'card': '0 2px 8px rgba(0, 0, 0, 0.08)',
        'card-hover': '0 4px 12px rgba(0, 0, 0, 0.12)',
        'fab': '0 4px 16px rgba(0, 0, 0, 0.16)',
        'badge': '0 2px 4px rgba(0, 0, 0, 0.1)',
      },
      spacing: {
        // 📐 8. Layout Spacing (권장)
        'section': '24px',    // Section Gap
        'card': '16px',       // Global Padding
      },
      animation: {
        'level-up': 'levelUp 0.6s ease-out',
        'badge-bounce': 'badgeBounce 1s ease-in-out infinite',
      },
      keyframes: {
        levelUp: {
          '0%': { transform: 'scale(1) rotate(0deg)' },
          '50%': { transform: 'scale(1.2) rotate(180deg)' },
          '100%': { transform: 'scale(1) rotate(360deg)' },
        },
        badgeBounce: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-4px)' },
        },
      }
    }
  }
}