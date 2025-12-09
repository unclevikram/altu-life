import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/features/ask_altu/presentation/screens/ask_altu_screen.dart';
import 'package:altu_life/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:altu_life/features/insights/presentation/screens/insights_screen.dart';
import 'package:altu_life/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Home screen that contains the bottom navigation and page views.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  AppTab _currentTab = AppTab.dashboard;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabChanged(AppTab tab) {
    if (_currentTab == tab) return;

    _fadeController.reverse().then((_) {
      setState(() => _currentTab = tab);
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content with fade animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildCurrentPage(),
          ),

          // Bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              currentTab: _currentTab,
              onTabChanged: _onTabChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentTab) {
      case AppTab.dashboard:
        return const DashboardScreen();
      case AppTab.insights:
        return const InsightsScreen();
      case AppTab.chat:
        return const AskAltuScreen();
    }
  }
}

