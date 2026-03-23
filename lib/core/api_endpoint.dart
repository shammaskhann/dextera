// ⚠️ IMPORTANT: Update this with your ngrok HTTPS URL once set up
// Setup: On EC2, run: ngrok http 8080
// Then replace with the generated URL: https://xxxx-xxxx-xxxx.ngrok-free.app/api/
const String baseApiUrl =
    "http://localhost:8080/api/"; // Temporary (needs HTTPS for GitHub Pages)
// const String baseApiUrl = "https://YOUR_NGROK_URL.ngrok-free.app/api/"; // Use this once ngrok is running
const String login = "${baseApiUrl}auth/login";
const String googleLogin = "${baseApiUrl}google";
const String register = "${baseApiUrl}auth/register";
const String verifyOtp = "${baseApiUrl}auth/verify-otp";
const String resendOtp = "${baseApiUrl}auth/resend-otp";

// Conversations (local springboot)
const String convo = "${baseApiUrl}convo/all";
const String convoCreate = "${baseApiUrl}convo/create";
const String convoDelete = "${baseApiUrl}convo/delete";
