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
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String imageUrl = '';
      if (imagePath != null && imagePath.isNotEmpty) {
        imageUrl = await _storageService.uploadBookImage(imagePath);
      }

      final book = BookModel(
        id: '',
        ownerId: _firestoreService.currentUserId ?? '',
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
      notifyListeners();
      return true;
    } catch (e) {
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