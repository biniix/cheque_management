import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants.dart';
import '../providers/accounts_provider.dart';
import '../providers/transactions_provider.dart';
import '../models/account.dart';

class BankDetailScreen extends ConsumerWidget {
  final String accountKey;

  const BankDetailScreen({super.key, required this.accountKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(transactionsProvider);

    // Parse accountKey to find the account (it's either an ID or bankKey-last4)
    final accountId = int.tryParse(accountKey);
    Account? account;
    if (accountId != null) {
      try {
        account = accounts.firstWhere((a) => a.id == accountId);
      } catch (_) {}
    } else {
      // Try to find by bank key
      final parts = accountKey.split('-');
      if (parts.isNotEmpty) {
        final bankKey = parts[0];
        try {
          account = accounts.firstWhere((a) => a.bankKey == bankKey);
        } catch (_) {}
      }
    }

    if (account == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Account',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF1A1D26)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Account not found',
                  style: GoogleFonts.inter(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final safeAccount = account;
    final accountTransactions = transactions
        .where((t) => t.accountId == safeAccount.id)
        .toList();

    final bankKey = safeAccount.bankKey;
    final bankName = safeAccount.bankName;
    final last4 = safeAccount.last4;
    final balance = safeAccount.balance;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    // Calculate credit/debit totals
    double totalCredits = 0;
    double totalDebits = 0;
    for (final tx in accountTransactions) {
      if (tx.amount > 0) {
        totalCredits += tx.amount;
      } else {
        totalDebits += tx.amount.abs();
      }
    }

    // Prepare chart spots for last 7 days
    final chartSpots = <FlSpot>[];
    final now = DateTime.now();
    double runningBalance = balance;
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayTx = accountTransactions.where((tx) =>
          tx.date.isAfter(dayStart) &&
          tx.date.isBefore(dayStart.add(const Duration(days: 1))));

      // Adjust balance for this day's transactions
      for (final tx in dayTx) {
        runningBalance -= tx.amount;
      }
      chartSpots.add(FlSpot(i.toDouble(), runningBalance));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF1A1D26)),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              Constants.getBankLogoPath(bankKey),
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(18)),
                                child: const Icon(Icons.account_balance,
                                    size: 22, color: Color(0xFF9CA3AF)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bankName,
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1D26),
                                  ),
                                ),
                                Text(
                                  '••$last4',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF9CA3AF),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Current Balance',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ETB ${currencyFormat.format(balance)}',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1D26),
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Credits',
                          'ETB ${currencyFormat.format(totalCredits)}',
                          const Color(0xFF059669),
                          Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Debits',
                          'ETB ${currencyFormat.format(totalDebits)}',
                          const Color(0xFFDC2626),
                          Icons.arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Chart
                if (chartSpots.length > 1) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Balance Trend',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final dayOffset = value.toInt().clamp(0, 6);
                                final dayDate =
                                    now.subtract(Duration(days: dayOffset));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('E').format(dayDate),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 6,
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartSpots,
                            isCurved: true,
                            color: const Color(0xFF2563EB),
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => Colors.white,
                            tooltipRoundedRadius: 10,
                            tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  'ETB ${NumberFormat('#,##0.00', 'en_US').format(spot.y)}',
                                  const TextStyle(
                                    color: Color(0xFF1A1D26),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                          handleBuiltInTouches: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Transactions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Transactions',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...accountTransactions.map((tx) {
                  final isCredit = tx.amount > 0;
                  return Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCredit
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(18)),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: isCredit
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.description ?? tx.type,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1D26),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateFormat.format(tx.date),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
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
                              '${isCredit ? '+' : '-'}ETB ${currencyFormat.format(tx.amount.abs())}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isCredit
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D26),
            ),
          ),
        ],
      ),
    );
  }
}
