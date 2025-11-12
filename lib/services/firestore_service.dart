import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../models/swap_request_model.dart';
import '../models/chat_message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ================= BOOK OPERATIONS =================

  // Create a new book listing
  Future<String> createBook(BookModel book) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('books').add(book.toMap());
      return docRef.id;
    } catch (e) {
      print('Create book error: $e');
      rethrow;
    }
  }

  // Get all available books, including current user's books
  Stream<List<BookModel>> getBrowseListings(String currentUserId) {
    // ✅ Fetch all available books
    // Note: We filter by status only, sorting is done in Dart to avoid index requirement
    try {
      return _firestore
          .collection('books')
          .where('status', isEqualTo: 'available')
          .snapshots()
          .map((snapshot) {
            try {
              if (snapshot.docs.isEmpty) {
                return <BookModel>[];
              }
              final books = snapshot.docs
                  .map((doc) {
                    try {
                      final data = doc.data();
                      if (data.isEmpty) return null;
                      return BookModel.fromMap(data, doc.id);
                    } catch (e) {
                      print('Error parsing book document ${doc.id}: $e');
                      return null;
                    }
                  })
                  .whereType<BookModel>()
                  .toList();
              
              // Sort by createdAt descending (newest first)
              books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              
              return books;
            } catch (e) {
              print('Error processing books snapshot: $e');
              return <BookModel>[];
            }
          })
          .handleError((error) {
            print('Error in getBrowseListings stream: $error');
            return <BookModel>[];
          });
    } catch (e) {
      print('Error creating getBrowseListings stream: $e');
      return Stream.value(<BookModel>[]);
    }
  }

  // Get current user's books
  Stream<List<BookModel>> getMyBooks(String currentUserId) {
    return _firestore
        .collection('books')
        .where('ownerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get a single book by ID
  Future<BookModel?> getBook(String bookId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('books').doc(bookId).get();
      if (doc.exists) {
        return BookModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Get book error: $e');
    }
    return null;
  }

  // Update a book
  Future<void> updateBook(String bookId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection('books').doc(bookId).update(updates);
    } catch (e) {
      print('Update book error: $e');
      rethrow;
    }
  }

  // Delete a book
  Future<void> deleteBook(String bookId) async {
    try {
      await _firestore.collection('books').doc(bookId).delete();
    } catch (e) {
      print('Delete book error: $e');
      rethrow;
    }
  }

  // ================= SWAP OPERATIONS =================
  Future<String> createSwapRequest(SwapRequestModel swapRequest) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('swap_requests').add(swapRequest.toMap());

      // Update both books' status to pending
      await updateBook(swapRequest.requesterBookId, {'status': 'pending'});
      await updateBook(swapRequest.recipientBookId, {'status': 'pending'});

      return docRef.id;
    } catch (e) {
      print('Create swap request error: $e');
      rethrow;
    }
  }

  Stream<List<SwapRequestModel>> getReceivedSwapRequests() {
    final currentUser = currentUserId;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('swap_requests')
        .where('recipientId', isEqualTo: currentUser)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SwapRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<SwapRequestModel>> getSentSwapRequests() {
    final currentUser = currentUserId;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('swap_requests')
        .where('requesterId', isEqualTo: currentUser)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SwapRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> acceptSwapRequest(
      String swapId, String requesterBookId, String recipientBookId) async {
    try {
      await _firestore.collection('swap_requests').doc(swapId).update({
        'status': 'accepted',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await updateBook(requesterBookId, {'status': 'swapped'});
      await updateBook(recipientBookId, {'status': 'swapped'});
    } catch (e) {
      print('Accept swap error: $e');
      rethrow;
    }
  }

  Future<void> rejectSwapRequest(
      String swapId, String requesterBookId, String recipientBookId) async {
    try {
      await _firestore.collection('swap_requests').doc(swapId).update({
        'status': 'rejected',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await updateBook(requesterBookId, {'status': 'available'});
      await updateBook(recipientBookId, {'status': 'available'});
    } catch (e) {
      print('Reject swap error: $e');
      rethrow;
    }
  }

  Future<void> updateSwapRequest(String swapId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('swap_requests').doc(swapId).update(updates);
    } catch (e) {
      print('Update swap request error: $e');
      rethrow;
    }
  }

  // ================= CHAT OPERATIONS =================
  Future<String> createChat({
    required String otherUserId,
    required String otherUserName,
    required String swapRequestId,
    required String bookTitle,
  }) async {
    try {
      String currentUserName = _auth.currentUser?.displayName ?? 'User';

      DocumentReference docRef = await _firestore.collection('chats').add({
        'participants': [currentUserId, otherUserId],
        'participantNames': {
          currentUserId!: currentUserName,
          otherUserId: otherUserName,
        },
        'swapRequestId': swapRequestId,
        'bookTitle': bookTitle,
        'lastMessage': '',
        'lastMessageTime': DateTime.now().toIso8601String(),
        'unreadCount': {
          currentUserId: 0,
          otherUserId: 0,
        },
      });

      return docRef.id;
    } catch (e) {
      print('Create chat error: $e');
      rethrow;
    }
  }

  Stream<List<QueryDocumentSnapshot>> getUserChats() {
    final currentUser = currentUserId;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String recipientId,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(ChatMessageModel(
            id: '',
            senderId: currentUserId!,
            text: text,
            timestamp: DateTime.now(),
            read: false,
          ).toMap());

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': DateTime.now().toIso8601String(),
        'unreadCount.$recipientId': FieldValue.increment(1),
      });
    } catch (e) {
      print('Send message error: $e');
      rethrow;
    }
  }

  Stream<List<ChatMessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$currentUserId': 0,
      });
    } catch (e) {
      print('Mark messages as read error: $e');
    }
  }
}
