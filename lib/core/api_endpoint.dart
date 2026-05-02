// ⚠️ IMPORTANT: Update this with your ngrok HTTPS URL once set up
// Setup: On EC2, run: ngrok http 8080
// Then replace with the generated URL: https://xxxx-xxxx-xxxx.
// -free.app/api/
// const String baseApiUrl =
//     "http://localhost:8080/api/"; // Temporary (needs HTTPS for GitHub Pages)
const String baseApiUrl =
    "https://api.dextera.online/api/"; // Use this once ngrok is running
const String login = "${baseApiUrl}auth/login";
const String googleLogin = "${baseApiUrl}auth/google";
const String register = "${baseApiUrl}auth/register";
const String verifyOtp = "${baseApiUrl}auth/verify-otp";
const String resendOtp = "${baseApiUrl}auth/resend-otp";
const String forgotPassword = "${baseApiUrl}auth/forgot-password";
const String resetPassword = "${baseApiUrl}auth/reset-password";

// Conversations (local springboot)
const String convo = "${baseApiUrl}convo/all";
const String convoCreate = "${baseApiUrl}convo/create";
const String convoDelete = "${baseApiUrl}convo/delete";
const String convoRename = "${baseApiUrl}convo/rename";

// User profile update
const String updateUsername = "${baseApiUrl}users/update/username";
const String updatePassword = "${baseApiUrl}users/update/password";
const String deleteAccount = "${baseApiUrl}users/delete";
