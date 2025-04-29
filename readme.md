# Settle Me – All-in-One Coordination App

A powerful cross-platform Flutter application built with Firebase backend, designed for real-time user coordination including rental management, ride booking, messaging, and agent services. Inspired by real-world needs to simplify local movement, living, and communication in one unified platform.

---

## 🚀 Features

### 1. **Authentication System**
- Email/password-based sign-up and login using Firebase Auth
- Email verification
- User profile setup and management

### 2. **Real-Time Messaging System**
- One-to-one chat functionality
- Real-time sync with Firebase Firestore
- Notification integration using Firebase Cloud Messaging (FCM)

### 3. **Rental System**
- Rent property listings (rooms, apartments, etc.)
- View details, images, pricing, and availability
- Contact owners via built-in messaging

### 4. **Ride System**
- Request and offer rides
- Live ride tracking (integration planned)
- Ride history and status updates

### 5. **Agent Booking System**
- Book local agents/helpers for services (e.g. movers, maintenance)
- Agent profiles with availability and booking calendar
- Service status tracking and cancellation

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** (Dart)
- **State Management**: BLoC (Business Logic Component)
- **Dependency Injection**: GetIt + Injectable
- **Architecture**: Clean Architecture (Feature-First structure)

### Backend
- **Firebase Auth** – Authentication & email verification
- **Firebase Firestore** – Real-time database for chats, rentals, rides, bookings
- **Firebase Cloud Messaging (FCM)** – Push notifications
- **Firebase Storage** – Profile and listing image handling

---

## 🧭 Project Structure (Feature-First + Clean Architecture)
lib/ ├── features/ │ ├── authentication/ │ ├── messaging/ │ ├── rental/ │ ├── ride/ │ └── agent_booking/ ├── core/ │ ├── services/ │ ├── theme/ │ └── utilities/ ├── injection.dart └── main.dart

---

## 📦 Installation

1. Clone the repo  
   `git clone https://github.com/your-username/settle-me.git`

2. Get packages  
   `flutter pub get`

3. Run the app  
   `flutter run`

> Make sure to set up Firebase for Android/iOS with appropriate `google-services.json` or `GoogleService-Info.plist`.

---

## 📌 To-Do / Upcoming

- Live ride tracking with maps  
- Reviews and ratings for agents  
- Admin panel (web)  
- Better filtering for rentals

---

## 📄 License

This project is licensed under the MIT License.

---

## 🙌 Credits

Created by **Sachin Bhusal**  
Inspired by real-world coordination challenges and mobile-first design principles.

