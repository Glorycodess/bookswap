import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> with SingleTickerProviderStateMixin {
  final Color _purple = const Color(0xFF4A148C);
  final TextEditingController _nameInputController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _loading = true;
  String _displayName = '';
  String _email = '';
  int _booksSwapped = 0;
  int _activeChats = 0;
  DateTime? _memberSince;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadPrefs();
  }

  @override
  void dispose() {
    _nameInputController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_name');
    final savedNotif = prefs.getBool('notifications_enabled');
    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.displayName;
    final email = currentUser?.email;
    final userId = currentUser?.uid;

    // Load profile stats
    int booksSwapped = 0;
    int activeChats = 0;
    DateTime? memberSince;

    if (userId != null) {
      try {
        // Get books swapped count
        final swapsSnapshot = await FirebaseFirestore.instance
            .collection('swaps')
            .where('requesterId', isEqualTo: userId)
            .where('status', isEqualTo: 'completed')
            .get();
        booksSwapped = swapsSnapshot.docs.length;

        // Get active chats count
        final chatsSnapshot = await FirebaseFirestore.instance
            .collection('swaps')
            .where('requesterId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .get();
        activeChats = chatsSnapshot.docs.length;

        // Get member since date
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final createdAt = userDoc.data()?['createdAt'] as Timestamp?;
          if (createdAt != null) {
            memberSince = createdAt.toDate();
          }
        }
      } catch (e) {
        debugPrint('Error loading stats: $e');
      }
    }

    setState(() {
      _displayName = (savedName?.trim().isNotEmpty == true)
          ? savedName!.trim()
          : (displayName?.trim().isNotEmpty == true ? displayName!.trim() : '');
      _email = email ?? '';
      _notificationsEnabled = savedNotif ?? true;
      _booksSwapped = booksSwapped;
      _activeChats = activeChats;
      _memberSince = memberSince;
      _loading = false;
    });

    _animationController.forward();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _saveName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Name cannot be empty', style: GoogleFonts.poppins())),
        );
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', trimmed);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(trimmed);
    }
    if (mounted) {
      setState(() => _displayName = trimmed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated', style: GoogleFonts.poppins())),
      );
    }
  }

  Future<void> _showChangeNameDialog() async {
    _nameInputController.text = _displayName;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Change Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _purple)),
          content: TextField(
            controller: _nameInputController,
            decoration: InputDecoration(
              labelText: 'Display Name',
              labelStyle: GoogleFonts.poppins(color: _purple),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _purple, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _purple.withOpacity(0.3)),
              ),
            ),
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(_nameInputController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await _saveName(result);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Notifications enabled' : 'Notifications disabled',
          style: GoogleFonts.poppins(),
        ),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  color: _purple,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              // Bold Profile Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _purple.withOpacity(0.1),
                      _purple.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _purple.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Large gradient avatar with initials
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8E2DE2), Color(0xFF4A148C)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _purple.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_displayName),
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name
                    Text(
                      _displayName.isNotEmpty ? _displayName : 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Email
                    if (_email.isNotEmpty)
                      Text(
                        _email,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Profile Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Books Swapped',
                          value: _booksSwapped.toString(),
                          icon: Icons.swap_horiz,
                          purple: _purple,
                        ),
                        _StatItem(
                          label: 'Active Chats',
                          value: _activeChats.toString(),
                          icon: Icons.chat_bubble,
                          purple: _purple,
                        ),
                        if (_memberSince != null)
                          _StatItem(
                            label: 'Member Since',
                            value: '${_memberSince!.month}/${_memberSince!.year}',
                            icon: Icons.calendar_today,
                            purple: _purple,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Gradient Change Name Button
                    SizedBox(
                      height: 50,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showChangeNameDialog,
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8E2DE2), Color(0xFF4A148C)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _purple.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Change Name',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Account Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: _purple.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Details',
                      style: GoogleFonts.poppins(
                        color: _purple,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PrefRow(
                      title: 'Email',
                      value: _email.isNotEmpty ? _email : 'Not provided',
                      purple: _purple,
                    ),
                    const SizedBox(height: 12),
                    _PrefRow(
                      title: 'Notifications',
                      value: _notificationsEnabled ? 'Enabled' : 'Disabled',
                      purple: _purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Notifications Toggle Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: _purple.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  title: Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    _notificationsEnabled ? 'Receive updates about swaps and messages' : 'Notifications are disabled',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  activeColor: Colors.white,
                  activeTrackColor: _purple,
                  inactiveThumbColor: const Color(0xFF9CA3AF),
                  inactiveTrackColor: const Color(0xFFE5E7EB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
              ),
              const SizedBox(height: 24),
              // Logout Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white, size: 22),
                  label: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color purple;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: purple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: purple, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PrefRow extends StatelessWidget {
  final String title;
  final String value;
  final Color purple;

  const _PrefRow({
    required this.title,
    required this.value,
    required this.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4B5563),
            ),
          ),
        ),
      ],
    );
  }
}
