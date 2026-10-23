importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBt4YzThO4EBl1XP1fNwzxb0dZOooyXPFw',
  authDomain: 'bilicheck.firebaseapp.com',
  projectId: 'bilicheck',
  storageBucket: 'bilicheck.firebasestorage.app',
  messagingSenderId: '999330931535',
  appId: '1:999330931535:web:b70525db5cdc22a278db3a',
});

const messaging = firebase.messaging();