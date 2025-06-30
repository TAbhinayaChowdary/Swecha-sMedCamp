# Medical Camp Management System

A full-stack application for managing medical camps, built with:
- **Flutter** (frontend, cross-platform mobile)
- **Node.js + Express + MongoDB** (backend API)

## Features

- Patient registration and management
- Vitals recording
- Doctor assignment and queue management
- Medicine prescription and pickup
- Inventory tracking
- Authentication (JWT)
- Admin and volunteer dashboards

## Setup Instructions

### Prerequisites

- Flutter SDK (3.4.3 or higher)
- Dart SDK
- Node.js (16+ recommended)
- MongoDB (local or cloud)
- Android Studio / VS Code

### 1. **Backend Setup**

```bash
cd backend
npm install
# Configure your MongoDB URI in backend/db.js or as an environment variable
npm run dev
```
- The backend runs by default on **port 5003** (or 5002, check your `server.js`).
- Make sure MongoDB is running and accessible.

### 2. **Frontend Setup**

```bash
cd frontend
flutter pub get
```

**Configure Backend URL:**
- Edit `lib/config/app_config.dart` in the Flutter project.
- For Android emulator: `http://10.0.2.2:5003/api`
- For iOS simulator: `http://localhost:5003/api`
- For physical device: Use your computer's local IP (e.g., `http://192.168.1.100:5003/api`)

**Run the app:**
```bash
flutter run
```

## Project Structure

```
lib/
├── config/
│   └── app_config.dart          # App configuration
├── models/
│   ├── user.dart               # User model
│   └── patient.dart            # Patient model
├── services/
│   └── api_service.dart        # API communication service
├── main.dart                   # App entry point
├── loginVol.dart              # Volunteer login
├── volMain.dart               # Volunteer main dashboard
├── volPReg.dart               # Patient registration
├── volVital.dart              # Vitals recording
├── volDas.dart                # Doctor assignment
├── volDPr.dart                # Doctor prescription
├── volMPic.dart               # Medicine pickup
└── volunteer_dashboard.dart   # Patient list dashboard
```

## API Integration

The app communicates with the Node.js backend through the `ApiService` class. Key features:

- **Authentication**: JWT token-based authentication
- **Patient Management**: CRUD operations for patients
- **Vitals Recording**: Store patient vitals data
- **Queue Management**: Handle patient queue
- **Inventory**: Track medicine inventory

## Environment Configuration

- **Development:** Use local MongoDB and backend URL as above.
- **Production:** Update backend URL and use a production MongoDB instance.

## Troubleshooting

- **Connection Refused:** Ensure backend is running and accessible from your device.
- **CORS Errors:** Backend should have CORS enabled (see `backend/server.js`).
- **Authentication Issues:** Check JWT token handling and expiration.
- **Symlink Issues (Windows):** Enable Developer Mode for symlink support.

## Contributing

- Follow best practices for both Node.js and Flutter.
- Add error handling and validation.
- Test on both Android and iOS.
- Update documentation for new features.

## License

This project is part of the Medical Camp management system.

**For more details, see the `frontend/README.md` and `backend/README.md` for each part.**
