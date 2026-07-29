import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/app_header.dart';
import '../../widgets/transaction_card.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final accounts = ref.watch(accountsProvider);

    // Build unified transaction list from provider transactions only.
    // Cheques already appear as 'cheque_issued' transactions when issued,
    // so we avoid adding them separately to prevent duplicates.
    final allItems = <Map<String, dynamic>>[];

    for (final tx in transactions) {
      final acc = accounts.where((a) => a.id == tx.accountId).firstOrNull;
      allItems.add({
        'type': tx.type,
        'amount': tx.amount,
        'date': tx.date.toIso8601String(),
        'payee': tx.payee ?? '',
        'description': tx.description ?? tx.type,
        'reference_no': tx.referenceNo ?? '',
        'bank_name': acc?.bankName ?? '',
      });
    }

    // Sort by date (newest first)
    allItems.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['date'] as String? ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    // Apply type filter
    final filtered = _filterType == 'all'
        ? allItems
        : allItems
            .where(
                (t) => (t['type'] as String).toLowerCase() == _filterType)
            .toList();

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(currentRoute: '/transactions'),
          Expanded(
            child: Column(
              children: [
                const AppHeader(title: 'Transactions'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter tabs
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', 'all'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Deposits', 'deposit'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Transfers', 'transfer'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Cheques', 'cheque_issued'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                Icons.arrow_downward_rounded,
                                'Record Deposit',
                                const Color(0xFF059669),
                                () => Navigator.pushNamed(context, '/deposit'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                Icons.arrow_upward_rounded,
                                'Record Transfer',
                                const Color(0xFFDC2626),
                                () => Navigator.pushNamed(context, '/transfer'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Count
                        Text(
                          '${filtered.length} Transaction${filtered.length != 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // List
                        if (filtered.isEmpty)
                          _buildEmptyState(context)
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: const Color(0xFFF0F0F0)
                                      .withValues(alpha: 0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 72),
                              itemBuilder: (context, index) =>
                                  TransactionCard(
                                      transaction: filtered[index]),
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

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0F0F0).withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
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
    final isSelected = _filterType == type;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? Colors.white
              : const Color(0xFF1A1D26),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterType = type),
      selectedColor: const Color(0xFF2563EB),
      checkmarkColor: Colors.white,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color:
                const Color(0xFFF0F0F0).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: Colors.grey.shade300),
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
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
