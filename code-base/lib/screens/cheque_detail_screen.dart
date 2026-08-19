import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/accounts_provider.dart';
import '../providers/cheque_books_provider.dart';
import '../providers/cheque_designs_provider.dart';
import '../providers/cheques_provider.dart';
import '../providers/transactions_provider.dart';
import '../providers/cheque_templates_provider.dart';
import '../widgets/cheque_leaf.dart';
import '../widgets/cheque_renderer.dart';
import 'write_cheque_screen.dart';

class ChequeDetailScreen extends ConsumerStatefulWidget {
  final int chequeId;

  const ChequeDetailScreen({super.key, required this.chequeId});

  @override
  ConsumerState<ChequeDetailScreen> createState() => _ChequeDetailScreenState();
}

class _ChequeDetailScreenState extends ConsumerState<ChequeDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chequeDesignsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final cheques = ref.watch(chequesProvider);
    final cheque = cheques.where((c) => c.id == widget.chequeId).firstOrNull;
    final books = ref.watch(chequeBooksProvider);
    final accounts = ref.watch(accountsProvider);

    if (cheque == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            'Cheque Detail',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D26),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Cheque not found',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D26),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final book = books.where((b) => b.id == cheque.chequebookId).firstOrNull;
    final account = book != null
        ? accounts.where((a) => a.id == book.accountId).firstOrNull
        : null;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    // Use the database-driven template for this bank when one exists — the
    // exact template the book was created with, else the bank's template.
    final allTemplates = ref.watch(chequeTemplatesProvider);
    final templateEntry =
        (book != null && book.templateId != null)
            ? templateById(allTemplates, book.templateId)
            : (account != null
                ? templateForBank(allTemplates, account.bankKey)
                : null);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Cheque #${cheque.chequeNumber}',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1D26),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1D26)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Print
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Print',
            onPressed: () => Navigator.pushNamed(
              context,
              '/print-cheque',
              arguments: cheque.id,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusBgColor(cheque.status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(cheque.status),
                        size: 12,
                        color: _statusColor(cheque.status),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cheque.status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(cheque.status),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (account != null)
                  Text(
                    '${account.bankName} • ${account.accountName}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cheque #${cheque.chequeNumber}',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D26),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ETB ${currencyFormat.format(cheque.amount)} • ${DateFormat('MMM d, yyyy').format(cheque.date)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Cheque design — template-driven when available.
            if (templateEntry != null)
              ChequeRenderer(
                template: templateEntry.template,
                fields: templateEntry.fields,
                bankKey: account?.bankKey ?? '',
                bankName: account?.bankName ?? '',
                branch: account?.accountName ?? '',
                date: cheque.date,
                payee: cheque.payee,
                amount: cheque.amount,
                amountInWords: cheque.amountInWords,
                crossed: cheque.crossed,
                status: cheque.status,
              )
            else
              ChequeLeaf(
                bankName: account?.bankName ?? 'Bank Name',
                bankKey: account?.bankKey ?? '',
                design: designForBank(
                    ref.watch(chequeDesignsProvider), account?.bankKey ?? ''),
                chequeNumber: cheque.chequeNumber,
                date: cheque.date,
                payee: cheque.payee,
                amount: cheque.amount,
                amountInWords: cheque.amountInWords,
                crossed: cheque.crossed,
                accountNumber: account?.accountNumber ?? '----',
                status: cheque.status,
              ),

            const SizedBox(height: 24),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Print
                      Expanded(
                        child: _actionButton(
                          icon: Icons.print_rounded,
                          label: 'Print',
                          color: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFEEF2FF),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/print-cheque',
                            arguments: cheque.id,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Edit (only if Issued)
                      Expanded(
                        child: _actionButton(
                          icon: Icons.edit_rounded,
                          label: 'Edit',
                          color: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFFEF3C7),
                          onTap: cheque.status == 'Issued'
                              ? () =>
                                  showWriteChequeDialog(context, editChequeId: cheque.id)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status actions
                  if (cheque.status == 'Issued') ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            icon: Icons.check_circle_rounded,
                            label: 'Mark Cleared',
                            color: const Color(0xFF10B981),
                            bgColor: const Color(0xFFD1FAE5),
                            onTap: () => _updateStatus(cheque.id, 'Cleared'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            icon: Icons.cancel_rounded,
                            label: 'Void',
                            color: const Color(0xFFEF4444),
                            bgColor: const Color(0xFFFEE2E2),
                            onTap: () => _updateStatus(cheque.id, 'Void'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Details section
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _detailRow('Payee', cheque.payee.isEmpty ? '—' : cheque.payee),
                  const SizedBox(height: 6),
                  _detailRow('Amount', 'ETB ${currencyFormat.format(cheque.amount)}', isMono: true),
                  const SizedBox(height: 6),
                  _detailRow('Date', DateFormat('MMM d, yyyy').format(cheque.date)),
                  const SizedBox(height: 6),
                  _detailRow('Crossing', cheque.crossed ? 'Crossed' : 'Open'),
                  if (account != null) ...[
                    const SizedBox(height: 6),
                    _detailRow('Account', '${account.bankName} ${account.accountNumber}'),
                    const SizedBox(height: 6),
                    _detailRow(
                      'Balance at issue',
                      'ETB ${currencyFormat.format(account.balance)}',
                      isMono: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? bgColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null ? color.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: onTap != null ? color : Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: onTap != null ? color : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isMono = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Issued':
        return const Color(0xFF2563EB);
      case 'Cleared':
        return const Color(0xFF10B981);
      case 'Stale':
        return const Color(0xFFF59E0B);
      case 'Void':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'Issued':
        return const Color(0xFFEEF2FF);
      case 'Cleared':
        return const Color(0xFFD1FAE5);
      case 'Stale':
        return const Color(0xFFFEF3C7);
      case 'Void':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Issued':
        return Icons.schedule_rounded;
      case 'Cleared':
        return Icons.check_circle_rounded;
      case 'Stale':
        return Icons.warning_rounded;
      case 'Void':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
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
          ? 'This will mark the cheque as void and refund ETB ${currencyFormat.format(refundAmount)} back to ${account.bankName} - ${account.accountName}.'
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
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
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
              style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isVoid
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(isVoid ? 'Void Cheque' : 'Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await chequesNotifier.updateStatus(chequeId, newStatus);

      // When voiding, create a refund transaction record (API already refunds the balance)
      if (isVoid && account != null && refundAmount > 0) {
        // Update local balance immediately to match the API's refund
        await accountsNotifier.updateBalance(
          account.id,
          account.balance + refundAmount,
        );

        // Create a refund transaction record
        final txNotifier = ref.read(transactionsProvider.notifier);
        await txNotifier.addTransaction(
          Transaction(
            id: 0,
            accountId: account.id,
            type: 'refund',
            amount: refundAmount,
            date: DateTime.now(),
            description: 'Refund for voided cheque #${cheque?.chequeNumber ?? ''}',
          ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        );
      }
    }
  }
}
