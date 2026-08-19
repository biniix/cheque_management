import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/cheque.dart';
import '../providers/accounts_provider.dart';
import '../providers/cheque_books_provider.dart';
import '../providers/cheque_designs_provider.dart';
import '../providers/cheques_provider.dart';
import '../providers/transactions_provider.dart';
import '../providers/cheque_templates_provider.dart';
import '../widgets/cheque_leaf.dart';
import '../widgets/cheque_renderer.dart';
import '../models/account.dart';
import '../utils/overdraft_dialog.dart';

class ChequePreviewScreen extends ConsumerWidget {
  final int chequebookId;
  final String payee;
  final double amount;
  final String amountInWords;
  final DateTime date;
  final bool crossed;
  final int? editChequeId;

  const ChequePreviewScreen({
    super.key,
    required this.chequebookId,
    required this.payee,
    required this.amount,
    required this.amountInWords,
    required this.date,
    required this.crossed,
    this.editChequeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(chequeBooksProvider);
    final book = books.where((b) => b.id == chequebookId).firstOrNull;
    final accounts = ref.watch(accountsProvider);
    final account =
        book != null ? accounts.where((a) => a.id == book.accountId).firstOrNull : null;
    final cheques = ref.watch(chequesProvider);
    final chequesForBook = cheques.where((c) => c.chequebookId == chequebookId).toList();
    final usedCount = chequesForBook.length;

    String? nextNumber;
    if (book != null && usedCount < book.size) {
      final nextNum = int.parse(book.startNumber) + usedCount;
      nextNumber = nextNum.toString().padLeft(book.startNumber.length, '0');
    }

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
          'Preview Cheque',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'CHEQUE PREVIEW',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (nextNumber != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Cheque #$nextNumber',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cheque Preview',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D26),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This is exactly how the cheque will appear on the leaf.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Cheque leaf (full width) — template-driven when available.
            if (templateEntry != null)
              ChequeRenderer(
                template: templateEntry.template,
                fields: templateEntry.fields,
                bankKey: account?.bankKey ?? '',
                bankName: account?.bankName ?? '',
                branch: account?.accountName ?? '',
                date: date,
                payee: payee,
                amount: amount,
                amountInWords: amountInWords,
                crossed: crossed,
                status: 'Issued',
              )
            else
              ChequeLeaf(
                bankName: account?.bankName ?? 'Bank Name',
                bankKey: account?.bankKey ?? '',
                design: designForBank(
                    ref.watch(chequeDesignsProvider), account?.bankKey ?? ''),
                chequeNumber: nextNumber ?? '----',
                date: date,
                payee: payee,
                amount: amount,
                amountInWords: amountInWords,
                crossed: crossed,
                accountNumber: account?.accountNumber ?? '----',
                status: 'Issued',
              ),
            const SizedBox(height: 24),

            // Actions below
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Actions',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D26),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          crossed ? 'CROSSED' : 'OPEN',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: account != null && book != null
                              ? () => _submitCheque(context, ref, book.id,
                                  nextNumber ?? '', account)
                              : null,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(
                            'Issue Cheque',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(
                            'Back to Edit',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A1D26),
                            side: const BorderSide(color: Color(0xFFE8ECF0)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _detailRow(
                    'Crossing',
                    crossed
                        ? 'Crossed — not payable over the counter'
                        : 'Open — payable over the counter',
                  ),
                  const SizedBox(height: 6),
                  _detailRow(
                    'Post-dated',
                    date.isAfter(DateTime.now())
                        ? 'Yes — dated ${DateFormat('MMM d, yyyy').format(date)}'
                        : 'No — dated today or earlier',
                  ),
                  if (account != null) ...[
                    const SizedBox(height: 6),
                    _detailRow(
                      'Linked balance',
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

  Widget _detailRow(String label, String value, {bool isMono = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitCheque(
    BuildContext context,
    WidgetRef ref,
    int chequebookId,
    String nextNumber,
    Account account,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final chequeNotifier = ref.read(chequesProvider.notifier);
    final txNotifier = ref.read(transactionsProvider.notifier);

    int chequeId;
    if (editChequeId != null) {
      // Edit mode: Skip transaction and balance deduction
      // Preserve original transaction ID
      final originalCheque = ref.read(chequesProvider).where((c) => c.id == editChequeId).firstOrNull;
      await chequeNotifier.updateCheque(
        Cheque(
          id: editChequeId!,
          chequebookId: chequebookId,
          transactionId: originalCheque?.transactionId,
          chequeNumber: nextNumber,
          date: date,
          payee: payee,
          amount: amount,
          amountInWords: amountInWords,
          bearerOrOrder: 'order',
          crossed: crossed,
          status: 'Issued',
        ),
      );
      chequeId = editChequeId!;
    } else {
      // Warn (but never block) when balance is insufficient
      if (!date.isAfter(DateTime.now()) && account.balance < amount) {
        await showOverdraftWarningDialog(
          context,
          accountName: account.accountName,
          bankName: account.bankName,
          balance: account.balance,
          chequeAmount: amount,
        );
      }

      // Issue new cheque — the API automatically creates the transaction and deducts balance
      final result = await chequeNotifier.addCheque(
        Cheque(
          id: 0,
          chequebookId: chequebookId,
          chequeNumber: nextNumber,
          date: date,
          payee: payee,
          amount: amount,
          amountInWords: amountInWords,
          bearerOrOrder: 'order',
          crossed: crossed,
          status: 'Issued',
        ),
      );
      chequeId = result.chequeId;

      // Save the transaction that the API created into local state
      if (result.transactionData != null) {
        await txNotifier.addTransactionFromApi(result.transactionData!);
      }

      // Update local account balance to match what the API calculated
      if (result.newBalance != null) {
        await ref.read(accountsProvider.notifier).updateBalance(
              account.id,
              result.newBalance!,
            );
      }
    }

    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Cheque #$nextNumber issued successfully'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
    // Navigate to cheque detail screen using the returned ID
    navigator.pushReplacementNamed('/cheque-detail', arguments: chequeId);
  }

}
