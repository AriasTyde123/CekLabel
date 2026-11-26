import 'package:flutter/material.dart';

import '../routes.dart';
import '../widgets/home_cards.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'scan_collection_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, this.initialTab = HomeTab.home});

  final HomeTab initialTab;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late HomeTab _currentTab;
  final ScrollController _homeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
  }

  void _selectTab(HomeTab tab) {
    if (tab == HomeTab.home && _currentTab == HomeTab.home) {
      if (_homeScrollController.hasClients) {
        _homeScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
      return;
    }
    if (_currentTab != tab) {
      setState(() => _currentTab = tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          HomeScreen(
            onSelectTab: _selectTab,
            scrollController: _homeScrollController,
          ),
          const ScanCollectionScreen(embedded: true),
          const ScanCollectionScreen(safeOnly: true, embedded: true),
          const ProfileScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: HomeNav(
        currentTab: _currentTab,
        onHome: () => _selectTab(HomeTab.home),
        onHistory: () => _selectTab(HomeTab.history),
        onScan: () => Navigator.pushNamed(context, AppRoutes.scan),
        onSafe: () => _selectTab(HomeTab.safeList),
        onProfile: () => _selectTab(HomeTab.profile),
      ),
    );
  }
}

