import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/accounts_provider.dart';
import '../providers/transactions_provider.dart';
import '../providers/cheques_provider.dart';
import '../providers/cheque_books_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../design/shared_widgets.dart';
import 'add_account_screen.dart';
import 'write_cheque_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showBalance = true;
  String _trendPeriod = 'weekly';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(accountsProvider.notifier).load();
      ref.read(transactionsProvider.notifier).load();
      ref.read(chequesProvider.notifier).load();
      ref.read(chequeBooksProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(transactionsProvider);
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    final chartData = _buildChartData(transactions);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/home'),
          Expanded(
            child: Column(
              children: [
                const AppHeader(title: 'Home'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (accounts.isEmpty)
                          _buildBalanceCard(context, currencyFormat)
                        else
                          _buildBalanceOverview(
                              context, accounts, currencyFormat),
                        const SizedBox(height: 24),
                        if (accounts.isNotEmpty && _hasQuickActions()) ...[
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                        ],
                        if (accounts.isNotEmpty && chartData.isNotEmpty) ...[
                          _buildChart(context, chartData),
                          const SizedBox(height: 24),
                        ],
                        if (accounts.isNotEmpty && transactions.isNotEmpty) ...[
                          _buildTransactionSummary(transactions, currencyFormat),
                          const SizedBox(height: 24),
                        ],
                        if (accounts.isNotEmpty)
                          _buildRecentTransactions(
                              context, transactions, currencyFormat),
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

  Widget _buildBalanceCard(BuildContext context, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1D26), Color(0xFF2D3142)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1D26).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.account_balance_rounded,
                size: 26, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'No bank account yet',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first bank account to track balances',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await AppWidgets.showBlurredDialog<String>(
                context,
                const AddAccountForm(),
                barrierLabel: 'Add Account',
              );
              if (result != null && context.mounted) {
                AppWidgets.showToast(context, result);
              }
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A1D26),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBalanceCard(
      BuildContext context, double totalBalance, NumberFormat currencyFormat) {
    final totalStr = currencyFormat.format(totalBalance);
    final txCount = ref.read(transactionsProvider).length;
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1D26), Color(0xFF2D3142)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1D26).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showBalance = !_showBalance),
                child: Icon(
                  _showBalance
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.zero,
                child: Text(
                  'ETB',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    color: Colors.white60,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _showBalance ? totalStr : '••••••',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat(Icons.account_balance_rounded,
                  '${ref.read(accountsProvider).length} Accounts'),
              _buildStat(
                  Icons.receipt_long_rounded, '$txCount Transactions'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceOverview(BuildContext context, List<Account> accounts,
      NumberFormat currencyFormat) {
    final sortedAccounts = List<Account>.from(accounts)
      ..sort((a, b) => a.bankName.compareTo(b.bankName));

    final panelTotal =
        sortedAccounts.fold<double>(0, (sum, a) => sum + a.balance);

    final card = _buildCompactBalanceCard(context, panelTotal, currencyFormat);
    final panel =
        _buildBankHighlights(context, sortedAccounts, currencyFormat);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card,
              const SizedBox(height: 16),
              panel,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: card),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: panel),
          ],
        );
      },
    );
  }

  Widget _buildBankHighlights(
      BuildContext context, List<Account> accounts, NumberFormat currencyFormat) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded,
                  size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                'Bank Balances',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D26),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...accounts.map((account) {
                      return _buildBankHighlightRow(
                          context, account, currencyFormat);
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankHighlightRow(
      BuildContext context, Account account, NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              Constants.getBankLogoPath(account.bankKey),
              width: 34,
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    size: 18, color: Color(0xFF2563EB)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.bankName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1D26),
                  ),
                ),
                if (account.accountName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    account.accountName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _showBalance
                ? 'ETB ${currencyFormat.format(account.balance)}'
                : '••••••',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D26),
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context, Map<int, double> chartData) {
    if (chartData.isEmpty) return const SizedBox.shrink();

    final pointCount = (_trendPeriod == 'yearly' || _trendPeriod == 'all') ? 12 : _trendPeriod == 'monthly' ? 4 : 7;
    final maxX = (pointCount - 1).toDouble();

    final spots = chartData.entries.map((e) {
      return FlSpot((maxX - e.key).toDouble(), e.value);
    }).toList();

    if (spots.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                'Balance Trend',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D26),
                ),
              ),
              const Spacer(),
              _trendTab('All', 'all'),
              const SizedBox(width: 4),
              _trendTab('Yearly', 'yearly'),
              const SizedBox(width: 4),
              _trendTab('Monthly', 'monthly'),
              const SizedBox(width: 4),
              _trendTab('Weekly', 'weekly'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFFF0F0F0).withValues(alpha: 0.5),
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
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx > maxX) return const SizedBox.shrink();
                        final label = _chartLabelForIndex(idx, maxX);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 9,
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
                maxX: maxX,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF2563EB),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipRoundedRadius: 10,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        ],
      ),
    );
  }

  Widget _trendTab(String label, String value) {
    final selected = _trendPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _trendPeriod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  String _chartLabelForIndex(int idx, double maxX) {
    final now = DateTime.now();
    if (_trendPeriod == 'weekly') {
      final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final dayOfWeek = now.subtract(Duration(days: maxX.toInt() - idx)).weekday % 7;
      return days[dayOfWeek];
    } else if (_trendPeriod == 'monthly') {
      final weeksAgo = maxX.toInt() - idx;
      final d = now.subtract(Duration(days: weeksAgo * 7));
      return DateFormat('MMM d').format(d);
    } else if (_trendPeriod == 'yearly') {
      final monthsAgo = maxX.toInt() - idx;
      final d = DateTime(now.year, now.month - monthsAgo, 1);
      return DateFormat('MMM').format(d);
    } else {
      final monthsAgo = maxX.toInt() - idx;
      final d = DateTime(now.year, now.month - monthsAgo, 1);
      return DateFormat('MMM yy').format(d);
    }
  }

  Map<int, double> _buildChartData(List<Transaction> transactions) {
    final accounts = ref.read(accountsProvider);
    if (accounts.isEmpty) return {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<int, double> dataPoints = {};

    if (_trendPeriod == 'weekly') {
      for (final account in accounts) {
        final accTx =
            transactions.where((t) => t.accountId == account.id).toList();
        final totalTx = accTx.fold<double>(0, (s, t) => s + t.amount);
        final opening = account.balance - totalTx;

        for (int i = 6; i >= 0; i--) {
          final day = DateTime(today.year, today.month, today.day - i);
          double dayBalance = opening;
          for (final tx in accTx) {
            final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
            if (!txDay.isAfter(day)) dayBalance += tx.amount;
          }
          dataPoints[i] = (dataPoints[i] ?? 0) + dayBalance;
        }
      }
    } else if (_trendPeriod == 'monthly') {
      for (final account in accounts) {
        final accTx =
            transactions.where((t) => t.accountId == account.id).toList();
        final totalTx = accTx.fold<double>(0, (s, t) => s + t.amount);
        final opening = account.balance - totalTx;

        for (int i = 3; i >= 0; i--) {
          final weekEnd = today.subtract(Duration(days: i * 7));
          double balance = opening;
          for (final tx in accTx) {
            final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
            if (!txDay.isAfter(weekEnd)) balance += tx.amount;
          }
          dataPoints[i] = (dataPoints[i] ?? 0) + balance;
        }
      }
    } else {
      for (final account in accounts) {
        final accTx =
            transactions.where((t) => t.accountId == account.id).toList();
        final totalTx = accTx.fold<double>(0, (s, t) => s + t.amount);
        final opening = account.balance - totalTx;

        for (int i = 11; i >= 0; i--) {
          final monthEnd = DateTime(now.year, now.month - i + 1, 0);
          double balance = opening;
          for (final tx in accTx) {
            final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
            if (!txDay.isAfter(monthEnd)) balance += tx.amount;
          }
          dataPoints[i] = (dataPoints[i] ?? 0) + balance;
        }
      }
    }

    final totalBalance = accounts.fold<double>(0, (s, a) => s + a.balance);
    dataPoints[0] = totalBalance;

    return dataPoints;
  }

  bool _hasQuickActions() {
    final authState = ref.read(authProvider);
    return authState.canAccess('cheques') ||
        authState.canAccess('accounts') ||
        authState.canAccess('deposits') ||
        authState.canAccess('transactions') ||
        authState.canAccess('transfers');
  }

  Widget _buildQuickActions() {
    final authState = ref.read(authProvider);
    final actions = <Widget>[];

    if (authState.canAccess('cheques')) {
      actions.add(Expanded(
        child: _buildActionCard(
          icon: Icons.receipt_long_rounded,
          label: 'Write Cheque',
          color: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEEF2FF),
          onTap: () => showWriteChequeDialog(context),
        ),
      ));
    }
    if (authState.canAccess('deposits')) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 12));
      actions.add(Expanded(
        child: _buildActionCard(
          icon: Icons.account_balance_rounded,
          label: 'Deposit',
          color: const Color(0xFF10B981),
          bgColor: const Color(0xFFD1FAE5),
          onTap: () => Navigator.pushNamed(context, '/deposit'),
        ),
      ));
    }
    if (authState.canAccess('transfers')) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 12));
      actions.add(Expanded(
        child: _buildActionCard(
          icon: Icons.send_rounded,
          label: 'Transfer',
          color: const Color(0xFFF59E0B),
          bgColor: const Color(0xFFFEF3C7),
          onTap: () => Navigator.pushNamed(context, '/transfer'),
        ),
      ));
    }


    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1D26),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: actions),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 10),
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
    );
  }

  Widget _buildTransactionSummary(List<Transaction> transactions, NumberFormat currencyFormat) {
    final now = DateTime.now();
    final thisMonth = transactions.where((t) =>
        t.date.year == now.year && t.date.month == now.month);
    final totalIncome = thisMonth
        .where((t) => t.amount > 0)
        .fold<double>(0, (s, t) => s + t.amount);
    final totalExpenses = thisMonth
        .where((t) => t.amount < 0)
        .fold<double>(0, (s, t) => s + t.amount.abs());
    final txCount = thisMonth.length;
    final transfers = thisMonth.where((t) => t.type == 'transfer').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Summary',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1D26),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                Icons.arrow_downward_rounded,
                'Income',
                'ETB ${currencyFormat.format(totalIncome)}',
                const Color(0xFF10B981),
                const Color(0xFFECFDF5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                Icons.arrow_upward_rounded,
                'Expenses',
                'ETB ${currencyFormat.format(totalExpenses)}',
                const Color(0xFFEF4444),
                const Color(0xFFFEF2F2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                Icons.receipt_long_rounded,
                'Transactions',
                '$txCount',
                const Color(0xFF2563EB),
                const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                Icons.swap_horiz_rounded,
                'Transfers',
                '$transfers',
                const Color(0xFFF59E0B),
                const Color(0xFFFEF3C7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(IconData icon, String label, String value,
      Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D26),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context,
      List<Transaction> transactions, NumberFormat currencyFormat) {
    final recent = transactions.take(5).toList();
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1D26),
          ),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No transactions yet',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1D26),
                  ),
                ),
              ],
            ),
          )
        else
          ...recent.map((tx) {
            final isCredit = tx.amount > 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF0F0F0)),
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
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
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
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
