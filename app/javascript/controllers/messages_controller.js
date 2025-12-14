import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = { 
    currentUserId: Number, 
    chatRoomId: Number 
  }
  static targets = ["container"]

  connect() {
    console.log("Messages controller connected")
    console.log("Current user ID:", this.currentUserIdValue)
    console.log("Chat room ID:", this.chatRoomIdValue)
    
    this.setupSubscription()
  }

  setupSubscription() {
    if (!this.chatRoomIdValue) return

    this.subscription = createConsumer().subscriptions.create(
      { channel: "ChatRoomChannel", chat_room_id: this.chatRoomIdValue },
      {
        connected: () => {
          console.log("Connected to chat room channel")
        },

        disconnected: () => {
          console.log("Disconnected from chat room channel")
        },

        received: (data) => {
          console.log("Received message:", data)
          
          // Echo bug fix: 내가 보낸 메시지면 무시 (이미 화면에 표시됨)
          if (data.sender_id === this.currentUserIdValue) {
            console.log("Ignoring my own message")
            return
          }

          // 상대방 메시지만 화면에 추가
          this.insertMessage(data)
        }
      }
    )
  }

  insertMessage(data) {
    // 메시지 컨테이너가 있으면 추가
    if (this.hasContainerTarget && data.html) {
      this.containerTarget.insertAdjacentHTML("beforeend", data.html)
      this.scrollToBottom()
    }
  }

  scrollToBottom() {
    const messagesArea = this.element.closest('#messages') || this.element
    messagesArea.scrollTop = messagesArea.scrollHeight
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }
}