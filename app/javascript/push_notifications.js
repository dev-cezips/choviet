// Push Notifications Manager for Chợ Việt
export class PushNotificationManager {
  constructor() {
    this.vapidPublicKey = document.querySelector('meta[name="push-vapid-public-key"]')?.content;
    this.isSupported = 'serviceWorker' in navigator && 'PushManager' in window;
  }
  
  async requestPermission() {
    if (!this.isSupported) {
      console.warn('Push notifications not supported');
      return false;
    }
    
    const permission = await Notification.requestPermission();
    return permission === 'granted';
  }
  
  async subscribe() {
    if (!this.isSupported || !this.vapidPublicKey) {
      console.error('Push setup not complete');
      return false;
    }
    
    try {
      // Request permission
      const granted = await this.requestPermission();
      if (!granted) return false;
      
      // Register service worker
      const registration = await navigator.serviceWorker.ready;
      
      // Subscribe to push
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKey)
      });
      
      // Send to server
      const response = await this.saveEndpoint(subscription);
      return response.success;
      
    } catch (error) {
      console.error('Failed to subscribe:', error);
      return false;
    }
  }
  
  async unsubscribe() {
    try {
      const registration = await navigator.serviceWorker.ready;
      const subscription = await registration.pushManager.getSubscription();
      
      if (subscription) {
        await subscription.unsubscribe();
        await this.removeEndpoint(subscription);
      }
      
      return true;
    } catch (error) {
      console.error('Failed to unsubscribe:', error);
      return false;
    }
  }
  
  async saveEndpoint(subscription) {
    const data = {
      push_endpoint: {
        platform: 'web',
        token: this.generateToken(subscription),
        endpoint_url: subscription.endpoint,
        keys: {
          p256dh: btoa(String.fromCharCode(...new Uint8Array(subscription.getKey('p256dh')))),
          auth: btoa(String.fromCharCode(...new Uint8Array(subscription.getKey('auth'))))
        }
      }
    };
    
    const response = await fetch('/push_endpoints', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(data)
    });
    
    return response.json();
  }
  
  async removeEndpoint(subscription) {
    const token = this.generateToken(subscription);
    
    const response = await fetch(`/push_endpoints?platform=web&token=${encodeURIComponent(token)}`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    });
    
    return response.json();
  }
  
  generateToken(subscription) {
    // Generate a unique token from the endpoint
    return btoa(subscription.endpoint).replace(/[^a-zA-Z0-9]/g, '').substring(0, 50);
  }
  
  urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding)
      .replace(/\-/g, '+')
      .replace(/_/g, '/');
    
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    
    return outputArray;
  }
}

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  window.pushManager = new PushNotificationManager();
  
  // Add click handlers for push subscription buttons
  document.querySelectorAll('[data-push-subscribe]').forEach(button => {
    button.addEventListener('click', async (e) => {
      e.preventDefault();
      const success = await window.pushManager.subscribe();
      if (success) {
        button.textContent = button.dataset.subscribedText || 'Notifications On';
        button.classList.add('subscribed');
      }
    });
  });
});