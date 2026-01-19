# Find-It

**Lost and Found: Where Lost Items Find Their Way Home**

A campus lost and found application built with Flutter and Supabase.

## Setup Instructions

### 1. Database Setup
1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Copy and run the SQL script from `database_schema.sql` to create all necessary tables
4. This will create the `users`, `found_items`, and `contact_requests` tables

### 2. Environment Configuration
1. Copy `env.example.dart` to `lib/env.dart`
2. Fill in your Supabase URL and anon key

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the App
```bash
flutter run
```

## Features
- User authentication and registration
- Report found items with images
- Browse and search found items
- Secure contact request system with approval workflow
- Contact information hidden until reporter approval
- Real-time notification badges for pending requests
- Automatic polling for cross-device notifications (30-second intervals)
- Dark theme UI throughout the app

## Database Tables
- `users`: User accounts and profiles
- `found_items`: Reported found items with details and images
- `contact_requests`: Secure contact request system between finders and reporters