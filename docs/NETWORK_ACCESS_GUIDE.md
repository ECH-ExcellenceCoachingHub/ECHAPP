# Network Access Configuration Guide

## Current Setup Status ✅

Your backend is already configured to accept connections from any network:
- Listening on `0.0.0.0:5000` (all network interfaces)
- CORS is enabled to allow all origins (`*`)

## How to Find Your Machine's IP Address

### Windows:
```cmd
ipconfig
```
Look for your active network adapter's IPv4 address (usually starts with 192.168.x.x or 10.x.x.x)

### macOS/Linux:
```bash
ifconfig
# or
ip addr show
```

## Frontend Configuration

### Option 1: Manual IP Configuration (Current Approach)
Update the IP address in `lib/config/api_config.dart`:
```dart
const String ipAddress = 'YOUR_MACHINE_IP_HERE'; // e.g., '192.168.1.4'
```

### Option 2: Environment-Based Configuration (Recommended)
Create different configurations for different environments:

```dart
class ApiConfig {
  static String get baseUrl {
    // For production, use your deployed backend URL
    if (const bool.fromEnvironment('dart.vm.product')) {
      return 'https://your-production-api.com/api';
    }
    
    // For development, detect platform
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else {
      // Mobile/Desktop - use your machine's IP
      const String ipAddress = '192.168.1.4'; // Update this
      return 'http://$ipAddress:5000/api';
    }
  }
}
```

Don't forget to add the import:
```dart
import 'package:flutter/foundation.dart' show kIsWeb;
```

## Testing Network Access

1. **Start your backend:**
   ```bash
   cd backend
   npm start
   ```

2. **Find your machine's IP address** using the commands above

3. **Update frontend configuration** with your IP

4. **Test from mobile device:**
   - Make sure both devices are on the same WiFi network
   - Open your Flutter app on the mobile device
   - The app should now be able to reach your backend

## Troubleshooting

### If connection fails:

1. **Check firewall settings:**
   - Windows: Allow Node.js through Windows Firewall
   - macOS: System Preferences > Security & Privacy > Firewall
   - Linux: Check iptables or ufw rules

2. **Verify the backend is running:**
   ```bash
   netstat -an | findstr 5000  # Windows
   netstat -an | grep 5000     # macOS/Linux
   ```

3. **Test from another device:**
   Open browser on another device and navigate to:
   `http://YOUR_MACHINE_IP:5000`

4. **Check network connectivity:**
   Ping your machine from the mobile device:
   ```bash
   ping YOUR_MACHINE_IP
   ```

## Production Deployment

For production, you should:
1. Deploy your backend to a cloud service (Vercel, Render, Heroku, etc.)
2. Use HTTPS
3. Restrict CORS to your frontend domain only
4. Set up proper environment variables

Example production CORS configuration:
```javascript
const corsOptions = {
  origin: ['https://your-frontend-domain.com'],
  credentials: true,
  optionsSuccessStatus: 200
};
```

## Security Notes

⚠️ **Development Only**: The current CORS configuration (`origin: '*'`) is suitable for development but should be restricted in production.

✅ **Best Practice**: Use specific domains in production:
```javascript
const corsOptions = {
  origin: [
    'http://localhost:3000',           // Local development
    'https://your-app.com',            // Production frontend
    'https://staging.your-app.com'     // Staging environment
  ],
  credentials: true
};
```