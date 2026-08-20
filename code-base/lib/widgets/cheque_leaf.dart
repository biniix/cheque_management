import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/cheque_design.dart';

class ChequeLeaf extends StatelessWidget {
  final String bankName;
  final String bankKey;
  final String branch;
  final String chequeNumber;
  final DateTime date;
  final String payee;
  final double amount;
  final String amountInWords;
  final bool crossed;
  final String accountNumber;
  final String status;
  final ChequeDesign? design;

  const ChequeLeaf({
    super.key,
    required this.bankName,
    this.bankKey = '',
    this.branch = '',
    required this.chequeNumber,
    required this.date,
    required this.payee,
    required this.amount,
    required this.amountInWords,
    required this.crossed,
    required this.accountNumber,
    required this.status,
    this.design,
  });

  @override
  Widget build(BuildContext context) {

    final d = design;
    final logoPosition = d?.logoPosition ?? 'left';
    final logoSize = d?.logoSize ?? 36;
    final primary = d?.primaryColor ?? const Color(0xFF1A1D26);
    final accent = d?.accentColor ?? const Color(0xFF2563EB);
    final muted = d?.mutedColor ?? const Color(0xFF9CA3AF);
    final border = d?.borderColor ?? const Color(0xFF1A1D26);
    final showHeadOffice = d?.showHeadOffice ?? true;
    final chequeNoPosition = d?.chequeNumberPosition ?? 'right';
    final amountAlign = d?.amountBoxAlign ?? Alignment.centerRight;
    final showMicr = d?.showMicr ?? false;
    final showStatusPill = d?.showStatusPill ?? true;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

          if (logoPosition == 'center')
            _centeredHeader(
              logoSize: logoSize,
              primary: primary,
              muted: muted,
              accent: accent,
              showHeadOffice: showHeadOffice,
              chequeNumber: chequeNumber,
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (logoPosition != 'right')
                  _logoBlock(
                    logoSize: logoSize,
                    primary: primary,
                    muted: muted,
                    accent: accent,
                    showHeadOffice: showHeadOffice,
                  ),
                if (chequeNoPosition != 'below')
                  _chequeNoBlock(
                    accent: accent,
                    muted: muted,
                    chequeNumber: chequeNumber,
                  ),
                if (logoPosition == 'right')
                  _logoBlock(
                    logoSize: logoSize,
                    primary: primary,
                    muted: muted,
                    accent: accent,
                    showHeadOffice: showHeadOffice,
                  ),
              ],
            ),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _dateBlock(accent: accent, muted: muted, date: date),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE8ECF0)),
          ),

          _ChequeLine(
            label: 'Pay',
            value: payee,
            primary: primary,
            muted: muted,
          ),

          _ChequeLine(
            label: 'The Sum of',
            value: amountInWords.isNotEmpty
                ? amountInWords
                : '___________________________',
            primary: primary,
            muted: muted,
          ),

          const SizedBox(height: 6),

          Align(
            alignment: amountAlign,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: border, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ETB ${NumberFormat('#,##0.00', 'en_US').format(amount)}',
                style: GoogleFonts.inconsolata(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE8ECF0)),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inconsolata(
                      fontSize: 10,
                      color: muted,
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
                      TextSpan(
                        text: 'Status: $status',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _statusColor(status, accent: accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (status == 'Issued')
                Container(
                  margin: const EdgeInsets.only(right: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                    color: accent.withValues(alpha: 0.08),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.verified_rounded, size: 16, color: accent),
                      const SizedBox(height: 2),
                      Text(
                        'DIGITAL',
                        style: GoogleFonts.inconsolata(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'STAMP',
                        style: GoogleFonts.inconsolata(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          if (showStatusPill) _StatusPill(status: status),

          if (showMicr) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                d?.micrText ?? '',
                style: GoogleFonts.inconsolata(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: primary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
            ],
          ),

          if (crossed)
            Positioned(
              top: 0,
              left: 0,
              child: IgnorePointer(
                child: SizedBox(
                  width: 130,
                  height: 96,
                  child: CustomPaint(
                    painter: _CrossedLinesPainter(
                      color: border.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _logoBlock({
    required double logoSize,
    required Color primary,
    required Color muted,
    required Color accent,
    required bool showHeadOffice,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            Constants.getBankLogoPath(bankKey),
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                size: logoSize * 0.55,
                color: accent.withValues(alpha: 0.6),
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
                color: primary,
                letterSpacing: -0.3,
              ),
            ),
            if (showHeadOffice) ...[
              const SizedBox(height: 2),
              Text(
                branch.isNotEmpty ? branch : 'Head Office · Addis Ababa',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: muted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _chequeNoBlock({
    required Color accent,
    required Color muted,
    required String chequeNumber,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Cheque No.',
          style: GoogleFonts.inter(
            fontSize: 9,
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          '#$chequeNumber',
          style: GoogleFonts.inconsolata(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _centeredHeader({
    required double logoSize,
    required Color primary,
    required Color muted,
    required Color accent,
    required bool showHeadOffice,
    required String chequeNumber,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: _logoBlock(
            logoSize: logoSize,
            primary: primary,
            muted: muted,
            accent: accent,
            showHeadOffice: showHeadOffice,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cheque No.',
          style: GoogleFonts.inter(
            fontSize: 9,
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          '#$chequeNumber',
          style: GoogleFonts.inconsolata(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _dateBlock({
    required Color accent,
    required Color muted,
    required DateTime date,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Date',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          DateFormat('dd / MM / yyyy').format(date),
          style: GoogleFonts.inconsolata(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status, {required Color accent}) {
    switch (status) {
      case 'Issued':
        return accent;
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

class _CrossedLinesPainter extends CustomPainter {
  final Color color;

  _CrossedLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final start = Offset(10, size.height);
    final end = Offset(size.width - 6, 12);
    final dir = end - start;
    final length = dir.distance;
    if (length == 0) return;

    final perp = Offset(-dir.dy / length, dir.dx / length) * 16;

    canvas.drawLine(start, end, paint);
    canvas.drawLine(start + perp, end + perp, paint);
  }

  @override
  bool shouldRepaint(covariant _CrossedLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ChequeLine extends StatelessWidget {
  final String label;
  final String value;
  final Color primary;
  final Color muted;

  const _ChequeLine({
    required this.label,
    required this.value,
    required this.primary,
    required this.muted,
  });

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
                color: muted,
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
                  color: primary,
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
