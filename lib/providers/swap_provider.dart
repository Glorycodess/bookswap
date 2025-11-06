import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/swap_request_model.dart';
import '../models/book_model.dart';

class SwapProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<SwapRequestModel> _receivedRequests = [];
  List<SwapRequestModel> _sentRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SwapRequestModel> get receivedRequests => _receivedRequests;
  List<SwapRequestModel> get sentRequests => _sentRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get swap requests where current user is recipient
  void getReceivedSwapRequests() {
    _firestoreService.getReceivedSwapRequests().listen((requests) {
      _receivedRequests = requests;
      notifyListeners();
    });
  }

  // Get swap requests where current user is requester
  void getSentSwapRequests() {
    _firestoreService.getSentSwapRequests().listen((requests) {
      _sentRequests = requests;
      notifyListeners();
    });
  }

  // Create a swap request
  Future<String?> createSwapRequest({
    required BookModel requesterBook,
    required BookModel recipientBook,
    required String requesterName,
    required String recipientName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create chat ID
      String chatId = '';

      SwapRequestModel swapRequest = SwapRequestModel(
        id: '',
        requesterId: _firestoreService.currentUserId!,
        requesterName: requesterName,
        requesterBookId: requesterBook.id,
        requesterBookTitle: requesterBook.title,
        recipientId: recipientBook.ownerId,
        recipientName: recipientName,
        recipientBookId: recipientBook.id,
        recipientBookTitle: recipientBook.title,
        status: 'pending',
        chatId: chatId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      String swapId = await _firestoreService.createSwapRequest(swapRequest);

      // Create chat for this swap
      chatId = await _firestoreService.createChat(
        otherUserId: recipientBook.ownerId,
        otherUserName: recipientName,
        swapRequestId: swapId,
        bookTitle: recipientBook.title,
      );

      // Update swap request with chat ID
      await _firestoreService.updateSwapRequest(swapId, {'chatId': chatId});

      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Accept swap request
  Future<bool> acceptSwapRequest(SwapRequestModel swapRequest) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.acceptSwapRequest(
        swapRequest.id,
        swapRequest.requesterBookId,
        swapRequest.recipientBookId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reject swap request
  Future<bool> rejectSwapRequest(SwapRequestModel swapRequest) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.rejectSwapRequest(
        swapRequest.id,
        swapRequest.requesterBookId,
        swapRequest.recipientBookId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cancel swap request (for requester)
  Future<bool> cancelSwapRequest(SwapRequestModel swapRequest) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.rejectSwapRequest(
        swapRequest.id,
        swapRequest.requesterBookId,
        swapRequest.recipientBookId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}