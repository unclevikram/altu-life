import 'dart:ui';

import 'package:altu_life/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// The app's navigation tabs.
enum AppTab {
  dashboard,
  insights,
  chat,
}

/// Bottom navigation bar with glassmorphism effect.
///
/// Matches the React app's Navigation component with frosted glass
/// background and tab-specific active colors.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  /// The currently selected tab.
  final AppTab currentTab;

  /// Callback when a tab is selected.
  final ValueChanged<AppTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: const Border(
          top: BorderSide(color: AppColors.slate200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            top: false,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: LucideIcons.layoutDashboard,
                    label: 'Dashboard',
                    isActive: currentTab == AppTab.dashboard,
                    activeColor: AppColors.brand600,
                    onTap: () => _onTap(AppTab.dashboard),
                  ),
                  _NavItem(
                    icon: LucideIcons.lightbulb,
                    label: 'Insights',
                    isActive: currentTab == AppTab.insights,
                    activeColor: AppColors.amber500,
                    onTap: () => _onTap(AppTab.insights),
                  ),
                  _NavItem(
                    icon: LucideIcons.messageCircle,
                    label: 'Ask Altu',
                    isActive: currentTab == AppTab.chat,
                    activeColor: AppColors.violet600,
                    onTap: () => _onTap(AppTab.chat),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(AppTab tab) {
    // Haptic feedback on tab change
    HapticFeedback.lightImpact();
    onTabChanged(tab);
  }
}

/// Individual navigation item with icon and label.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        transform: Matrix4.identity()..scale(isActive ? 1.05 : 1.0),
        transformAlignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? activeColor : AppColors.slate400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeColor : AppColors.slate400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

