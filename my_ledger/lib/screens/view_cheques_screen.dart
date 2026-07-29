import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../providers/cheque_books_provider.dart';
import '../providers/cheques_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../constants.dart';

class ViewChequesScreen extends ConsumerStatefulWidget {
  const ViewChequesScreen({super.key});

  @override
  ConsumerState<ViewChequesScreen> createState() => _ViewChequesScreenState();
}

class _ViewChequesScreenState extends ConsumerState<ViewChequesScreen> {
  String _statusFilter = 'all';
  int? _accountFilter;

  // Quick status options
  static const _statusOptions = [
    ('All', 'all', Icons.all_inclusive_rounded),
    ('Issued', 'Issued', Icons.schedule_rounded),
    ('Cleared', 'Cleared', Icons.check_circle_rounded),
    ('Stale', 'Stale', Icons.warning_rounded),
    ('Void', 'Void', Icons.cancel_rounded),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(chequesProvider.notifier).load();
      await ref.read(chequeBooksProvider.notifier).load();
      await ref.read(accountsProvider.notifier).load();
      ref.read(chequesProvider.notifier).checkStaleCheques();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cheques = ref.watch(chequesProvider);
    final books = ref.watch(chequeBooksProvider);
    final accounts = ref.watch(accountsProvider);
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('MMM d, yyyy');

    // Apply filters
    var filtered = cheques;
    if (_statusFilter != 'all') {
      filtered = filtered.where((c) => c.status == _statusFilter).toList();
    }
    if (_accountFilter != null) {
      final bookIds = books
          .where((b) => b.accountId == _accountFilter)
          .map((b) => b.id)
          .toList();
      filtered =
          filtered.where((c) => bookIds.contains(c.chequebookId)).toList();
    }

    // Counts per status
    final issuedCount =
        cheques.where((c) => c.status == 'Issued').length;
    final clearedCount =
        cheques.where((c) => c.status == 'Cleared').length;
    final staleCount = cheques.where((c) => c.status == 'Stale').length;
    final voidCount = cheques.where((c) => c.status == 'Void').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/view-cheques'),
          Expanded(
            child: Column(
              children: [
                const AppHeader(title: 'Cheques'),
                Expanded(
                  child: Column(
                    children: [
                      // ── Filters Section ──
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status filter chips (horizontal row)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _statusOptions.map((opt) {
                                  final label = opt.$1;
                                  final type = opt.$2;
                                  final icon = opt.$3;
                                  final isSelected = _statusFilter == type;

                                  // Count for this filter
                                  int count;
                                  switch (type) {
                                    case 'Issued':
                                      count = issuedCount;
                                      break;
                                    case 'Cleared':
                                      count = clearedCount;
                                      break;
                                    case 'Stale':
                                      count = staleCount;
                                      break;
                                    case 'Void':
                                      count = voidCount;
                                      break;
                                    default:
                                      count = cheques.length;
                                  }

                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(right: 8),
                                    child: _buildStatusChip(
                                      label,
                                      type,
                                      icon,
                                      count,
                                      isSelected,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Account filter section
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // "All Accounts" section chip
                                  _buildAccountSectionChip(
                                    'All Accounts',
                                    null,
                                    Icons.account_balance_rounded,
                                    isSelected: _accountFilter == null,
                                    count: cheques.length,
                                  ),
                                  const SizedBox(width: 8),
                                  // Per-bank chips
                                  ...accounts.map((a) {
                                    final bookIdsForAcc = books
                                        .where((b) => b.accountId == a.id)
                                        .map((b) => b.id)
                                        .toList();
                                    final accChequeCount = cheques
                                        .where((c) =>
                                            bookIdsForAcc
                                                .contains(c.chequebookId))
                                        .length;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          right: 8),
                                      child: _buildAccountSectionChip(
                                        a.bankName,
                                        a.id,
                                        Icons.account_balance_rounded,
                                        isSelected:
                                            _accountFilter == a.id,
                                        count: accChequeCount,
                                        bankKey: a.bankKey,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Stats Bar ──
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                        child: Row(
                          children: [
                            Text(
                              '${filtered.length} cheque${filtered.length != 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const Spacer(),
                            // Quick action buttons in a row
                            SizedBox(
                              height: 36,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/write-cheque'),
                                icon: const Icon(Icons.add_rounded,
                                    size: 16),
                                label: Text(
                                  'Write Cheque',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Cheque List ──
                      Expanded(
                        child: filtered.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    24, 8, 24, 24),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final cheque = filtered[index];
                                  final book = books
                                      .where((b) =>
                                          b.id == cheque.chequebookId)
                                      .firstOrNull;
                                  final acc = book != null
                                      ? accounts
                                          .where((a) =>
                                              a.id == book.accountId)
                                          .firstOrNull
                                      : null;

                                  return _buildChequeCard(
                                    cheque,
                                    acc,
                                    book,
                                    currencyFormat,
                                    dateFormat,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Status filter chip with count badge
  Widget _buildStatusChip(
    String label,
    String type,
    IconData icon,
    int count,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _statusFilter = type),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFF0F0F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF4A4E5C),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Account section chip (either "All Accounts" or per-bank)
  Widget _buildAccountSectionChip(
    String label,
    int? accountId,
    IconData icon, {
    bool isSelected = false,
    int count = 0,
    String? bankKey,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _accountFilter = accountId),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF5B5BD6).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5B5BD6)
                  : const Color(0xFFF0F0F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bank logo or icon
              if (bankKey != null && bankKey.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    Constants.getBankLogoPath(bankKey),
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFF5B5BD6)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF5B5BD6)
                      : const Color(0xFF6B7280),
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF5B5BD6)
                      : const Color(0xFF4A4E5C),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF5B5BD6).withValues(alpha: 0.15)
                        : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF5B5BD6)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Cheque card with sleek design
  Widget _buildChequeCard(
    dynamic cheque,
    dynamic acc,
    dynamic book,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/cheque-detail',
        arguments: cheque.id,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Cheque # + Status + Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Cheque #${cheque.chequeNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D26),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(cheque.status),
                    ],
                  ),
                ),
                Text(
                  'ETB ${currencyFormat.format(cheque.amount)}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Middle: Payee + Date
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  cheque.payee.isNotEmpty ? cheque.payee : 'Bearer',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  dateFormat.format(cheque.date),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

            // Bank info
            if (acc != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      Constants.getBankLogoPath(acc.bankKey),
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    acc.bankName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  if (book != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• #${book.startNumber}-${book.endNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Action buttons row for Issued cheques
            if (cheque.status == 'Issued') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildQuickAction(
                    Icons.check_circle_rounded,
                    'Cleared',
                    const Color(0xFF10B981),
                    () => _updateStatus(cheque.id, 'Cleared'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    Icons.cancel_rounded,
                    'Void',
                    const Color(0xFFEF4444),
                    () => _updateStatus(cheque.id, 'Void'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Small horizontal action button
  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 36,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No cheques found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _accountFilter != null
                ? 'No cheques match this account and status'
                : 'Get started by writing your first cheque',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/write-cheque'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Write a Cheque',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'Issued':
        bgColor = const Color(0xFFEEF2FF);
        textColor = const Color(0xFF2563EB);
        break;
      case 'Cleared':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
      case 'Stale':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case 'Void':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Future<void> _updateStatus(int chequeId, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    final chequesNotifier = ref.read(chequesProvider.notifier);
    final accountsNotifier = ref.read(accountsProvider.notifier);
    final books = ref.read(chequeBooksProvider);
    final cheques = ref.read(chequesProvider);
    final cheque = cheques.where((c) => c.id == chequeId).firstOrNull;

    // Find linked account for refund
    Account? account;
    if (cheque != null) {
      final book = books.where((b) => b.id == cheque.chequebookId).firstOrNull;
      if (book != null) {
        final accounts = ref.read(accountsProvider);
        account = accounts.where((a) => a.id == book.accountId).firstOrNull;
      }
    }

    final isVoid = newStatus == 'Void';
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final refundAmount = cheque?.amount ?? 0;

    String dialogContent;
    if (isVoid) {
      dialogContent = account != null
          ? 'This will void the cheque and refund ETB ${currencyFormat.format(refundAmount)} back to ${account.bankName} - ${account.accountName}.'
          : 'This will mark the cheque as void. It cannot be used.';
    } else {
      dialogContent = 'Confirm that this cheque has been cleared by the bank.';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          isVoid ? 'Void Cheque?' : 'Mark as Cleared?',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          dialogContent,
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isVoid
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isVoid ? 'Void Cheque' : 'Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await chequesNotifier.updateStatus(chequeId, newStatus);

      // Refund the amount to the linked account when voiding
      if (isVoid && account != null && refundAmount > 0) {
        await accountsNotifier.updateBalance(
          account.id,
          account.balance + refundAmount,
        );
      }

      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isVoid
                  ? 'Cheque voided. ETB ${currencyFormat.format(refundAmount)} refunded'
                  : 'Cheque marked as $newStatus',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
