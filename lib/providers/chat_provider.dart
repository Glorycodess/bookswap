import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/chat_message_model.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<QueryDocumentSnapshot> _chats = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<QueryDocumentSnapshot> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get user's chats
  void getUserChats() {
    _firestoreService.getUserChats().listen((chats) {
      _chats = chats;
      notifyListeners();
    });
  }

  // Send a message
  Future<bool> sendMessage({
    required String chatId,
    required String text,
    required String recipientId,
  }) async {
    try {
      await _firestoreService.sendMessage(
        chatId: chatId,
        text: text,
        recipientId: recipientId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get messages for a chat (returns stream)
  Stream<List<ChatMessageModel>> getChatMessages(String chatId) {
    return _firestoreService.getChatMessages(chatId);
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    await _firestoreService.markMessagesAsRead(chatId);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}