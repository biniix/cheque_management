import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/accounts_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/view_cheques_screen.dart';

/// Floating white sidebar card with blue accent — minimal, grouped sections.
class Sidebar extends ConsumerWidget {
  final String currentRoute;
  final void Function(int index)? onNavigate;

  const Sidebar({super.key, required this.currentRoute, this.onNavigate});

  // ── Route mapping (maintains original functionality) ──
  static const _allRoutes = [
    '/home', '/accounts', '/customers',
    '/transactions', '/view-cheques',
  ];

  // ── All navigation items as a flat list ──
  static const _navItems = [
    _NavItem('Home', Icons.home_outlined, 0),
    _NavItem('Accounts', Icons.account_balance_outlined, 1),
    _NavItem('Customers', Icons.people_outlined, 2),
    _NavItem('Transactions', Icons.receipt_long_outlined, 3),
    _NavItem('Cheques', Icons.check_circle_outlined, 4),
  ];

  static Widget _pageForRoute(String route) {
    switch (route) {
      case '/home':
        return const HomeScreen();
      case '/accounts':
        return const AccountsScreen();
      case '/customers':
        return const CustomersScreen();
      case '/transactions':
        return const TransactionsScreen();
      case '/view-cheques':
        return const ViewChequesScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.userName ?? 'User';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Scrollable nav area ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    _buildLogo(),
                    const SizedBox(height: 28),

                    // Nav items
                    ..._navItems.map((item) {
                      final route = _allRoutes[item.index];
                      final isActive = currentRoute == route;
                      return _buildNavItem(
                        context,
                        item.icon,
                        item.label,
                        item.index,
                        isActive,
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Bottom: User profile ──
            _buildUserProfile(context, ref, userName),
          ],
        ),
      ),
    );
  }

  // ── Logo ──
  Widget _buildLogo() {
    return Row(
      children: [
        // App logo
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/logos/my_ledger.png',
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'My Ledger',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F2937),
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  // ── Nav item (blue active state with hover effects) ──
  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: _SidebarNavItem(
        icon: icon,
        label: label,
        index: index,
        isActive: isActive,
        currentRoute: currentRoute,
        onNavigate: onNavigate,
      ),
    );
  }

  // ── User profile at bottom ──
  Widget _buildUserProfile(BuildContext context, WidgetRef ref, String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFFF3F4F6).withValues(alpha: 0.8)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(authProvider.notifier).logout();
            Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Avatar initial with blue bg
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    userName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.logout_rounded,
                  size: 15,
                  color: Color(0xFF2563EB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav item (no hover effect) ──
class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isActive;
  final String currentRoute;
  final void Function(int index)? onNavigate;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isActive,
    required this.currentRoute,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final route = Sidebar._allRoutes[index];
          if (currentRoute != route) {
            if (onNavigate != null) {
              onNavigate!(index);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => Sidebar._pageForRoute(route)),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF2563EB)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? Colors.white
                    : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final int index;
  const _NavItem(this.label, this.icon, this.index);
}
