import 'dart:io';
import 'package:dextera/repository/chat_repository.dart';

class ErrorHandler {
  static String parse(dynamic error) {
    if (error == null) return "An unknown error occurred";

    if (error is ChatException) {
      return error.displayMessage;
    }

    String message = error.toString();

    // Remove common prefixes
    final prefixes = ["Exception: ", "DioException: ", "HttpException: ", "Error: "];
    for (final prefix in prefixes) {
      if (message.startsWith(prefix)) {
        message = message.replaceFirst(prefix, "");
      }
    }

    // Handle common Dart/Flutter exceptions
    if (error is SocketException) {
      return "No internet connection. Please check your network.";
    } else if (error is HttpException) {
      return "Couldn't find the requested resource.";
    } else if (error is FormatException) {
      return "Bad response format from server.";
    }

    // Handle specific error strings (case insensitive)
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains("invalid email or password")) {
      return "The email or password you entered is incorrect.";
    } else if (lowerMessage.contains("network error") || 
               lowerMessage.contains("xmlhttprequest") || 
               lowerMessage.contains("connection failed")) {
      return "Connection lost. Please check your internet.";
    } else if (lowerMessage.contains("timeout")) {
      return "The request timed out. Please try again later.";
    } else if (lowerMessage.contains("unauthorized") || lowerMessage.contains("401")) {
      return "Session expired. Please log in again.";
    }

    // If it's a JSON string, try to extract a message if possible
    if (message.startsWith('{') && message.endsWith('}')) {
      // This is a rough check, but often helpful if raw JSON leaks
      return "A server error occurred. Please try again.";
    }

    // Default to the message itself if it's clean enough, otherwise a fallback
    return message.length > 1 ? message : "Something went wrong. Please try again.";
  }
}
