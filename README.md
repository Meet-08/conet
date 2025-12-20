# CoNet

A Flutter mobile application with a Node.js backend.

## Prerequisites

### For Android App

1. **Flutter SDK** (version 3.10.1 or higher)

   - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Add Flutter to your system PATH
   - Verify installation: `flutter doctor`

2. **Android Studio**

   - Download from [developer.android.com](https://developer.android.com/studio)
   - Install Android SDK (API level 21 or higher recommended)
   - Set up an Android emulator or connect a physical device

3. **Java Development Kit (JDK)**
   - JDK 17 or higher recommended

### For Backend

1. **Node.js** (version 18 or higher recommended)

   - Download from [nodejs.org](https://nodejs.org/)
   - Verify installation: `node --version`

2. **npm** (comes with Node.js)
   - Verify installation: `npm --version`

## Project Structure

```
conet/
├── conet_app/       # Flutter mobile application
├── conet_backend/   # Node.js Express backend
└── README.md
```

## Running the Backend

1. Navigate to the backend directory:

   ```bash
   cd conet_backend
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Start the server:

   ```bash
   # Production mode
   npm start

   # Development mode (with auto-reload)
   npm run dev
   ```

## Running the Android App

1. Navigate to the app directory:

   ```bash
   cd conet_app
   ```

2. Install Flutter dependencies:

   ```bash
   flutter pub get
   ```

3. Set up environment variables:

   - Create a `.env` file in the `conet_app` directory with required Supabase credentials

4. Connect an Android device or start an emulator:

   ```bash
   # List available devices
   flutter devices

   # Start an emulator (if using Android Studio emulator)
   flutter emulators --launch <emulator_id>
   ```

5. Run the app:

   ```bash
   # Run on default device
   flutter run

   # Run on a specific device
   flutter run -d <device_id>
   ```

## Useful Commands

### Flutter

- `flutter doctor` - Check Flutter installation and dependencies
- `flutter clean` - Clean build files
- `flutter pub get` - Get dependencies
- `flutter build apk` - Build release APK
- `flutter build apk --debug` - Build debug APK

### Backend

- `npm start` - Start production server
- `npm run dev` - Start development server with hot reload

## Environment Configuration

The app uses Supabase for backend services. Make sure to configure your `.env` file with:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```
