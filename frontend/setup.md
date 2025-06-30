# Medical Camp - Frontend-Backend Setup Guide

## Quick Setup

### Step 1: Start the Backend
```bash
cd backend
npm install
npm run dev
```

The backend should start on `http://localhost:5003`

### Step 2: Configure Frontend
1. Open `frontend/lib/config/app_config.dart`
2. Update the base URL based on your setup:
   - **Android Emulator**: `http://10.0.2.2:5003/api`
   - **iOS Simulator**: `http://localhost:5003/api`
   - **Physical Device**: `http://YOUR_COMPUTER_IP:5003/api`

### Step 3: Install Flutter Dependencies
```bash
cd frontend
flutter pub get
```

### Step 4: Run the App
```bash
flutter run
```

## Testing the Connection

The app will automatically test the backend connection on startup. Check the console output for:
- ✅ Backend connection successful
- ❌ Backend connection failed

## Common Issues & Solutions

### 1. Connection Refused
**Problem**: Cannot connect to backend
**Solution**: 
- Ensure backend is running on port 5003
- Check if port is not blocked by firewall
- For physical devices, use computer's IP address

### 2. CORS Errors
**Problem**: Cross-origin request blocked
**Solution**: 
- Backend has CORS configured in `server.js`
- If issues persist, check backend CORS settings

### 3. Authentication Issues
**Problem**: Login not working
**Solution**:
- Check if backend auth routes are working
- Verify JWT token implementation
- Test with Postman first

## API Endpoints

The frontend connects to these backend endpoints:

- `POST /api/auth/login` - User login
- `GET /api/patients` - Get all patients
- `POST /api/patients` - Create new patient
- `POST /api/vitals` - Record patient vitals
- `GET /api/queue` - Get patient queue
- `GET /api/inventory` - Get inventory
- `GET /api/admin/stats` - Get admin statistics

## Development Tips

1. **Use Android Emulator** for easiest setup
2. **Check console logs** for connection status
3. **Test API endpoints** with Postman first
4. **Use physical device** for real-world testing

## Production Deployment

1. Update `app_config.dart` with production URL
2. Enable SSL/TLS on backend
3. Configure proper CORS for production domain
4. Set up proper authentication

## Support

If you encounter issues:
1. Check console logs for error messages
2. Verify backend is running and accessible
3. Test API endpoints manually
4. Check network connectivity 