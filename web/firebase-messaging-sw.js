// Firebase Cloud Messaging service worker: shows push notifications while the
// PassionRide web app is closed or in a background tab.
// Keep the SDK version in step with firebase_core_web's supportedFirebaseJsSdkVersion.
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyB0bUK-1TkR5B5sDOwgfPjD6gQwA6mwHHw',
  appId: '1:800936933243:web:3c09b9b8484237f330efde',
  messagingSenderId: '800936933243',
  projectId: 'passon-ride-rental-888',
  authDomain: 'passon-ride-rental-888.firebaseapp.com',
  storageBucket: 'passon-ride-rental-888.firebasestorage.app',
});

// Messages with a `notification` block are displayed automatically by the SDK.
firebase.messaging();
