# 8-Week Development Log for Dextera Flutter App

## Project Overview

Dextera is a Flutter-based chat application featuring secure authentication with OTP verification and real-time chat streaming. The app provides a responsive design across mobile, tablet, and desktop platforms, integrating with a Spring Boot backend and PostgreSQL database.

---

## Week 1: Project Setup and Foundation

**Focus**: Establishing the project structure, dependencies, and basic configuration.

- **Flutter Project Initialization**: Created a new Flutter project named "dextera" with standard directory structure (lib/, android/, ios/, web/, etc.)
- **Dependencies Configuration**: Added core packages to pubspec.yaml:
  - `flutter_svg: ^2.2.1` for SVG icon support
  - `flutter_screenutil: ^5.9.3` for responsive screen utilities
  - `cupertino_icons: ^1.0.8` for iOS-style icons
  - `http: ^1.6.0` for API communication
- **Platform Setup**: Configured build settings for Android (gradle), iOS (Xcode), Web, Windows, Linux, and macOS
- **Code Quality Setup**: Created analysis_options.yaml with recommended linting rules
- **Asset Organization**: Set up assets/ directory structure for fonts/, icons/, and images/
- **App Theme Foundation**: Created core/app_theme.dart with basic color scheme and typography constants

---

## Week 2: Authentication Models and API Setup

**Focus**: Building data models and establishing backend connectivity.

- **Authentication Models Creation**: Developed comprehensive data models in lib/models/auth_models.dart:
  - `RegisterRequest`: username, email, password with toJson() serialization
  - `LoginRequest`: email, password with toJson()
  - `VerifyOtpRequest`: email, otp with toJson()
  - `ResendOtpRequest`: email with toJson()
  - `User`: id, name, email, verified status, timestamps with fromJson() factory
  - `LoginResponse`: user data, status, token, message with fromJson()
  - `ApiResponse`: status, message with fromJson()
- **API Endpoints Configuration**: Created lib/core/api_endpoint.dart with backend URLs:
  - Base URL: `http://localhost:8080/api/` (local development)
  - Production URL commented: `https://dexter-backend-springboot-postgre-production.up.railway.app/api/`
  - Endpoints: login, register, verify-otp, resend-otp
- **Repository Pattern Setup**: Created lib/repository/ directory structure
- **Initial API Integration**: Established HTTP client setup with JSON encoding/decoding patterns

---

## Week 3: Login Screen Implementation

**Focus**: Creating the login interface with API integration and state management.

- **LoginController Development**: Implemented lib/controllers/login_controller.dart:
  - ChangeNotifier for reactive state management
  - Email/password validation
  - Loading states (\_isLoading)
  - Error handling with user-friendly messages
  - API integration with AuthRepository.login()
  - Navigation to OTP screen on successful login
- **AuthRepository Login Method**: Added login functionality in lib/repository/auth_repository.dart:
  - HTTP POST request to login endpoint
  - JSON request/response handling
  - Error handling for network failures and API errors
  - Logging for debugging
- **LoginScreen UI Creation**: Built lib/screens/login_screen.dart:
  - Responsive layout with SingleChildScrollView
  - Email and password TextFormField inputs
  - Custom styling with app theme colors
  - Login button with loading indicator
  - Navigation to signup screen
  - Error display via SnackBar
- **Custom UI Components**: Created lib/screens/components/ directory:
  - custom_button.dart: Reusable button component
  - custom_textfield.dart: Styled text input fields

---

## Week 4: Signup Screen and Registration Flow

**Focus**: Implementing user registration with backend integration.

- **SignupController Development**: Created lib/controllers/signup_controller.dart:
  - Registration form validation (username, email, password)
  - Password confirmation matching
  - Loading states and error management
  - API integration with AuthRepository.register()
  - Success navigation to OTP verification
- **AuthRepository Register Method**: Extended auth_repository.dart with registration:
  - HTTP POST to register endpoint
  - Request serialization and response parsing
  - Status code handling (200 success, 400 validation errors)
  - Network error handling
- **SignupScreen UI**: Developed lib/screens/signup_screen.dart:
  - Username, email, password, and confirm password fields
  - Form validation with real-time feedback
  - Responsive design with centered layout
  - Navigation between login and signup screens
  - Success/error messaging via SnackBar
- **Navigation Flow Enhancement**: Updated routing logic for seamless auth flow

---

## Week 5: OTP Verification Screen

**Focus**: Building OTP input and verification functionality.

- **OtpController Implementation**: Created lib/controllers/otp_controller.dart:
  - OTP length validation (6 digits)
  - Loading states for verification and resend
  - API integration for verifyOtp and resendOtp
  - Error handling with specific messages
  - Navigation to home screen on successful verification
- **AuthRepository OTP Methods**: Added to auth_repository.dart:
  - verifyOtp: POST to verify-otp endpoint with email/otp
  - resendOtp: POST to resend-otp endpoint
  - Comprehensive error handling and logging
- **OtpVerifyScreen UI**: Built lib/screens/otp_verify_screen.dart:
  - flutter_otp_text_field integration for 6-digit input
  - Email display for context
  - Verify and Resend OTP buttons
  - Loading indicators for both operations
  - Responsive design with proper spacing
- **OTP Package Integration**: Added flutter_otp_text_field: ^1.5.1+1 to pubspec.yaml

---

## Week 6: Onboarding and Navigation Setup

**Focus**: Creating welcome experience and app navigation foundation.

- **OnboardingScreen Creation**: Developed lib/screens/onboarding_screen.dart:
  - Welcome message and app introduction
  - Call-to-action button to start authentication
  - Consistent theming with app colors
  - Responsive layout for different screen sizes
- **App Navigation Structure**: Set up main.dart with initial routing:
  - Default route to OnboardingScreen
  - Conditional navigation based on auth state
  - MaterialApp configuration with theme
- **Screen Utils Integration**: Implemented flutter_screenutil for consistent sizing
- **Asset Integration**: Added SVG icons and images to assets/
- **Build Configuration**: Updated build.gradle.kts and other platform configs

---

## Week 7: Basic Chat Screen and Repository

**Focus**: Establishing chat interface foundation and basic repository setup.

- **ChatRepository Creation**: Built lib/repository/chat_repository.dart:
  - Basic HTTP setup for chat API
  - Initial chat method structure
  - Error handling framework
- **HomeChatScreen Foundation**: Started lib/screens/home_chat_screen.dart:
  - Basic responsive layout structure
  - Drawer navigation setup for tablet/desktop
  - Message list container
  - Input field foundation
  - Animation controllers for drawer transitions
- **Chat Models**: Created basic message models (to be expanded)
- **UI Components**: Enhanced custom components for chat interface
- **Responsive Breakpoints**: Implemented mobile (<700px), tablet (700-1024px), desktop (≥1024px) layouts

---

## Week 8: Chat Streaming Functionality and Final Polish

**Focus**: Implementing real-time chat streaming and project completion.

- **ChatRepository Streaming**: Enhanced chat_repository.dart with full streaming support:
  - SSE (Server-Sent Events) integration for real-time responses
  - Stream<String> streamChat() method with async\* generator
  - Word-by-word chunk processing from "data:" lines
  - Proper stream termination on "[DONE]" signal
  - Comprehensive error handling for network issues
- **HomeChatScreen Streaming UI**: Completed chat interface in home_chat_screen.dart:
  - StreamSubscription for real-time message updates
  - Streaming text display with incremental building
  - Auto-scroll to bottom on new messages
  - Loading states during streaming
  - Message history management (\_messages list)
  - Input controller with send functionality
- **Chat API Integration**: Connected to external chat API:
  - Endpoint: `https://8000-01ke9hsffzevnjzywv4gx41ax2.cloudspaces.litng.ai/api/v1/chat`
  - JSON request with message payload
  - Accept: text/event-stream header
  - Real-time response parsing
- **Final Polish**:
  - Error handling improvements across all screens
  - Loading indicators and user feedback
  - Code cleanup and documentation
  - Performance optimizations
  - Build testing across platforms

---

## Technologies and Architecture Used

- **Framework**: Flutter (Dart SDK ^3.9.0)
- **State Management**: Provider Pattern with ChangeNotifier
- **Networking**: HTTP package with JSON serialization
- **UI**: Material Design with responsive breakpoints
- **Backend**: Spring Boot + PostgreSQL (external API)
- **Streaming**: Server-Sent Events for real-time chat
- **Architecture**: MVC with Repository pattern

## Key Milestones by Week

- **Week 1**: Project foundation and theming
- **Week 2**: Data models and API configuration
- **Week 3**: Login screen with API integration
- **Week 4**: Registration flow completion
- **Week 5**: OTP verification system
- **Week 6**: Onboarding and navigation
- **Week 7**: Chat screen foundation
- **Week 8**: Real-time chat streaming implementation

## API Integration Summary

- **Authentication APIs**: 4 endpoints (register, login, verify-otp, resend-otp)
- **Chat API**: 1 streaming endpoint for real-time conversations
- **Backend**: Spring Boot with PostgreSQL database
- **Error Handling**: Comprehensive network and API error management
- **Security**: OTP-based verification for account security

Date: January 14, 2026
