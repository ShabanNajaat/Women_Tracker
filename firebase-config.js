// Firebase Configuration for Glow Wellness Web
// These keys are public and safe to include in the client-side code for Firebase.
const firebaseConfig = {
    apiKey: "AIzaSyCzgGEB_54dx4rJ2c1qPNeL-tB2zUik7Oc",
    authDomain: "glow-wellness-68460.firebaseapp.com",
    projectId: "glow-wellness-68460",
    storageBucket: "glow-wellness-68460.firebasestorage.app",
    messagingSenderId: "103650710155",
    appId: "1:103650710155:web:e6e54e348c7e992f28ba8e",
    measurementId: "G-XJD8CDJGR1"
};

// Global reference for other scripts to check if firebase is ready
let firebaseApp, auth, db;

async function initFirebase() {
    if (typeof firebase === 'undefined') {
        console.error('Firebase SDK not loaded. Ensure scripts are in <head>');
        return;
    }
    firebaseApp = firebase.initializeApp(firebaseConfig);
    auth = firebase.auth();
    db = firebase.firestore();
    console.log("Firebase initialized successfully");
}
