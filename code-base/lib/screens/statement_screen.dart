import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/accounts_provider.dart';
import '../providers/transactions_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../design/shared_widgets.dart';

class StatementScreen extends ConsumerStatefulWidget {
  const StatementScreen({super.key});

  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  final Set<int> _selectedAccountIds = {};

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(transactionsProvider);

    if (_selectedAccountIds.isEmpty && accounts.isNotEmpty) {
      Future.microtask(() {
        setState(() => _selectedAccountIds.addAll(accounts.map((a) => a.id)));
      });
    }

    final selectedAccounts =
        accounts.where((a) => _selectedAccountIds.contains(a.id)).toList();

    final filtered = transactions.where((t) {
      if (!_selectedAccountIds.contains(t.accountId)) return false;
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      final fromDay = DateTime(_from.year, _from.month, _from.day);
      final toDay = DateTime(_to.year, _to.month, _to.day);
      return !day.isBefore(fromDay) && !day.isAfter(toDay);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final income = filtered
        .where((t) => t.amount > 0)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = filtered
        .where((t) => t.amount < 0)
        .fold<double>(0, (s, t) => s + t.amount.abs());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/transactions'),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  title: 'Bank Statement',
                  actions: [
                    TextButton.icon(
                      onPressed: selectedAccounts.isEmpty
                          ? null
                          : () => _printStatement(context, selectedAccounts,
                              filtered, income, expense, currencyFormat),
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print'),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: const Color(0xFFF0F0F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Banks',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1D26),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (accounts.isEmpty)
                                    Text(
                                      'No accounts yet. Add an account first.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    )
                                  else
                                    ...accounts.map((a) {
                                      return CheckboxListTile(
                                        value:
                                            _selectedAccountIds.contains(a.id),
                                        onChanged: (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedAccountIds.add(a.id);
                                            } else {
                                              _selectedAccountIds.remove(a.id);
                                            }
                                          });
                                        },
                                        title: Text(
                                          a.bankName,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF1A1D26),
                                          ),
                                        ),
                                        subtitle: Text(
                                          a.accountName,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                        activeColor: const Color(0xFF2563EB),
                                      );
                                    }),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _dateField(
                                          'From',
                                          _from,
                                          (d) => setState(() => _from = d),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _dateField(
                                          'To',
                                          _to,
                                          (d) => setState(() => _to = d),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                _summaryCard('Income', income,
                                    const Color(0xFF10B981), currencyFormat),
                                const SizedBox(width: 12),
                                _summaryCard('Expense', expense,
                                    const Color(0xFFEF4444), currencyFormat),
                                const SizedBox(width: 12),
                                _summaryCard(
                                    'Net',
                                    income - expense,
                                    income - expense >= 0
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFFEF4444),
                                    currencyFormat),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Text(
                              '${filtered.length} Transaction${filtered.length != 1 ? 's' : ''} in period',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (filtered.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: const Color(0xFFF0F0F0)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.receipt_long_outlined,
                                        size: 40, color: Colors.grey.shade300),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No transactions in this period',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1D26),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: const Color(0xFFF0F0F0)
                                          .withValues(alpha: 0.5)),
                                ),
                                child: Column(
                                  children: filtered.map((tx) {
                                    final acc = accounts
                                        .where((a) => a.id == tx.accountId)
                                        .firstOrNull;
                                    return _statementRow(
                                        tx, acc, currencyFormat);
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
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

  Widget _dateField(
      String label, DateTime value, ValueChanged<DateTime> onPicked) {
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
          readOnly: true,
          controller: TextEditingController(
              text: DateFormat('MMM d, yyyy').format(value)),
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
            suffixIcon: Icon(Icons.calendar_today_rounded,
                size: 16, color: Color(0xFF9CA3AF)),
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

  Widget _summaryCard(
      String label, double value, Color color, NumberFormat currencyFormat) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ETB ${currencyFormat.format(value)}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statementRow(
      Transaction tx, Account? acc, NumberFormat currencyFormat) {
    final isCredit = tx.amount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: const Color(0xFFF0F0F0).withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  isCredit ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 15,
              color:
                  isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acc?.bankName ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1D26),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.description ?? tx.type}  •  ${DateFormat('MMM d, yyyy').format(tx.date)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isCredit ? '+' : '-'}ETB ${currencyFormat.format(tx.amount.abs())}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color:
                  isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printStatement(
    BuildContext context,
    List<Account> accounts,
    List<Transaction> transactions,
    double income,
    double expense,
    NumberFormat currencyFormat,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Bank Statement',
                    style: const pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.Text(
                    'Cheque Management',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Period: ${DateFormat('MMM d, yyyy').format(_from)} — ${DateFormat('MMM d, yyyy').format(_to)}',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Banks: ${accounts.map((a) => a.bankName).join(', ')}',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pdfSummary('Income', income, PdfColors.green700),
                  _pdfSummary('Expense', expense, PdfColors.red700),
                  _pdfSummary('Net', income - expense, PdfColors.blue700),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue50,
                ),
                child: pw.Row(
                  children: [
                    _pdfCell('Date', flex: 2),
                    _pdfCell('Bank', flex: 3),
                    _pdfCell('Description', flex: 4),
                    _pdfCell('Amount (ETB)', flex: 3, alignRight: true),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),

              if (transactions.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 16),
                  child: pw.Text(
                    'No transactions in this period.',
                    style: const pw.TextStyle(color: PdfColors.grey600),
                  ),
                )
              else
                for (final tx in transactions)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      children: [
                        _pdfCell(
                          DateFormat('MMM d, yyyy').format(tx.date),
                          flex: 2,
                        ),
                        _pdfCell(
                          accounts
                                  .where((a) => a.id == tx.accountId)
                                  .firstOrNull
                                  ?.bankName ??
                              '',
                          flex: 3,
                        ),
                        _pdfCell(tx.description ?? tx.type, flex: 4),
                        _pdfCell(
                          '${tx.amount > 0 ? '+' : '-'}${currencyFormat.format(tx.amount.abs())}',
                          flex: 3,
                          alignRight: true,
                          bold: true,
                          color: tx.amount > 0
                              ? PdfColors.green700
                              : PdfColors.red700,
                        ),
                      ],
                    ),
                  ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generated by Cheque Management',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name: 'Bank_Statement_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  pw.Widget _pdfSummary(String label, double value, PdfColor color) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'ETB ${NumberFormat('#,##0.00', 'en_US').format(value)}',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfCell(
    String text, {
    int flex = 1,
    bool alignRight = false,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
