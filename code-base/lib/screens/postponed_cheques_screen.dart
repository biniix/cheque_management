import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../providers/accounts_provider.dart';
import '../providers/cheque_books_provider.dart';
import '../providers/cheques_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import 'write_cheque_screen.dart';

/// Lists cheques whose date is in the future ("postponed" / post-dated cheques).
/// These are cheques that were written but the linked transaction takes effect
/// on the cheque date.
class PostponedChequesScreen extends ConsumerStatefulWidget {
  const PostponedChequesScreen({super.key});

  @override
  ConsumerState<PostponedChequesScreen> createState() =>
      _PostponedChequesScreenState();
}

class _PostponedChequesScreenState extends ConsumerState<PostponedChequesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(chequesProvider.notifier).load();
      await ref.read(chequeBooksProvider.notifier).load();
      await ref.read(accountsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cheques = ref.watch(chequesProvider);
    final books = ref.watch(chequeBooksProvider);
    final accounts = ref.watch(accountsProvider);
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('MMM d, yyyy');

    final now = DateTime.now();
    final postponed = cheques
        .where((c) => c.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/postponed-cheques'),
          Expanded(
            child: Column(
              children: [
                const AppHeader(title: 'Postponed Cheques'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary stats
                        Row(
                          children: [
                            _summaryChip(
                              '${postponed.length} cheque${postponed.length != 1 ? 's' : ''}',
                              Icons.receipt_long_outlined,
                              const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 10),
                            _summaryChip(
                              'ETB ${currencyFormat.format(postponed.fold(0.0, (s, c) => s + c.amount))}',
                              Icons.payments_outlined,
                              const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 10),
                            if (postponed.any((c) =>
                                c.date.difference(now).inDays <= 7 &&
                                c.date.isAfter(now)))
                              _summaryChip(
                                '${postponed.where((c) => c.date.difference(now).inDays <= 7 && c.date.isAfter(now)).length} due this week',
                                Icons.warning_amber_rounded,
                                const Color(0xFFD97706),
                              ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () =>
                                  showWriteChequeDialog(context),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                'Write Cheque',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: postponed.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  itemCount: postponed.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final cheque = postponed[index];
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
                                        cheque.chequeNumber,
                                        cheque.payee,
                                        cheque.amount,
                                        cheque.date,
                                        acc?.bankName ?? '',
                                        acc?.bankKey ?? '',
                                        acc?.accountName ?? '',
                                        currencyFormat,
                                        dateFormat);
                                  },
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

  Widget _buildChequeCard(
    String chequeNumber,
    String payee,
    double amount,
    DateTime date,
    String bankName,
    String bankKey,
    String accountName,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final daysLeft = target.difference(today).inDays;

    // Urgency: green (30+), blue (7-30), amber (1-7), red (today)
    final (daysColor, daysBg, daysLabel) = switch (daysLeft) {
      0 => (
        const Color(0xFFDC2626),
        const Color(0xFFFEE2E2),
        'Due today',
      ),
      <= 3 => (
        const Color(0xFFEA580C),
        const Color(0xFFFFF7ED),
        '$daysLeft day${daysLeft > 1 ? 's' : ''} left',
      ),
      <= 7 => (
        const Color(0xFFD97706),
        const Color(0xFFFEF3C7),
        '$daysLeft days left',
      ),
      <= 30 => (
        const Color(0xFF2563EB),
        const Color(0xFFEFF6FF),
        '$daysLeft days left',
      ),
      _ => (
        const Color(0xFF059669),
        const Color(0xFFECFDF5),
        '$daysLeft days left',
      ),
    };

    // Progress bar: how much of the waiting period has elapsed
    final maxDays = daysLeft > 90 ? daysLeft.toDouble() : 90.0;
    final progress = (maxDays - daysLeft) / maxDays;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Bank logo
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  Constants.getBankLogoPath(bankKey),
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.event_available_rounded,
                    size: 20,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Cheque info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Cheque #$chequeNumber',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1D26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: daysBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            daysLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: daysColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$bankName · $accountName  •  Pay: $payee',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Due ${dateFormat.format(date)}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Amount
              Text(
                'ETB ${currencyFormat.format(amount)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(daysColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                daysLeft == 0 ? 'NOW' : '${daysLeft}d',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: daysColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_available_rounded,
                size: 32, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 16),
          Text(
            'No postponed cheques',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Future-dated cheques will show up here',
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
