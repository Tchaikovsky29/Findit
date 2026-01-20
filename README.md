# Find-It

**Lost and Found: Where Lost Items Find Their Way Home**

A comprehensive campus lost and found application built with Flutter and Supabase, designed to help students and faculty recover lost items securely and efficiently. The app features user authentication, item reporting with image uploads, advanced search capabilities, and a secure contact request system to protect user privacy.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Setup](#setup)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Database Schema](#database-schema)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Project Overview

Find-It is a mobile application that streamlines the process of reporting and claiming lost items on campus. Built with Flutter for cross-platform compatibility, it uses Supabase as the backend for real-time database operations and authentication. The app emphasizes privacy by implementing a secure contact request system where contact information is only shared upon mutual approval.

Key objectives:
- Reduce the number of lost items that go unclaimed
- Provide a secure and user-friendly platform for item recovery
- Foster community engagement on campus

## Architecture

The application follows a layered architecture:

- **Presentation Layer**: Flutter screens and widgets for UI
- **Business Logic Layer**: Services and providers for data management
- **Data Layer**: Models and Supabase integration for persistence
- **Utilities**: Shared constants, themes, and helper functions

### Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL, Authentication, Storage)
- **State Management**: Provider
- **Local Storage**: Shared Preferences, Secure Storage
- **Image Handling**: Image Picker, Permission Handler

## Features

- **User Authentication**: Secure login and registration system
- **Item Reporting**: Report found items with descriptions, locations, and images
- **Advanced Search**: Browse and search items by keywords, categories, and AI-generated tags
- **Secure Contact System**: Request contact information with approval workflow
- **Real-time Notifications**: Badge indicators for pending contact requests
- **Cross-device Sync**: Automatic polling for updates (30-second intervals)
- **Dark Theme**: Complete dark mode support throughout the app
- **Admin Panel**: Administrative functions for managing users and items

## Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Supabase account and project
- Android/iOS development environment

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/find-it.git
   cd find-it
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Set up the development environment**:
   - For Android: Install Android Studio and Android SDK
   - For iOS: Install Xcode (macOS only)

## Setup

### 1. Database Setup

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Go to your Supabase project dashboard
3. Navigate to the SQL Editor
4. Copy and paste the contents of [`database_schema.sql`](database_schema.sql)
5. Execute the script to create all necessary tables and policies

This will create the following tables:
- `users`: User accounts and profiles
- `found_items`: Reported found items with details and images
- `contact_requests`: Secure contact request system between finders and reporters

### 2. Environment Configuration

1. Copy the environment template:
   ```bash
   cp lib/env.example.dart lib/env.dart
   ```

2. Open `lib/env.dart` and fill in your Supabase credentials:
   ```dart
   const supabaseUrl = 'your-supabase-project-url';
   const supabaseAnonKey = 'your-supabase-anon-key';
   ```

### 3. Run the Application

```bash
flutter run
```

For specific platforms:
```bash
flutter run -d android  # For Android
flutter run -d ios      # For iOS
```

## Usage

### For Users

1. **Sign Up**: Create an account with your PRN, email, and other details
2. **Report Found Items**: Use the "Add Item" screen to report found items with photos and descriptions
3. **Browse Items**: View all reported items on the home screen
4. **Search Items**: Use the search functionality to find specific items
5. **Request Contact**: Send contact requests for items you're interested in
6. **Manage Requests**: Approve or deny incoming contact requests in your profile

### For Administrators

Access the admin panel to:
- View all users and items
- Manage user accounts
- Monitor contact requests
- Generate reports

## API Reference

The app uses several services for backend operations. Here are the main service classes:

### AuthService
Handles user authentication and registration.

**Methods:**
- `signUp(String prn, String password, String fullName, String email, ...)`: Register a new user
- `signIn(String prn, String password)`: Authenticate an existing user
- `signOut()`: Log out the current user
- `getCurrentUser()`: Get current user information

### FoundItemsService
Manages found item operations.

**Methods:**
- `addItem(Map<String, dynamic> itemData)`: Add a new found item
- `getAllItems()`: Retrieve all found items
- `searchItems(String query)`: Search items by keywords
- `getUserItems(String prn)`: Get items reported by a specific user

### ContactRequestService
Handles contact request operations.

**Methods:**
- `sendRequest(String itemId, String message)`: Send a contact request
- `getPendingRequests()`: Get pending requests for current user
- `approveRequest(String requestId)`: Approve a contact request
- `denyRequest(String requestId)`: Deny a contact request

## Database Schema

The application uses three main tables in Supabase:

### users
```sql
CREATE TABLE users (
    prn VARCHAR PRIMARY KEY,
    password_hash VARCHAR NOT NULL,
    full_name VARCHAR NOT NULL,
    year INTEGER NOT NULL,
    branch VARCHAR NOT NULL,
    department VARCHAR NOT NULL,
    phone_number VARCHAR NOT NULL,
    email VARCHAR NOT NULL UNIQUE,
    theme_preference VARCHAR DEFAULT 'light',
    is_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### found_items
```sql
CREATE TABLE found_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR NOT NULL,
    user_tags TEXT[] DEFAULT '{}',
    ai_object VARCHAR,
    ai_adjectives TEXT[],
    ai_description TEXT,
    image_url VARCHAR,
    added_by VARCHAR REFERENCES users(prn) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### contact_requests
```sql
CREATE TABLE contact_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    item_id UUID REFERENCES found_items(id) ON DELETE CASCADE,
    requester_prn VARCHAR NOT NULL,
    status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Contributing

We welcome contributions to Find-It! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes and ensure tests pass
4. Commit your changes: `git commit -am 'Add some feature'`
5. Push to the branch: `git push origin feature/your-feature-name`
6. Submit a pull request

### Code Style
- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comprehensive docstrings for all classes and functions
- Ensure all code is properly commented

### Testing
Run tests before submitting:
```bash
flutter test
```

## Troubleshooting

### Common Issues

1. **Supabase Connection Issues**
   - Verify your `lib/env.dart` file has correct Supabase URL and anon key
   - Check your internet connection
   - Ensure Supabase project is active

2. **Image Upload Failures**
   - Grant camera and gallery permissions in device settings
   - Check available storage in Supabase project

3. **Authentication Problems**
   - Ensure PRN format is correct
   - Verify password meets requirements
   - Check if account already exists

4. **Build Errors**
   - Run `flutter clean` and `flutter pub get`
   - Update Flutter SDK if necessary
   - Check for platform-specific dependencies

### Debug Mode
Enable debug logging by setting the `debugShowCheckedModeBanner` to `true` in `lib/main.dart`.

### Getting Help
- Check existing issues on GitHub
- Create a new issue with detailed error logs
- Contact the maintainers

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.