const API_URL = 'https://r-chat-api.rusmersr.workers.dev/'; // Замени на реальный URL Worker

let currentChannel = 'general';
let currentServer = 'default';
let currentUser = {
  id: 'user-' + Math.random().toString(36).substr(2, 9),
  username: 'User'
