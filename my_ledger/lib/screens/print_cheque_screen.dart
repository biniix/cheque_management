import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/account.dart';
import '../models/cheque.dart';
import '../providers/cheques_provider.dart';
import '../providers/cheque_books_provider.dart';
import '../providers/accounts_provider.dart';
import '../widgets/cheque_leaf.dart';
import '../constants.dart';

class PrintChequeScreen extends ConsumerWidget {
  final int chequeId;

  const PrintChequeScreen({super.key, required this.chequeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cheques = ref.watch(chequesProvider);
    final cheque = cheques.where((c) => c.id == chequeId).firstOrNull;
    final books = ref.watch(chequeBooksProvider);
    final accounts = ref.watch(accountsProvider);

    if (cheque == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Print Cheque')),
        body: const Center(child: Text('Cheque not found')),
      );
    }

    final book = books.where((b) => b.id == cheque.chequebookId).firstOrNull;
    final acc = book != null
        ? accounts.where((a) => a.id == book.accountId).firstOrNull
        : null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Print Cheque',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1D26),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1D26)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _printCheque(context, ref, cheque, acc),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Print'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PRINT PREVIEW',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Cheque #${cheque.chequeNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Print Preview',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D26),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This is exactly how the cheque will appear when printed.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // ChequeLeaf widget — same design as the preview
            ChequeLeaf(
              bankName: acc?.bankName ?? 'Bank Name',
              bankKey: acc?.bankKey ?? '',
              chequeNumber: cheque.chequeNumber,
              date: cheque.date,
              payee: cheque.payee.isEmpty ? 'Bearer' : cheque.payee,
              isOrder: cheque.bearerOrOrder == 'order',
              amount: cheque.amount,
              amountInWords: cheque.amountInWords,
              crossed: cheque.crossed,
              accountNumber: acc?.accountNumber ?? '----',
              status: cheque.status,
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildPdf(
      BuildContext context,
      Cheque cheque,
      Account? acc) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    // Try to load bank logo
    pw.ImageProvider? logoImage;
    if (acc != null && acc.bankKey.isNotEmpty) {
      try {
        final data = await rootBundle.load(Constants.getBankLogoPath(acc.bankKey));
        logoImage = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        logoImage = null;
      }
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header - Bank Logo + Name & Cheque Number (matching ChequeLeaf)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    children: [
                      // Bank logo
                      if (logoImage != null)
                        pw.Container(
                          width: 36,
                          height: 36,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          width: 36,
                          height: 36,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue50,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Center(
                            child: pw.Icon(
                              const pw.IconData(0xe539),
                              size: 20,
                              color: PdfColors.blue600,
                            ),
                          ),
                        ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            acc?.bankName ?? 'Bank Name',
                            style: const pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Head Office \u00b7 Addis Ababa',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Cheque number
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Cheque No.',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey400,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        '#${cheque.chequeNumber}',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Divider
              pw.SizedBox(height: 12),
              pw.Divider(height: 1, color: PdfColors.grey200),
              pw.SizedBox(height: 12),

              // Account info
              pw.Text(
                'Account: ${acc?.accountNumber ?? ''}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              if (acc != null && acc.accountName.isNotEmpty)
                pw.Text(
                  acc.accountName,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              pw.SizedBox(height: 20),

              // Date line (matching ChequeLine style)
              _pdfChequeLine('DATE', dateFormat.format(cheque.date)),
              pw.SizedBox(height: 6),

              // Payee line
              _pdfChequeLine('PAY',
                  '${cheque.payee.isNotEmpty ? cheque.payee : 'Bearer'}   ${cheque.bearerOrOrder == 'order' ? 'or Order' : 'or Bearer'}'),
              pw.SizedBox(height: 6),

              // Amount in words
              _pdfChequeLine(
                'THE SUM OF',
                cheque.amountInWords.isNotEmpty
                    ? cheque.amountInWords
                    : '___________________________',
                italic: true,
              ),

              pw.SizedBox(height: 10),

              // Amount in figures (right-aligned box)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'ETB ${currencyFormat.format(cheque.amount)}',
                    style: const pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 16),
              pw.Divider(height: 1, color: PdfColors.grey200),
              pw.SizedBox(height: 10),

              // Footer: account details + crossing + digital stamp
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Account info and crossing
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Account: ${acc?.accountNumber ?? '----'}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600),
                        ),
                        if (cheque.crossed)
                          pw.Text(
                            'A/C Payee Only \u2014 Not Negotiable',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Digital stamp (replaces signature)
                  if (cheque.status == 'Issued')
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.blue600, width: 1.5),
                        borderRadius: pw.BorderRadius.circular(6),
                        color: PdfColors.blue50,
                      ),
                      child: pw.Column(
                        children: [
                          pw.Icon(const pw.IconData(0xe944), size: 16, color: PdfColors.blue600),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'DIGITAL',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue600,
                            ),
                          ),
                          pw.Text(
                            'STAMP',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Crossing lines (if crossed)
              if (cheque.crossed) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(
                            width: 60, height: 2, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('A/C PAYEE',
                            style: const pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Container(
                            width: 60, height: 2, color: PdfColors.black),
                      ],
                    ),
                  ],
                ),
              ],

              pw.SizedBox(height: 10),

              // Status pill
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _pdfStatusBgColor(cheque.status),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  cheque.status.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _pdfStatusTextColor(cheque.status),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfChequeLine(String label, String value,
      {bool italic = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 85,
          child: pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey400,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 3),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.normal,
                fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  PdfColor _pdfStatusBgColor(String status) {
    switch (status) {
      case 'Issued':
        return PdfColors.blue50;
      case 'Cleared':
        return PdfColors.green50;
      case 'Stale':
        return PdfColors.amber50;
      case 'Void':
        return PdfColors.red50;
      default:
        return PdfColors.grey100;
    }
  }

  PdfColor _pdfStatusTextColor(String status) {
    switch (status) {
      case 'Issued':
        return PdfColors.blue700;
      case 'Cleared':
        return PdfColors.green700;
      case 'Stale':
        return PdfColors.amber700;
      case 'Void':
        return PdfColors.red700;
      default:
        return PdfColors.grey700;
    }
  }

  Future<void> _printCheque(
      BuildContext context, WidgetRef ref, Cheque cheque, Account? acc) async {
    try {
      final pdfData = await _buildPdf(context, cheque, acc);
      await Printing.layoutPdf(
        onLayout: (_) => pdfData,
        name: 'Cheque_${cheque.chequeNumber}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }


}
