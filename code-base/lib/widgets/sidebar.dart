import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/accounts_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/postponed_cheques_screen.dart';
import '../screens/view_cheques_screen.dart';
import '../screens/deposit_screen.dart';
import '../screens/transfer_screen.dart';
import '../screens/admin/employee_list_screen.dart';
import '../screens/admin/audit_logs_screen.dart';
import '../screens/template_editor_screen.dart';
import '../screens/template_list_screen.dart';

/// Floating white sidebar card with blue accent — minimal, grouped sections.
class Sidebar extends ConsumerWidget {
  final String currentRoute;
  final void Function(int index)? onNavigate;

  const Sidebar({super.key, required this.currentRoute, this.onNavigate});

  // ── Route mapping (maintains original functionality) ──
  static const _allRoutes = [
    '/home',
    '/accounts',
    '/customers',
    '/transfer',
    '/deposit',
    '/view-cheques',
    '/transactions',
    '/postponed-cheques',
  ];

  // ── All navigation items as a flat list ──
  // Each item maps to a module key used for employee access control.
  static const _navItems = [
    _NavItem('Home', Icons.home_outlined, 0, 'home'),
    _NavItem('Accounts', Icons.account_balance_outlined, 1, 'accounts'),
    _NavItem('Customers', Icons.people_outlined, 2, 'customers'),
    _NavItem('Transfers', Icons.north_east_rounded, 3, 'transfers'),
    _NavItem('Deposits', Icons.south_west_rounded, 4, 'deposits'),
    _NavItem('Cheques', Icons.check_circle_outlined, 5, 'cheques'),
    _NavItem('Transactions', Icons.receipt_long_outlined, 6, 'transactions'),
    _NavItem('Postponed Cheques', Icons.event_available_outlined, 7, 'cheques'),
  ];

  // ── Admin nav items (shown only to admins) ──
  static const _adminItems = [
    _NavItem('Employees', Icons.group_outlined, 0, 'admin',
        route: '/admin/employees'),
    _NavItem('Audit Log', Icons.history_rounded, 1, 'admin',
        route: '/admin/audit-logs'),
    _NavItem('Templates', Icons.dashboard_customize_outlined, 2, 'admin',
        route: '/admin/template-list'),
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
      case '/postponed-cheques':
        return const PostponedChequesScreen();
      case '/transfer':
        return const TransferScreen();
      case '/deposit':
        return const DepositScreen();
      case '/view-cheques':
        return const ViewChequesScreen();
      case '/admin/employees':
        return const EmployeeListScreen();
      case '/admin/audit-logs':
        return const AuditLogsScreen();
      case '/admin/template-list':
        return const TemplateListScreen();
      case '/admin/template-editor':
        return const TemplateEditorScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.userName ?? 'User';
    final employeeId = authState.employeeId ?? '';

    // Admins see every module, plus the dedicated admin section below.
    // Everyone else sees exactly the modules they were granted — no implicit
    // extras (e.g. 'transactions' no longer implies Transfers/Deposits).
    final visibleItems = authState.isAdmin
        ? _navItems
        : _navItems
            .where((item) => authState.canAccess(item.module))
            .toList();

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

                    // Admin section (top, admins only)
                    if (authState.isAdmin) ...[
                      _sectionLabel('ADMIN'),
                      ..._adminItems.map((item) {
                        final isActive = currentRoute == item.route;
                        return _buildNavItem(
                          context,
                          item.icon,
                          item.label,
                          item.index,
                          isActive,
                          item.module,
                          admin: true,
                          route: item.route,
                        );
                      }),
                      const SizedBox(height: 20),
                    ],

                    // Workspace section (admins see all, others filtered by access)
                    if (visibleItems.isNotEmpty) _sectionLabel('WORKSPACE'),
                    ...visibleItems.map((item) {
                      final route = _allRoutes[item.index];
                      final isActive = currentRoute == route;
                      return _buildNavItem(
                        context,
                        item.icon,
                        item.label,
                        item.index,
                        isActive,
                        item.module,
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Bottom: User profile ──
            _buildUserProfile(context, ref, userName, employeeId),
          ],
        ),
      ),
    );
  }

  // ── Logo text (no image) ──
  Widget _buildLogo() {
    return Text(
      'Cheque Management',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1F2937),
        letterSpacing: -0.4,
      ),
    );
  }

  // ── Section header (ADMIN / WORKSPACE) ──
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: const Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  // ── Nav item (blue active state with hover effects) ──
  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool isActive,
    String module, {
    bool admin = false,
    String? route,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: _SidebarNavItem(
        icon: icon,
        label: label,
        index: index,
        isActive: isActive,
        currentRoute: currentRoute,
        onNavigate: onNavigate,
        admin: admin,
        route: route,
      ),
    );
  }

  // ── User profile at bottom ──
  Widget _buildUserProfile(
      BuildContext context, WidgetRef ref, String userName, String employeeId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          top:
              BorderSide(color: const Color(0xFFF3F4F6).withValues(alpha: 0.8)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (employeeId.isNotEmpty)
                        Text(
                          employeeId,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF9CA3AF),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
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
  final bool admin;
  final String? route;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isActive,
    required this.currentRoute,
    this.onNavigate,
    this.admin = false,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final route =
              admin ? (this.route ?? '/admin/employees') : Sidebar._allRoutes[index];
          if (currentRoute != route) {
            if (onNavigate != null) {
              onNavigate!(index);
            } else if (admin || route == '/transfer' || route == '/deposit') {
              // Admin & form screens push on top so back button works
              Navigator.pushNamed(context, route);
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
            color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF374151),
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
  final String module;

  /// Explicit route for admin nav items (normal items derive it from [index]).
  final String? route;

  const _NavItem(this.label, this.icon, this.index, this.module,
      {this.route});
}
