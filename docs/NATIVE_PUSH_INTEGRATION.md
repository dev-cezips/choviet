# Native App Push Notification Integration Guide

## Overview
Chợ Việt uses Firebase Cloud Messaging (FCM) for push notifications on both iOS and Android. iOS notifications are sent through FCM which then routes them via APNs.

## Server Configuration

### Environment Variables
```bash
# Required
FCM_PROJECT_ID=your-firebase-project-id
FCM_SERVICE_ACCOUNT_JSON='{...}' # Full service account JSON as string
```

### Getting Service Account JSON
1. Go to Firebase Console → Project Settings → Service accounts
2. Generate new private key
3. Copy the entire JSON content and set as `FCM_SERVICE_ACCOUNT_JSON`

## iOS Integration

### 1. Apple Developer Setup
1. Create APNs Authentication Key (.p8 file)
2. Note the Key ID and Team ID
3. Enable Push Notifications in App ID configuration

### 2. Firebase Setup
1. Firebase Console → Project settings → Cloud Messaging
2. Add iOS app if not already added
3. Upload APNs authentication key (.p8)
4. Enter Key ID and Team ID

### 3. Xcode Configuration
```xml
<!-- Info.plist -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

Capabilities:
- ✅ Push Notifications
- ✅ Background Modes → Remote notifications

### 4. Swift Implementation

```swift
import Firebase
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        
        // Set FCM delegate
        Messaging.messaging().delegate = self
        
        return true
    }
}

// MARK: - FCM Token Management
extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        // Register token with server
        registerPushToken(token: token)
    }
    
    private func registerPushToken(token: String) {
        guard let userId = getCurrentUserId() else { return }
        
        let url = URL(string: "\(API_BASE_URL)/api/v1/push_endpoints")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(getAuthToken(), forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "platform": "ios",
            "token": token,
            "device_id": UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to register push token: \(error)")
            } else {
                print("Push token registered successfully")
            }
        }.resume()
    }
}

// MARK: - Notification Handling
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Handle tap on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        handleNotificationTap(userInfo: userInfo)
        completionHandler()
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "dm_message":
            if let conversationId = userInfo["conversation_id"] as? String {
                // Navigate to conversation
                navigateToConversation(id: conversationId)
            }
        default:
            break
        }
    }
}
```

## Android Integration

### 1. Firebase Setup
1. Add `google-services.json` to `app/` directory
2. Configure Gradle files

```gradle
// Project-level build.gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}

// App-level build.gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.1.2'
}
```

### 2. Kotlin Implementation

```kotlin
// MyFirebaseMessagingService.kt
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {
    
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        
        // Register token with server
        registerPushToken(token)
    }
    
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        // App in foreground - show custom notification
        if (remoteMessage.notification != null) {
            showNotification(
                title = remoteMessage.notification?.title ?: "",
                body = remoteMessage.notification?.body ?: "",
                data = remoteMessage.data
            )
        }
    }
    
    private fun registerPushToken(token: String) {
        val userId = getCurrentUserId() ?: return
        
        val client = OkHttpClient()
        val json = JSONObject().apply {
            put("platform", "android")
            put("token", token)
            put("device_id", getDeviceId())
        }
        
        val body = json.toString().toRequestBody("application/json".toMediaType())
        val request = Request.Builder()
            .url("$API_BASE_URL/api/v1/push_endpoints")
            .post(body)
            .addHeader("Authorization", getAuthToken())
            .build()
            
        client.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                if (response.isSuccessful) {
                    Log.d(TAG, "Push token registered successfully")
                }
            }
            
            override fun onFailure(call: Call, e: IOException) {
                Log.e(TAG, "Failed to register push token", e)
            }
        })
    }
    
    private fun showNotification(title: String, body: String, data: Map<String, String>) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "dm_messages"
        
        // Create notification channel (Android O+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Direct Messages",
                NotificationManager.IMPORTANCE_HIGH
            )
            notificationManager.createNotificationChannel(channel)
        }
        
        // Create pending intent for tap action
        val intent = when (data["type"]) {
            "dm_message" -> {
                Intent(this, ConversationActivity::class.java).apply {
                    putExtra("conversation_id", data["conversation_id"])
                }
            }
            else -> Intent(this, MainActivity::class.java)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.drawable.ic_notification)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
            
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }
}

// MainActivity.kt
class MainActivity : AppCompatActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Get FCM token
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val token = task.result
                // Token will be sent via onNewToken callback
            }
        }
    }
}
```

### 3. AndroidManifest.xml

```xml
<service
    android:name=".MyFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>

<!-- Default notification icon -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />

<!-- Default notification channel -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="dm_messages" />
```

## Testing Push Notifications

### Using Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Send test message
3. Enter FCM token from device logs
4. Add custom data:
   - `type`: `dm_message`
   - `conversation_id`: `123`

### Using cURL
```bash
# Get access token first
ACCESS_TOKEN=$(node -e "
const jwt = require('jsonwebtoken');
const serviceAccount = JSON.parse(process.env.FCM_SERVICE_ACCOUNT_JSON);
const now = Math.floor(Date.now() / 1000);
const payload = {
  iss: serviceAccount.client_email,
  scope: 'https://www.googleapis.com/auth/firebase.messaging',
  aud: 'https://oauth2.googleapis.com/token',
  iat: now,
  exp: now + 3600
};
const token = jwt.sign(payload, serviceAccount.private_key, { algorithm: 'RS256' });
console.log(token);
")

# Send test notification
curl -X POST https://fcm.googleapis.com/v1/projects/$FCM_PROJECT_ID/messages:send \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_FCM_TOKEN",
      "notification": {
        "title": "Test Message",
        "body": "Hello from Chợ Việt!"
      },
      "data": {
        "type": "dm_message",
        "conversation_id": "123"
      }
    }
  }'
```

## Troubleshooting

### iOS Issues
- **No token received**: Check APNs entitlements and provisioning profile
- **Notifications not showing**: Ensure app is in background, check notification permissions
- **Token invalid**: Verify APNs key is uploaded to Firebase correctly

### Android Issues  
- **No token received**: Check google-services.json is correct
- **Notifications not showing**: Check notification channel creation
- **App crashes**: Verify Firebase dependencies are compatible

### Common Issues
- **401 Unauthorized**: Check auth token in API request
- **Token registration fails**: Verify API endpoint and request format
- **Deep links not working**: Check intent filters and navigation logic