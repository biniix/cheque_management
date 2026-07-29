import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final type = (transaction['type'] as String?)?.toLowerCase() ?? 'transfer';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final isCredit = amount > 0;
    final dateStr = transaction['date'] as String? ?? '';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    final payee = transaction['payee'] as String? ?? '';
    final description = transaction['description'] as String? ?? '';
    final bankName = transaction['bank_name'] as String? ?? '';
    final referenceNo = transaction['reference_no'] as String? ?? '';

    // Determine icon and colors
    IconData icon;
    Color iconColor;
    Color bgColor;
    String label;

    switch (type) {
      case 'deposit':
        icon = Icons.arrow_downward_rounded;
        iconColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        label = 'Deposit';
        break;
      case 'cheque_issued':
        icon = Icons.check_circle_outline_rounded;
        iconColor = const Color(0xFF6366F1);
        bgColor = const Color(0xFFEEF2FF);
        label = 'Cheque';
        break;
      case 'cheque':
        icon = Icons.check_circle_outline_rounded;
        iconColor = const Color(0xFF6366F1);
        bgColor = const Color(0xFFEEF2FF);
        label = 'Cheque';
        break;
      default:
        icon = Icons.arrow_upward_rounded;
        iconColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        label = isCredit ? 'Credit' : 'Transfer';
    }

    // Determine title: show bank name first, then payee/description
    final title = bankName.isNotEmpty
        ? (payee.isNotEmpty
            ? '$bankName — $payee'
            : description.isNotEmpty
                ? '$bankName — $description'
                : bankName)
        : (payee.isNotEmpty
            ? payee
            : description.isNotEmpty
                ? description
                : label);

    // Subtitle shows the type label
    final subtitle = label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D26),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      if (referenceNo.isNotEmpty) ...[               
                        const SizedBox(width: 8),
                        Text(
                          'Ref: $referenceNo',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    dateFormat.format(date),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}ETB ${currencyFormat.format(amount.abs())}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
