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

  // ================= Browse Books =================
  void getBrowseListings() {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getBrowseListings().listen((books) {
      _browseBooks = books;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  // ================= My Books =================
  void getMyBooks() {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getMyBooks().listen((books) {
      _myBooks = books;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  // ================= Add a Simple Book (no image, no swap info) =================
  Future<bool> addSimpleBook({
    required String title,
    required String author,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final book = BookModel(
        id: '',
        ownerId: _firestoreService.currentUserId ?? '',
        ownerName: 'Anonymous',
        title: title,
        author: author,
        genre: '',
        condition: '',
        description: '', // Swap info placeholder
        imageUrl: '',
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

  // ================= Full Create Book (with image & swap info) =================
  Future<bool> createBook({
    required String title,
    required String author,
    required String genre,
    required String condition,
    required String description, // "Swap For" info stored here
    required String ownerName,
    String? imagePath,
  }) async {
    try {
      // Check if user is authenticated
      final userId = _firestoreService.currentUserId;
      if (userId == null || userId.isEmpty) {
        _errorMessage = 'Please log in to add a book';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String imageUrl = '';
      
      // Handle image upload - check if it's a local file path or URL
      if (imagePath != null && imagePath.isNotEmpty) {
        // Check if it's a URL (starts with http) or a local file path
        if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
          // It's already a URL from OpenLibrary
          imageUrl = imagePath;
        } else {
          // It's a local file path - upload to Firebase Storage
          try {
            imageUrl = await _storageService.uploadBookImage(imagePath);
          } catch (e) {
            print('Image upload error: $e');
            // Continue without image if upload fails
            imageUrl = '';
          }
        }
      }

      final book = BookModel(
        id: '',
        ownerId: userId,
        ownerName: ownerName,
        title: title,
        author: author,
        genre: genre,
        condition: condition,
        description: description, // swap info
        imageUrl: imageUrl,
        status: 'available',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createBook(book);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('Create book error: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ================= Update Book =================
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

      if (newImagePath != null && newImagePath.isNotEmpty) {
        if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
          await _storageService.deleteImage(currentImageUrl);
        }
        imageUrl = await _storageService.uploadBookImage(newImagePath);
      }

      final updates = {
        'title': title,
        'author': author,
        'genre': genre,
        'condition': condition,
        'description': description, // update swap info
        'imageUrl': imageUrl,
        'updatedAt': DateTime.now(),
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

  // ================= Delete Book =================
  Future<bool> deleteBook(String bookId, String? imageUrl) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

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

  // ================= Clear Error =================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}