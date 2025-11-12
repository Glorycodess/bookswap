import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/book_model.dart';

class BookProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<BookModel> _browseBooks = [];
  List<BookModel> _myBooks = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscriptions
  StreamSubscription<List<BookModel>>? _browseBooksSubscription;
  StreamSubscription<List<BookModel>>? _myBooksSubscription;

  List<BookModel> get browseBooks => _browseBooks;
  List<BookModel> get myBooks => _myBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ================= Browse Books =================
  void getBrowseListings() {
    // Cancel existing subscription if any
    _browseBooksSubscription?.cancel();

    final currentUserId = _firestoreService.currentUserId ?? '';
    print('BookProvider: Setting up browse listings stream for user: $currentUserId');

    _isLoading = true;
    notifyListeners();

    // Create new subscription and store it
    _browseBooksSubscription = _firestoreService.getBrowseListings(currentUserId).listen(
      (List<BookModel> books) {
        print('BookProvider: Received ${books.length} books from stream');
        
        // Note: Books are already sorted by FirestoreService (newest first)
        
        // ✅ Mark user's own books
        _browseBooks = books.map((book) {
          return book.copyWith(
            isMine: book.ownerId == currentUserId,
          );
        }).toList();

        print('BookProvider: Updated browseBooks list with ${_browseBooks.length} books');
        _isLoading = false;
        _errorMessage = null; // Clear any previous errors
        notifyListeners();
      },
      onError: (error) {
        print('BookProvider: Error loading browse books: $error');
        print('BookProvider: Error stack trace: ${StackTrace.current}');
        _errorMessage = error.toString();
        _isLoading = false;
        _browseBooks = []; // Clear books on error
        notifyListeners();
      },
      cancelOnError: false, // Keep stream alive even on error
    );
  }

  // ================= My Books =================
  void getMyBooks() {
    // Cancel existing subscription if any
    _myBooksSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    final currentUserId = _firestoreService.currentUserId ?? '';

    // Create new subscription and store it
    _myBooksSubscription = _firestoreService.getMyBooks(currentUserId).listen(
      (List<BookModel> books) {
        _myBooks = books;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        print('Error loading my books: $error');
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ================= Add Simple Book =================
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
        description: '',
        imageBase64: '',
        status: 'available',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createBook(book);

      // Note: Stream will automatically update, no need to call getBrowseListings() again

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

  // ================= Full Create Book =================
  Future<bool> createBook({
    required String title,
    required String author,
    required String genre,
    required String condition,
    required String description,
    required String ownerName,
    String? imageBase64,
  }) async {
    try {
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

      final book = BookModel(
        id: '',
        ownerId: userId,
        ownerName: ownerName,
        title: title,
        author: author,
        genre: genre,
        condition: condition,
        description: description,
        imageBase64: imageBase64 ?? '',
        status: 'available',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('BookProvider: Creating book with status: ${book.status}, title: ${book.title}');
      final bookId = await _firestoreService.createBook(book);
      print('BookProvider: Book created successfully with ID: $bookId');

      // Note: Stream will automatically update when Firestore document is created
      // The Firestore stream listener will receive the new book automatically
      // No need to call getBrowseListings() again - it would create duplicate subscriptions

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
    String? imageBase64,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updates = {
        'title': title,
        'author': author,
        'genre': genre,
        'condition': condition,
        'description': description,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (imageBase64 != null) {
        updates['imageBase64'] = imageBase64;
      }

      await _firestoreService.updateBook(bookId, updates);

      // Note: Stream will automatically update, no need to call getBrowseListings() again

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
  Future<bool> deleteBook(String bookId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.deleteBook(bookId);

      // Note: Stream will automatically update, no need to call getBrowseListings() again

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

  @override
  void dispose() {
    // Cancel all stream subscriptions when provider is disposed
    _browseBooksSubscription?.cancel();
    _myBooksSubscription?.cancel();
    super.dispose();
  }
}