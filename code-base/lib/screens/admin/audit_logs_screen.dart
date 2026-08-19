import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/audit_log.dart';
import '../../providers/audit_logs_provider.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/app_header.dart';

/// Admin-only activity log: every login, logout, create, update, delete and
/// password change across the system, newest first.
class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  bool _loading = true;
  String? _action;
  String? _entity;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  static const _actions = <String, String>{
    'login': 'Login',
    'login_failed': 'Failed login',
    'logout': 'Logout',
    'create': 'Create',
    'update': 'Update',
    'delete': 'Delete',
    'password_change': 'Password change',
    'status_change': 'Status change',
  };

  static const _entities = <String, String>{
    'auth': 'Account',
    'employee': 'Employee',
    'account': 'Bank account',
    'customer': 'Customer',
    'transaction': 'Transaction',
    'transfer': 'Transfer',
    'cheque': 'Cheque',
    'chequebook': 'Cheque book',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await ref.read(auditLogsProvider.notifier).load(
          action: _action,
          entity: _entity,
          query: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        );
    if (mounted) setState(() => _loading = false);
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  /// Icon + accent color for each action type.
  (IconData, Color) _actionStyle(String action) {
    switch (action) {
      case 'login':
        return (Icons.login_rounded, const Color(0xFF2563EB));
      case 'login_failed':
        return (Icons.warning_amber_rounded, const Color(0xFFF59E0B));
      case 'logout':
        return (Icons.logout_rounded, const Color(0xFF6B7280));
      case 'create':
        return (Icons.add_circle_outline_rounded, const Color(0xFF10B981));
      case 'update':
        return (Icons.edit_outlined, const Color(0xFF2563EB));
      case 'delete':
        return (Icons.delete_outline_rounded, const Color(0xFFDC2626));
      case 'password_change':
        return (Icons.key_rounded, const Color(0xFF7C3AED));
      case 'status_change':
        return (Icons.swap_horiz_rounded, const Color(0xFFF59E0B));
      default:
        return (Icons.history_rounded, const Color(0xFF6B7280));
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(auditLogsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/admin/audit-logs'),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  title: 'Audit Log',
                  actions: [
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh_rounded,
                          size: 18, color: Color(0xFF2563EB)),
                      onPressed: _load,
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Filters row ──
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: _onSearchChanged,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search by name, ID or details…',
                                  prefixIcon: const Icon(Icons.search_rounded,
                                      size: 18, color: Color(0xFF9CA3AF)),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _filterDropdown<String>(
                                value: _action,
                                hint: 'All actions',
                                items: _actions,
                                onChanged: (v) {
                                  setState(() => _action = v);
                                  _load();
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _filterDropdown<String>(
                                value: _entity,
                                hint: 'All types',
                                items: _entities,
                                onChanged: (v) {
                                  setState(() => _entity = v);
                                  _load();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Count ──
                        Text(
                          '${logs.length} activit${logs.length == 1 ? 'y' : 'ies'} recorded',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── List ──
                        Expanded(
                          child: _loading
                              ? const Center(child: CircularProgressIndicator())
                              : logs.isEmpty
                                  ? _buildEmptyState(context)
                                  : ListView.separated(
                                      itemCount: logs.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) =>
                                          _buildLogCard(context, logs[index]),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dropdown used for the action and entity filters.
  Widget _filterDropdown<T>({
    required T? value,
    required String hint,
    required Map<String, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      hint: Text(
        hint,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
        overflow: TextOverflow.ellipsis,
      ),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text(hint,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF6B7280))),
        ),
        ...items.entries.map((e) => DropdownMenuItem<T>(
              value: e.key as T,
              child: Text(e.value,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF1A1D26))),
            )),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A1D26)),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          size: 18, color: Color(0xFF9CA3AF)),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildLogCard(BuildContext context, AuditLog log) {
    final (icon, accent) = _actionStyle(log.action);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          // Action icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          // Details + actor/time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.details.isNotEmpty
                      ? log.details
                      : '${log.actionLabel} ${log.entityLabel}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1D26),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (log.userName.isNotEmpty) log.userName,
                    if (log.employeeId.isNotEmpty) log.employeeId,
                    _formatTime(log.createdAt),
                  ].join('  ·  '),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              log.actionLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    return DateFormat('MMM d, yyyy · h:mm a').format(local);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.history_rounded,
                size: 28, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          Text(
            'No activity found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Logins, logouts and changes will appear here',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
