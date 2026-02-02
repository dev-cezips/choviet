class CreateInquiries < ActiveRecord::Migration[8.0]
  def change
    create_table :inquiries do |t|
      # 누가 → 누구에게
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }

      # 어디서 왔는지 (추적용, nullable)
      t.references :post, null: true, foreign_key: true

      # 문의 내용 (스냅샷)
      t.string :sender_name, null: false
      t.string :contact_method, null: false
      t.string :contact_value, null: false
      t.text :message, null: false

      # 상태 추적 (수익화 핵심)
      t.string :status, null: false, default: 'pending'
      t.datetime :read_at
      t.datetime :replied_at

      # 출처 (나중에 광고 등 확장)
      t.string :source, null: false, default: 'organic'

      t.timestamps
    end

    # 수신자별 상태 조회 (대시보드용)
    add_index :inquiries, [:recipient_id, :status]
    # post_id와 sender_id 인덱스는 t.references가 자동 생성
  end
end
