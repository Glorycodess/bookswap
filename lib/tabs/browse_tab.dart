import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/book_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/add_book_page.dart';
import '../screens/book_details_page.dart';
import '../screens/edit_book_page.dart';
import '../models/book_model.dart';

class BrowseTab extends StatefulWidget {
  const BrowseTab({super.key});

  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize stream when tab is created
    // Note: IndexedStack keeps all tabs alive, so this runs once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bookProvider = context.read<BookProvider>();
        print('BrowseTab: Initializing browse listings stream');
        bookProvider.getBrowseListings();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _calculateCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1200) return 4;
    if (screenWidth >= 900) return 3;
    if (screenWidth >= 600) return 2;
    return 2;
  }

  void _showBookOptions(BuildContext context, BookModel book) {
    final primaryColor = Colors.purple.shade900;
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;
    final isOwner = currentUserId != null && book.ownerId == currentUserId;

    if (!isOwner) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: primaryColor),
              title: Text('Edit Book',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditBookPage(book: book)),
                );
                // Note: Stream will automatically update, no need to call getBrowseListings()
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade600),
              title: Text(
                'Delete Book',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, book.id);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String bookId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded,
                color: Colors.orange.shade600, size: 28),
            const SizedBox(width: 12),
            Text('Delete Book',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this book? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Delete',
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<BookProvider>().deleteBook(bookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(success ? Icons.check_circle : Icons.error_outline,
                    color: Colors.white),
                const SizedBox(width: 12),
                Text(success
                    ? 'Book deleted successfully'
                    : 'Failed to delete book'),
              ],
            ),
            backgroundColor:
                success ? Colors.green.shade600 : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.purple.shade900;
    final bookProvider = context.watch<BookProvider>();
    final books = bookProvider.browseBooks;

    final filteredBooks = _searchQuery.isEmpty
        ? books
        : books
            .where((book) =>
                book.title.toLowerCase().contains(_searchQuery) ||
                book.author.toLowerCase().contains(_searchQuery))
            .toList();

    // ✅ Sort so current user's books appear first
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    filteredBooks.sort((a, b) {
      if (a.ownerId == currentUserId && b.ownerId != currentUserId) return -1;
      if (a.ownerId != currentUserId && b.ownerId == currentUserId) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.menu_book_rounded,
                              color: primaryColor, size: 32),
                          const SizedBox(width: 12),
                          Text(
                            'Browse Books',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${filteredBooks.length} books available',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.grey.shade300, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(
                              () => _searchQuery = value.toLowerCase()),
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            hintText: 'Search by title or author...',
                            hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: primaryColor, size: 24),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded,
                                        color: Colors.grey.shade400),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(
                                          () => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: bookProvider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: primaryColor))
                    : filteredBooks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book_rounded,
                                    size: 80,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No books yet'
                                      : 'No books found',
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(
                                    20, 20, 20, 100),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book =
                                  filteredBooks[index];
                              return _buildBookCard(
                                  book, primaryColor, currentUserId);
                            },
                          ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 80,
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddBookPage()),
            ),
            // Note: Stream will automatically update when book is added, no need to call getBrowseListings()
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 6,
            icon: const Icon(Icons.add_rounded, size: 24),
            label: Text('Add Book',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(BookModel book, Color primaryColor, String? currentUserId) {
    final isOwner = currentUserId != null &&
        book.ownerId == currentUserId;

    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => BookDetailsPage(book: book)));
      },
      onLongPress: isOwner
          ? () => _showBookOptions(context, book)
          : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isOwner ? Colors.purple.shade700 : Colors.grey.shade200,
                  width: isOwner ? 2 : 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: book.imageBase64.isNotEmpty
                        ? Image.memory(
                            base64Decode(book.imageBase64),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.grey.shade900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                            color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isOwner)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showBookOptions(context, book),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.menu_book_rounded,
            size: 48, color: Colors.grey.shade400),
      ),
    );
  }
}