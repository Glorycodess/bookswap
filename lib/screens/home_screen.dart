import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tabs/browse_tab.dart';
import '../tabs/chats_tab.dart';
import '../tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _index = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const BrowseTab(key: ValueKey('Browse')),
      _PlaceholderTab(title: 'Listings', key: const ValueKey('Listings')),
      const ChatsTab(key: ValueKey('Chat')),
      const SettingsTab(key: ValueKey('Settings')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Bold header with purple gradient
          _AppHeader(),
          // Tab content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: IndexedStack(
                key: ValueKey(_index),
                index: _index,
                children: _pages,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

// Clean header with purple gradient
class _AppHeader extends StatefulWidget {
  @override
  State<_AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<_AppHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // App logo/icon - slightly smaller
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // App name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BookSwap',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Swap books, share stories',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Themed bottom navigation bar with purple accents
class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF8E2DE2).withOpacity(0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 70,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.explore_outlined,
              color: selectedIndex == 0
                  ? const Color(0xFF8E2DE2)
                  : const Color(0xFF9CA3AF),
            ),
            selectedIcon: const Icon(
              Icons.explore,
              color: Color(0xFF8E2DE2),
            ),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.library_books_outlined,
              color: selectedIndex == 1
                  ? const Color(0xFF8E2DE2)
                  : const Color(0xFF9CA3AF),
            ),
            selectedIcon: const Icon(
              Icons.library_books,
              color: Color(0xFF8E2DE2),
            ),
            label: 'Listings',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.chat_bubble_outline,
              color: selectedIndex == 2
                  ? const Color(0xFF8E2DE2)
                  : const Color(0xFF9CA3AF),
            ),
            selectedIcon: const Icon(
              Icons.chat_bubble,
              color: Color(0xFF8E2DE2),
            ),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
              color: selectedIndex == 3
                  ? const Color(0xFF8E2DE2)
                  : const Color(0xFF9CA3AF),
            ),
            selectedIcon: const Icon(
              Icons.settings,
              color: Color(0xFF8E2DE2),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Placeholder tab for Listings
class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}
