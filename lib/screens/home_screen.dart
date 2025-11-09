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
          // REMOVED: Duplicate top "BookSwap" — now only one in BrowseTab
          // Tab content (each tab handles its own header)
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

// REMOVED: _AppHeader class — duplicate "BookSwap" header removed
// Each tab now handles its own header (BrowseTab has the main header)

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
