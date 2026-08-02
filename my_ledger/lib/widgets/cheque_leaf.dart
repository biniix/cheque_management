import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

/// Renders a cheque exactly as it would appear on a physical leaf:
/// bank name + logo, cheque number, date, payee, amount in words and figures,
/// a digital stamp alternative to signature, and status pill.
class ChequeLeaf extends StatelessWidget {
  final String bankName;
  final String bankKey;
  final String chequeNumber;
  final DateTime date;
  final String payee;
  final bool isOrder; // true = Order, false = Bearer
  final double amount;
  final String amountInWords;
  final bool crossed;
  final String accountNumber;
  final String status;

  const ChequeLeaf({
    super.key,
    required this.bankName,
    this.bankKey = '',
    required this.chequeNumber,
    required this.date,
    required this.payee,
    required this.isOrder,
    required this.amount,
    required this.amountInWords,
    required this.crossed,
    required this.accountNumber,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF1A1D26), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank logo + name + Cheque number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bank logo + name
              Row(
                children: [
                  // Bank logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      Constants.getBankLogoPath(bankKey),
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.account_balance_rounded,
                          size: 20,
                          color: const Color(0xFF2563EB).withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bankName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1D26),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Head Office · Addis Ababa',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Cheque number
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Cheque No.',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '#$chequeNumber',
                    style: GoogleFonts.inconsolata(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE8ECF0)),
          ),

          // Date line
          _ChequeLine(
            label: 'Date',
            value: DateFormat('dd / MM / yyyy').format(date),
          ),

          // Payee line — show exactly what the user entered (e.g. "Biniyam Teklu" or "Bearer")
          _ChequeLine(
            label: 'Pay',
            value: payee,
          ),

          // Amount in words
          _ChequeLine(
            label: 'The Sum of',
            value: amountInWords.isNotEmpty ? amountInWords : '___________________________',
          ),

          const SizedBox(height: 6),

          // Amount in figures (right-aligned box)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1A1D26), width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ETB ${NumberFormat('#,##0.00', 'en_US').format(amount)}',
                style: GoogleFonts.inconsolata(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D26),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE8ECF0)),
          const SizedBox(height: 10),

          // Footer: account details + crossing indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Account details
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inconsolata(
                      fontSize: 10,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: 'Account: $accountNumber\n'),
                      if (crossed)
                        const TextSpan(
                          text: 'A/C Payee Only — Not Negotiable\n',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      const TextSpan(text: 'Status: '),
                      TextSpan(
                        text: status,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _statusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Digital stamp (replaces signature)
              if (status == 'Issued')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xFFEEF2FF),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(height: 2),
                      Text(
                        'DIGITAL',
                        style: GoogleFonts.inconsolata(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'STAMP',
                        style: GoogleFonts.inconsolata(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Status pill
          _StatusPill(status: status),
        ],
      ),
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
}

class _ChequeLine extends StatelessWidget {
  final String label;
  final String value;

  const _ChequeLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 3),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFD1D5DB), width: 0.5),
                ),
              ),
              child: Text(
                value,
                style: GoogleFonts.inconsolata(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1D26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
