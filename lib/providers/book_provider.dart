import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/book_model.dart';

class BookProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<BookModel> _browseBooks = [];
  List<BookModel> _myBooks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookModel> get browseBooks => _browseBooks;
  List<BookModel> get myBooks => _myBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get available books for browsing
  void getBrowseListings() {
    _firestoreService.getBrowseListings().listen((books) {
      _browseBooks = books;
      notifyListeners();
    });
  }

  // Get current user's books
  void getMyBooks() {
    _firestoreService.getMyBooks().listen((books) {
      _myBooks = books;
      notifyListeners();
    });
  }

  // Create a new book
  Future<bool> createBook({
    required String title,
    required String author,
    required String genre,
    required String condition,
    required String description,
    required String ownerName,
    String? imagePath,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String imageUrl = '';
      if (imagePath != null) {
        imageUrl = await _storageService.uploadBookImage(imagePath);
      }

      BookModel book = BookModel(
        id: '',
        ownerId: _firestoreService.currentUserId!,
        ownerName: ownerName,
        title: title,
        author: author,
        genre: genre,
        condition: condition,
        description: description,
        imageUrl: imageUrl,
        status: 'available',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createBook(book);

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

  // Update a book
  Future<bool> updateBook({
    required String bookId,
    required String title,
    required String author,
    required String genre,
    required String condition,
    required String description,
    String? newImagePath,
    String? currentImageUrl,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String imageUrl = currentImageUrl ?? '';
      
      // Upload new image if provided
      if (newImagePath != null) {
        // Delete old image if exists
        if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
          await _storageService.deleteImage(currentImageUrl);
        }
        imageUrl = await _storageService.uploadBookImage(newImagePath);
      }

      Map<String, dynamic> updates = {
        'title': title,
        'author': author,
        'genre': genre,
        'condition': condition,
        'description': description,
        'imageUrl': imageUrl,
      };

      await _firestoreService.updateBook(bookId, updates);

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

  // Delete a book
  Future<bool> deleteBook(String bookId, String? imageUrl) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Delete image from storage if exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _storageService.deleteImage(imageUrl);
      }

      await _firestoreService.deleteBook(bookId);

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