import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/book_provider.dart';
import '../screens/add_book_page.dart';
import '../screens/book_details_page.dart';

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
    final bookProvider = context.read<BookProvider>();
    bookProvider.getBrowseListings();
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

  void _showBookOptions(BuildContext context, book) {
    final primaryColor = Color(0xFF6C5CE7);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.symmetric(vertical: 20),
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
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: primaryColor),
              title: Text('Edit Book', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Edit feature coming soon'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade600),
              title: Text('Delete Book',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade600,
                  )),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, book.id, book.imageUrl);
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String bookId, String? imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange.shade600, size: 28),
            SizedBox(width: 12),
            Text('Delete Book', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this book? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<BookProvider>().deleteBook(bookId, imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(success ? Icons.check_circle : Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text(success ? 'Book deleted successfully' : 'Failed to delete book'),
            ],
          ),
          backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF6C5CE7);
    final accentColor = Color(0xFF00B894);
    final bookProvider = context.watch<BookProvider>();
    final books = bookProvider.browseBooks;

    final filteredBooks = _searchQuery.isEmpty
        ? books
        : books
            .where((book) =>
                book.title.toLowerCase().contains(_searchQuery) ||
                book.author.toLowerCase().contains(_searchQuery))
            .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);

    // REMOVED: "BookSwap", subtitle, and logo — cleaner header
    // KEPT: "Browse Books", count, and search
    // FIXED: Clean minimal header with gradient, rounded corners, SafeArea, full bleed
    return Stack(
      children: [
        // Main content column
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIXED: Clean minimal header with gradient background
            // Full bleed gradient with rounded bottom corners, no white line/gap
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Browse Books" title — large, bold, no icon
                      Text(
                        'Browse Books',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Book count — smaller text below title
                      Text(
                        '${filteredBooks.length} books available',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Clean search bar — full-width, rounded, with shadow
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value.toLowerCase()),
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            hintText: 'Search by title or author...',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 24),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Books Grid
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: bookProvider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
                      )
                    : filteredBooks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book_rounded, size: 80, color: Colors.grey.shade300),
                                SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty ? 'No books yet' : 'No books found',
                                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              // FIXED: Changed childAspectRatio from 0.58 to 0.72 to prevent overflow
                              childAspectRatio: 0.72,
                            ),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];
                              return _buildBookCard(book, primaryColor, accentColor);
                            },
                          ),
              ),
            ),
          ],
        ),
        // FAB positioned manually (no Scaffold needed)
        Positioned(
          right: 16,
          bottom: 80,
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBookPage()),
            ),
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            elevation: 6,
            icon: Icon(Icons.add_rounded, size: 24),
            label: Text(
              'Add Book',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(book, Color primaryColor, Color accentColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailsPage(book: book)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // FIXED: Subtle shadow for modern card design
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIXED: Book Cover with fixed aspect ratio and proper fit
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: book.imageUrl != null && book.imageUrl.isNotEmpty
                    ? Image.network(
                        book.imageUrl,
                        // FIXED: BoxFit.cover to prevent image overflow and ensure consistent sizing
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            // FIXED: Text section with proper spacing and overflow handling
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // FIXED: Title - 1 line max, bold, 13sp, ellipsis
                  Text(
                    book.title ?? 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  SizedBox(height: 6),
                  // FIXED: Author - 1 line max, 11sp, ellipsis
                  Text(
                    book.author ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      height: 1.2,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Placeholder image with proper sizing and aspect ratio
  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 48,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
