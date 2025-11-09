import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../providers/book_provider.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _lookingForController = TextEditingController();

  String _condition = 'New';
  File? _selectedImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _fetchCoverUrl(String title, String author) async {
    final query = Uri.encodeComponent('$title $author');
    final url = 'https://openlibrary.org/search.json?q=$query';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['docs'] != null && data['docs'].isNotEmpty) {
          final coverId = data['docs'][0]['cover_i'];
          if (coverId != null) {
            return 'https://covers.openlibrary.org/b/id/$coverId-L.jpg';
          }
        }
      }
    } catch (_) {}
    return null;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    String? imageUrl = _selectedImage?.path;

    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = await _fetchCoverUrl(
        _titleController.text.trim(),
        _authorController.text.trim(),
      );
    }

    bool success = await context.read<BookProvider>().createBook(
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          genre: '',
          condition: _condition,
          description: _lookingForController.text.trim(),
          ownerName: 'Anonymous',
          imagePath: imageUrl,
        );

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Book added successfully!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _titleController.clear();
      _authorController.clear();
      _lookingForController.clear();
      setState(() {
        _condition = 'New';
        _selectedImage = null;
      });
    } else {
      final error = context.read<BookProvider>().errorMessage ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add book: $error'),
          backgroundColor: Colors.red.shade600,
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

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Add New Book', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker section with preview
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 180,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, 
                                size: 64, 
                                color: primaryColor.withOpacity(0.5)),
                              SizedBox(height: 12),
                              Text(
                                'Add Cover Image',
                                style: GoogleFonts.poppins(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tap to select',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              if (_selectedImage == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      'Or we\'ll find one automatically',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 32),

              // Book Title
              Text('Book Information', 
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
              SizedBox(height: 16),
              
              _buildTextField(
                controller: _titleController,
                label: 'Book Title',
                hint: 'e.g., The Great Gatsby',
                icon: Icons.menu_book_rounded,
                primaryColor: primaryColor,
              ),
              SizedBox(height: 16),

              // Author Name
              _buildTextField(
                controller: _authorController,
                label: 'Author Name',
                hint: 'e.g., F. Scott Fitzgerald',
                icon: Icons.person_outline_rounded,
                primaryColor: primaryColor,
              ),
              SizedBox(height: 16),

              // Condition dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _condition,
                  decoration: InputDecoration(
                    labelText: 'Book Condition',
                    labelStyle: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.w500),
                    prefixIcon: Icon(Icons.stars_rounded, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: ['New', 'Like New', 'Good', 'Fair', 'Used']
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: GoogleFonts.poppins()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _condition = value);
                  },
                ),
              ),
              SizedBox(height: 16),

              // Looking For (better naming than "Swap For")
              _buildTextField(
                controller: _lookingForController,
                label: 'Looking For (Optional)',
                hint: 'What books are you interested in?',
                icon: Icons.search_rounded,
                primaryColor: primaryColor,
                maxLines: 2,
                isRequired: false,
              ),
              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: accentColor.withOpacity(0.3),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Add Book',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color primaryColor,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.w500),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) => isRequired && (value == null || value.isEmpty)
            ? 'Please enter $label'
            : null,
      ),
    );
  }
}