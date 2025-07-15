# 🍽️ SurplusServe – Food Donation App

**SurplusServe** is a Flutter & Firebase-based mobile application designed to reduce food waste by connecting **donors** with **receivers**. The app enables easy listing, discovery, and claiming of surplus food with real-time geolocation and smart notifications.

---

## 🚀 Features

### 👥 User Roles

#### 1. Donor:
- Upload surplus food with details (title, description, pickup time, contact).
- Address is geocoded to coordinates using the Google Geocoding API.
- Nearby receivers are automatically notified when food is uploaded.

#### 2. Receiver:
- Browse a list of unclaimed food items sorted by distance.
- Claim food and view location using Google Maps navigation.
- Donors receive notifications when food is claimed.

---

## 🧱 Tech Stack

- **Frontend**: Flutter (Dart)  
- **Backend**: Firebase Firestore, Firebase Authentication, Firebase Cloud Functions  
- **Notifications**: Firebase Cloud Messaging (FCM)  
- **Location Services**: Google Maps SDK, Google Geocoding API  
- **AI Services**: Vertex AI – For personalized notification messages  

---

## 🛠️ Setup Instructions

### 🔧 Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase CLI](https://firebase.google.com/docs/cli)  
  → Install using:  
  ```bash
  npm install -g firebase-tools


## 🔑 Firebase Setup

Follow these steps to connect your Flutter app with Firebase:

### 1. Create a Firebase Project
- Go to the [Firebase Console](https://console.firebase.google.com/)
- Click **"Add Project"** and follow the setup instructions

### 2. Add Android App to Firebase
- In the Firebase Console, click **"Add App"** → **Android**
- Enter your app's package name (e.g., `com.example.surplusserve`)
- Download the `google-services.json` file
- Move the file to your project at:


### 3. Enable Firebase Services
In the Firebase Console, enable the following:
- **Cloud Firestore**
- **Authentication** (Email/Password, and Google Sign-In)
- **Cloud Messaging**
- **Cloud Storage**


## 🔥 Firebase Functions

1. Navigate to the functions/ directory:
   ```bask
   cd functions
   npm install
   firebase deploy --only functions

## 🔐 Environment Variables 

In .env file:

- GOOGLE_MAPS_API_KEY=your_key
- GEOCODING_API_KEY=your_key

## 💡 Powered by Firebase

<p align="center">
  <img src="https://firebase.google.com/downloads/brand-guidelines/PNG/logo-vertical.png" alt="Firebase Logo" height="100">
</p>

Firebase played a crucial role in building this prototype quickly and efficiently. Thanks to Firebase’s fully managed backend services, we were able to focus more on the **user experience** and **core functionality** rather than infrastructure setup. Perfect for rapid prototyping and real-world deployment!


