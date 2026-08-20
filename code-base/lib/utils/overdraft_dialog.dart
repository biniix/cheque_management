import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

Future<bool> showOverdraftWarningDialog(
  BuildContext context, {
  required String accountName,
  required String bankName,
  required double balance,
  required double chequeAmount,
}) async {
  final currencyFormat = NumberFormat('#,##0.00', 'en_US');
  final overdraft = chequeAmount - balance;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Insufficient Balance',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D26),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "The account $bankName - $accountName doesn't have enough funds to cover this cheque.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Column(
                children: [
                  _overdraftRow('Available balance',
                      'ETB ${currencyFormat.format(balance)}',
                      const Color(0xFF1A1D26)),
                  const SizedBox(height: 8),
                  _overdraftRow('Cheque amount',
                      'ETB ${currencyFormat.format(chequeAmount)}',
                      const Color(0xFFEF4444)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _overdraftRow(
                    'Overdraft',
                    'ETB ${currencyFormat.format(overdraft)}',
                    const Color(0xFFEF4444),
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can still issue the cheque, but the account will go into overdraft.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(
                'OK, I Understand',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  return result ?? true;
}

Widget _overdraftRow(String label, String value, Color color,
    {bool bold = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF6B7280),
        ),
      ),
      Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}
