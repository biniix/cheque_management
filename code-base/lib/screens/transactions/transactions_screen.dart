import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../constants.dart';
import '../../models/transaction.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/app_header.dart';
import '../../widgets/audit_log_sheet.dart';
import '../../design/shared_widgets.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _selectedType = 'all';

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final accounts = ref.watch(accountsProvider);

    final items = <Map<String, dynamic>>[];
    for (final tx in transactions) {
      final acc = accounts.where((a) => a.id == tx.accountId).firstOrNull;
      items.add({
        'id': tx.id,
        'type': tx.type,
        'amount': tx.amount,
        'date': tx.date.toIso8601String(),
        'payee': tx.payee ?? '',
        'description': tx.description ?? tx.type,
        'reference_no': tx.referenceNo ?? '',
        'bank_name': acc?.bankName ?? '',
        'bank_key': acc?.bankKey ?? '',
        'account_name': acc?.accountName ?? '',
        'account_id': acc?.id,
      });
    }

    items.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['date'] as String? ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/transactions'),
          Expanded(
            child: Column(
              children: [

                AppHeader(
                  title: 'Transactions',
                  actions: [
                    _buildActionChip(
                      icon: Icons.summarize_rounded,
                      label: 'Summary',
                      onTap: () => _showSummaryDialog(context, currencyFormat),
                    ),
                    const SizedBox(width: 8),
                    _buildActionChip(
                      icon: Icons.description_outlined,
                      label: 'Statements',
                      onTap: () => _showStatementsDialog(context),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF0F0F0)),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('All', 'all'),
                                _buildFilterChip('Deposits', 'deposit'),
                                _buildFilterChip('Transfers', 'transfer'),
                                _buildFilterChip('Cheques', 'cheque'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Expanded(
                          child: _buildTypeList(context, items, _selectedType, currencyFormat),
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

  Widget _buildActionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedType = type),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF0F0F0),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeList(BuildContext context, List<Map<String, dynamic>> items, String type, NumberFormat currencyFormat) {
    final List<Map<String, dynamic>> filtered;
    if (type == 'all') {
      filtered = items;
    } else if (type == 'cheque') {
      filtered = items.where((t) => (t['type'] as String).toLowerCase().startsWith('cheque')).toList();
    } else {
      filtered = items.where((t) => (t['type'] as String).toLowerCase() == type).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${filtered.length} Transaction${filtered.length != 1 ? 's' : ''}',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildCompactRow(context, filtered[index], currencyFormat),
                ),
        ),
      ],
    );
  }

  Widget _buildCompactRow(BuildContext context, Map<String, dynamic> item, NumberFormat currencyFormat) {
    final type = (item['type'] as String).toLowerCase();
    final amount = (item['amount'] as num).toDouble();
    final isCredit = amount > 0;
    final bankName = item['bank_name'] as String? ?? '';
    final accountName = item['account_name'] as String? ?? '';
    final txnId = item['id'] as int? ?? 0;

    final Color accent = isCredit
        ? const Color(0xFF10B981)
        : type == 'cheque_issued'
            ? const Color(0xFF6366F1)
            : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              Constants.getBankLogoPath(item['bank_key'] as String? ?? ''),
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 16,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    bankName.isNotEmpty ? bankName : 'Unknown Bank',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                ),
                if (accountName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1D5DB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        accountName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          Text(
            '${isCredit ? '+' : '-'}ETB ${currencyFormat.format(amount.abs())}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),

          if (ref.watch(authProvider).isAdmin)
            IconButton(
              tooltip: 'Who did this',
              icon: const Icon(Icons.info_outline_rounded,
                  size: 16, color: Color(0xFF2563EB)),
              onPressed: () => showAuditLogDialog(
                context,
                entity: type == 'transfer' ? 'transfer' : 'transaction',
                entityId: txnId,
                title: _typeLabel(type),
                entityIcon: Icons.receipt_long_rounded,
              ),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),

          TextButton.icon(
            onPressed: () => _showDetailDialog(context, item, currencyFormat),
            icon: const Icon(Icons.chevron_right_rounded, size: 16),
            label: const Text('View Details'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 32, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Record a deposit or transfer to get started',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> item, NumberFormat currencyFormat) {
    final type = (item['type'] as String).toLowerCase();
    final amount = (item['amount'] as num).toDouble();
    final isCredit = amount > 0;
    final date = DateTime.tryParse(item['date'] as String? ?? '') ?? DateTime.now();
    final txnId = item['id'] as int? ?? 0;
    final bankName = item['bank_name'] as String? ?? 'Unknown Bank';
    final accountName = item['account_name'] as String? ?? '';

    final Color accent = isCredit
        ? const Color(0xFF10B981)
        : type == 'cheque_issued'
            ? const Color(0xFF6366F1)
            : const Color(0xFFEF4444);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _typeLabel(type),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1D26),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bankName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7280)),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'AMOUNT',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: accent.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${isCredit ? '+' : '-'}ETB ${currencyFormat.format(amount.abs())}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(date),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Account', accountName.isNotEmpty ? '$bankName · $accountName' : bankName),
                      _detailRow('Method', Constants.paymentMethodLabel(item['method'] as String? ?? '')),
                      _detailRow('Description', item['description'] as String? ?? '—'),
                      if ((item['payee'] as String? ?? '').isNotEmpty)
                        _detailRow('Payee', item['payee'] as String),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (type != 'cheque_issued')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _showEditSheet(context, item, currencyFormat);
                          },
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _confirmDelete(context, txnId);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Cheque transactions are managed from the Cheques section.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1D26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, Map<String, dynamic> item, NumberFormat currencyFormat) {
    final txnId = item['id'] as int? ?? 0;
    final type = (item['type'] as String).toLowerCase();
    final amountCtrl = TextEditingController(
        text: (item['amount'] as num).abs().toStringAsFixed(2));
    final descCtrl = TextEditingController(text: item['description'] as String? ?? '');
    DateTime date = DateTime.tryParse(item['date'] as String? ?? '') ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Transaction',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sheetField('Amount (ETB)', amountCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  _sheetField('Description', descCtrl),
                  const SizedBox(height: 14),
                  Text(
                    'Date',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                        text: DateFormat('MMM d, yyyy').format(date)),
                    onTap: () async {
                      final picked = await AppWidgets.pickDate(
                        context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setSheetState(() => date = picked);
                    },
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.calendar_today_rounded,
                          size: 16, color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newAmount = double.tryParse(amountCtrl.text);
                        if (newAmount == null || newAmount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a valid amount'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }
                        final signed =
                            (type == 'transfer' || type == 'cheque_issued')
                                ? -newAmount
                                : newAmount;

                        await ref
                            .read(transactionsProvider.notifier)
                            .updateTransaction(
                              Transaction(
                                id: txnId,
                                accountId: item['account_id'] as int? ?? 0,
                                type: type,
                                method: item['method'] as String? ?? 'cash',
                                amount: signed,
                                date: date,
                                payee: item['payee'] as String?,
                                description: descCtrl.text.trim(),
                                referenceNo: item['reference_no'] as String?,
                              ),
                            );
                        await ref.read(accountsProvider.notifier).syncFromApi();
                        if (!context.mounted) return;
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaction updated'),
                            backgroundColor: Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.all(16),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _sheetField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, int txnId) async {
    final confirmed = await AppWidgets.confirmDialog(
      context,
      title: 'Delete transaction?',
      message:
          'This will remove the transaction and adjust the account balance.',
      confirmLabel: 'Delete',
      confirmColor: const Color(0xFFDC2626),
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed && context.mounted) {
      await ref.read(transactionsProvider.notifier).deleteTransaction(txnId);
      await ref.read(accountsProvider.notifier).syncFromApi();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showSummaryDialog(BuildContext context, NumberFormat currencyFormat) {
    final transactions = ref.read(transactionsProvider);
    double deposits = 0, transfers = 0, cheques = 0;
    int depositCount = 0, transferCount = 0, chequeCount = 0;

    for (final tx in transactions) {
      if (tx.type == 'deposit') {
        deposits += tx.amount;
        depositCount++;
      } else if (tx.type == 'transfer') {
        transfers += tx.amount;
        transferCount++;
      } else if (tx.type.startsWith('cheque')) {
        cheques += tx.amount;
        chequeCount++;
      }
    }

    final net = deposits + transfers + cheques;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Summary',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                _summaryRow('Deposits', depositCount, deposits, const Color(0xFF10B981), currencyFormat),
                const SizedBox(height: 12),
                _summaryRow('Transfers', transferCount, transfers, const Color(0xFFEF4444), currencyFormat),
                const SizedBox(height: 12),
                _summaryRow('Cheques', chequeCount, cheques, const Color(0xFF6366F1), currencyFormat),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net (in − out)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${net >= 0 ? '+' : '-'}ETB ${currencyFormat.format(net.abs())}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: net >= 0 ? const Color(0xFF2563EB) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, int count, double total, Color color, NumberFormat currencyFormat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(
          '$count • ${total >= 0 ? '+' : '-'}ETB ${currencyFormat.format(total.abs())}',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showStatementsDialog(BuildContext context) {
    final accounts = ref.read(accountsProvider);
    final selectedAccountIds = <int>{};
    DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime to = DateTime.now();

    if (accounts.isNotEmpty) {
      selectedAccountIds.addAll(accounts.map((a) => a.id));
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statements',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Select Accounts', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: accounts.map((a) {
                      final isSelected = selectedAccountIds.contains(a.id);
                      return FilterChip(
                        label: Text(a.bankName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedAccountIds.add(a.id);
                            } else {
                              selectedAccountIds.remove(a.id);
                            }
                          });
                        },
                        selectedColor: const Color(0xFF2563EB),
                        checkmarkColor: Colors.white,
                        labelStyle: GoogleFonts.inter(
                          color: isSelected ? Colors.white : const Color(0xFF6B7280),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _dateField('From', from, (d) => setDialogState(() => from = d)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dateField('To', to, (d) => setDialogState(() => to = d)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _generateAndPrintStatement(from, to, selectedAccountIds);
                          },
                          icon: const Icon(Icons.print_rounded),
                          label: const Text('Print'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _generateAndDownloadStatement(from, to, selectedAccountIds);
                          },
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime value, ValueChanged<DateTime> onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(text: DateFormat('MMM d, yyyy').format(value)),
          onTap: () async {
            final picked = await AppWidgets.pickDate(
              context,
              initialDate: value,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) onPicked(picked);
          },
          decoration: const InputDecoration(
            suffixIcon: Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<Uint8List> _buildStatementPdf(DateTime from, DateTime to, Set<int> accountIds) async {
    final transactions = ref.read(transactionsProvider);
    final accounts = ref.read(accountsProvider);

    final filtered = transactions.where((t) {
      if (!accountIds.contains(t.accountId)) return false;
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      return !day.isBefore(from) && !day.isAfter(to);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final pdf = pw.Document();
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final selectedAccounts =
        accounts.where((a) => accountIds.contains(a.id)).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Text('Bank Statement', style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
            pw.SizedBox(height: 8),
            pw.Text('Period: ${DateFormat('MMM d, yyyy').format(from)} — ${DateFormat('MMM d, yyyy').format(to)}'),
            pw.Text('Banks: ${selectedAccounts.map((a) => a.bankName).join(', ')}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
            pw.SizedBox(height: 24),

            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.Text('Date', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 3, child: pw.Text('Bank', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 4, child: pw.Text('Description', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 3, child: pw.Text('Amount', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            for (final tx in filtered)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text(DateFormat('MMM d, yyyy').format(tx.date))),
                    pw.Expanded(flex: 3, child: pw.Text(accounts.where((a) => a.id == tx.accountId).firstOrNull?.bankName ?? '')),
                    pw.Expanded(flex: 4, child: pw.Text(tx.description ?? tx.type)),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        '${tx.amount > 0 ? '+' : '-'}${currencyFormat.format(tx.amount.abs())}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          color: tx.amount > 0 ? PdfColors.green700 : PdfColors.red700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  String _statementFileName(DateTime from, DateTime to) =>
      'Bank_Statement_${DateFormat('yyyyMMdd').format(from)}_${DateFormat('yyyyMMdd').format(to)}';

  Future<void> _generateAndPrintStatement(DateTime from, DateTime to, Set<int> accountIds) async {
    try {
      final pdfData = await _buildStatementPdf(from, to, accountIds);
      await Printing.layoutPdf(
        onLayout: (_) => pdfData,
        name: _statementFileName(from, to),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  Future<void> _generateAndDownloadStatement(DateTime from, DateTime to, Set<int> accountIds) async {
    try {
      final pdfData = await _buildStatementPdf(from, to, accountIds);

      await Printing.sharePdf(
        bytes: pdfData,
        filename: '${_statementFileName(from, to)}.pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statement PDF downloaded.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'deposit': return 'Deposit';
      case 'transfer': return 'Transfer';
      case 'cheque_issued': return 'Cheque Issued';
      case 'cheque': return 'Cheque';
      default: return 'Transaction';
    }
  }
}
