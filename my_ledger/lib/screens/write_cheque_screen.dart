import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/cheque.dart';
import '../models/cheque_book.dart';
import '../providers/accounts_provider.dart';
import '../providers/cheque_books_provider.dart';
import '../providers/cheques_provider.dart';
import '../providers/transactions_provider.dart';
import '../widgets/cheque_leaf.dart';
import '../utils/number_to_words.dart';
import '../utils/overdraft_dialog.dart';

class WriteChequeScreen extends ConsumerStatefulWidget {
  final int? editChequeId;

  const WriteChequeScreen({super.key, this.editChequeId});

  @override
  ConsumerState<WriteChequeScreen> createState() => _WriteChequeScreenState();
}

class _WriteChequeScreenState extends ConsumerState<WriteChequeScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedBookId;
  final _payeeCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isOrder = false; // false = Bearer, true = Order
  bool _crossed = true; // default to crossed
  bool _isSaving = false;
  String _amountInWords = '';
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(chequeBooksProvider.notifier).load();
      await ref.read(chequesProvider.notifier).load();
      await ref.read(accountsProvider.notifier).load();

      // If editing, pre-fill form
      if (widget.editChequeId != null) {
        final cheques = ref.read(chequesProvider);
        final cheque = cheques.where((c) => c.id == widget.editChequeId).firstOrNull;
        if (cheque != null) {
          _isEditMode = true;
          _selectedBookId = cheque.chequebookId;
          _payeeCtrl.text = cheque.payee == 'Bearer' ? '' : cheque.payee;
          _amountCtrl.text = cheque.amount.toStringAsFixed(2);
          _amountInWords = cheque.amountInWords;
          _date = cheque.date;
          _isOrder = cheque.bearerOrOrder == 'order';
          _crossed = cheque.crossed;
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _payeeCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String? get _nextNumber {
    final books = ref.read(chequeBooksProvider);
    final cheques = ref.read(chequesProvider);
    final selectedBook = _selectedBookId != null
        ? books.where((b) => b.id == _selectedBookId).firstOrNull
        : null;
    if (selectedBook == null) return null;

    // In edit mode, show the existing cheque's number
    if (_isEditMode && widget.editChequeId != null) {
      final existingCheque = cheques.where((c) => c.id == widget.editChequeId).firstOrNull;
      if (existingCheque != null) return existingCheque.chequeNumber;
    }

    final chequesForBook = cheques.where((c) => c.chequebookId == selectedBook.id).toList();
    final usedCount = chequesForBook.length;
    if (usedCount >= selectedBook.size) return null;
    final nextNum = int.parse(selectedBook.startNumber) + usedCount;
    return nextNum.toString().padLeft(selectedBook.startNumber.length, '0');
  }

  bool get _isBookFull {
    final books = ref.read(chequeBooksProvider);
    final cheques = ref.read(chequesProvider);
    final selectedBook = _selectedBookId != null
        ? books.where((b) => b.id == _selectedBookId).firstOrNull
        : null;
    if (selectedBook == null) return false;
    // Exclude the current cheque being edited from the count
    var usedCount = cheques.where((c) => c.chequebookId == selectedBook.id).length;
    if (_isEditMode && widget.editChequeId != null) {
      usedCount--; // The cheque being edited counts toward the total
    }
    return usedCount >= selectedBook.size;
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(chequeBooksProvider);
    final accounts = ref.watch(accountsProvider);
    final cheques = ref.watch(chequesProvider);
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    final selectedBook = _selectedBookId != null
        ? books.where((b) => b.id == _selectedBookId).firstOrNull
        : null;
    final account = selectedBook != null
        ? accounts.where((a) => a.id == selectedBook.accountId).firstOrNull
        : null;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final nextNumber = _nextNumber;
    final isBookFull = _isBookFull;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Cheque' : 'Write Cheque',
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
          if (nextNumber != null && amount > 0)
            TextButton.icon(
              onPressed: _isSaving ? null : _previewCheque,
              icon: const Icon(Icons.preview_rounded, size: 18),
              label: Text(
                'Preview',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main form card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF0F0F0)),
                ),
                child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Cheque Book
                          _sectionLabel('Cheque Book'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedBookId,
                            isExpanded: true,
                            decoration: _inputDecoration(),
                            hint: Text(
                              'Select cheque book',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                            items: [
                              ...books.map((b) {
                                final acc = accounts.where((a) => a.id == b.accountId).firstOrNull;
                                final used = cheques
                                    .where((c) => c.chequebookId == b.id)
                                    .length;
                                return DropdownMenuItem<int>(
                                  value: b.id,
                                  child: Text(
                                    '${acc?.bankName ?? 'Account'} — #${b.startNumber}-${b.endNumber} (${b.size - used} left)',
                                    style: GoogleFonts.inter(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                              const DropdownMenuItem<int>(
                                value: -1,
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline,
                                        size: 16, color: Color(0xFF2563EB)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Create new cheque book…',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) async {
                              if (v == -1) {
                                final created =
                                    await _showCreateChequeBookDialog(context, ref);
                                if (created != null) {
                                  setState(() => _selectedBookId = created.id);
                                }
                                return;
                              }
                              setState(() => _selectedBookId = v);
                            },
                            validator: (v) => v == null || v == -1 ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),

                          // Cheque Number display
                          if (nextNumber != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(18)),
                              child: Row(
                                children: [
                                  const Icon(Icons.tag_rounded,
                                      size: 16, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cheque #$nextNumber',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.check_circle,
                                      size: 16,
                                      color: Colors.green.shade400),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Payee
                          _sectionLabel('Payee'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _payeeCtrl,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF1A1D26),
                            ),
                            decoration: _textFieldDecoration(
                                hint: 'Full name or "Bearer"'),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),

                          // Amount
                          _sectionLabel('Amount (ETB)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountCtrl,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF1A1D26),
                            ),
                            keyboardType: TextInputType.number,
                            decoration: _textFieldDecoration(
                                hint: 'e.g. 5000.00'),
                            onChanged: (v) {
                              final amt = double.tryParse(v.replaceAll(',', ''));
                              if (amt != null && amt > 0) {
                                setState(() =>
                                    _amountInWords = NumberToWords.convert(amt));
                              } else {
                                setState(() => _amountInWords = '');
                              }
                            },
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Required';
                              final amt = double.tryParse(v!.replaceAll(',', ''));
                              if (amt == null || amt <= 0) {
                                return 'Enter a valid amount';
                              }
                              return null;
                            },
                          ),

                          // Amount in words
                          if (_amountInWords.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.text_fields_rounded,
                                      size: 14, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _amountInWords,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF4A4E5C),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Date
                          _sectionLabel('Date'),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: DateFormat('MMM d, yyyy').format(_date),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _date = picked);
                              }
                            },
                            decoration: InputDecoration(
                              suffixIcon: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: Color(0xFF9CA3AF)),
                              filled: true,
                              fillColor: const Color(0xFFF5F7FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          if (_date.isAfter(DateTime.now())) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.schedule_rounded,
                                    size: 14, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 6),
                                Text(
                                  'Post-dated cheque',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Payable To - Segmented Toggle
                          _sectionLabel('Payable To'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildToggleOption(
                                  'Bearer',
                                  'Payable to the holder',
                                  !_isOrder,
                                  () => setState(() => _isOrder = false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildToggleOption(
                                  'Order',
                                  'Payee name required',
                                  _isOrder,
                                  () => setState(() => _isOrder = true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Crossing - Segmented Toggle
                          _sectionLabel('Crossing'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildToggleOption(
                                  'Open',
                                  'Payable over the counter',
                                  !_crossed,
                                  () => setState(() => _crossed = false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildToggleOption(
                                  'Crossed',
                                  'Account payee only',
                                  _crossed,
                                  () => setState(() => _crossed = true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Issue button
                    if (isBookFull)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_rounded,
                                size: 18, color: Color(0xFFEF4444)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This cheque book is full. Create a new one.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _issueCheque,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Issue Cheque',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

              const SizedBox(height: 24),

              // Preview (below form)
              if (selectedBook != null && nextNumber != null && amount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.preview_rounded,
                              size: 16, color: Color(0xFF2563EB)),
                          const SizedBox(width: 6),
                          Text(
                            'Live Preview',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1D26),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ChequeLeaf(
                        bankName: account?.bankName ?? 'Bank Name',
                        bankKey: account?.bankKey ?? '',
                        chequeNumber: nextNumber,
                        date: _date,
                        payee:
                            _payeeCtrl.text.isEmpty ? 'Bearer' : _payeeCtrl.text,
                        isOrder: _isOrder,
                        amount: amount,
                        amountInWords: _amountInWords.isNotEmpty
                            ? _amountInWords
                            : '___________________________',
                        crossed: _crossed,
                        accountNumber: account?.accountNumber ?? '----',
                        status: 'Issued',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Balance check card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF0F0F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_rounded,
                            size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Text(
                          'Balance Check',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1D26),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Linked account
                    _balanceRow(
                      'Linked account',
                      account != null
                          ? '${account.bankName} ${account.accountNumber}'
                          : '—',
                    ),
                    const SizedBox(height: 8),

                    // Current balance
                    _balanceRow(
                      'Current balance',
                      account != null
                          ? 'ETB ${currencyFormat.format(account.balance)}'
                          : '—',
                      isMono: true,
                      isBold: true,
                    ),
                    const SizedBox(height: 8),

                    // Cheque amount
                    _balanceRow(
                      'Cheque amount',
                      amount > 0 ? 'ETB ${currencyFormat.format(amount)}' : '—',
                      isMono: true,
                      isBold: true,
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 16),

                    // Warning / Info
                    if (account != null && amount > 0) ...[
                      if (account.balance < amount && !_date.isAfter(DateTime.now()))
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_rounded,
                                  size: 16, color: Color(0xFFEF4444)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Insufficient funds',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF991B1B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Overdraft: ETB ${NumberFormat('#,##0.00', 'en_US').format(amount - account.balance)}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF991B1B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                              ),
                            ],
                          ),
                        )
                      else if (_date.isAfter(DateTime.now()))
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 16, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Post-dated — balance will be deducted on the cheque date.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF92400E),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sufficient funds available.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF065F46),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1D26),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  InputDecoration _textFieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildToggleOption(
    String label,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: 0.08)
              : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF9CA3AF),
                      width: isSelected ? 2 : 1.5,
                    ),
                    color: isSelected
                        ? const Color(0xFF2563EB).withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceRow(
    String label,
    String value, {
    bool isMono = false,
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? const Color(0xFF1A1D26),
          ),
        ),
      ],
    );
  }

  void _previewCheque() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBookId == null || _nextNumber == null) return;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;

    Navigator.pushNamed(
      context,
      '/cheque-preview',
      arguments: {
        'chequebookId': _selectedBookId!,
        'payee': _payeeCtrl.text.trim().isEmpty ? 'Bearer' : _payeeCtrl.text.trim(),
        'amount': amount,
        'amountInWords': _amountInWords,
        'date': _date.toIso8601String(),
        'isOrder': _isOrder,
        'crossed': _crossed,
        'editChequeId': _isEditMode ? widget.editChequeId : null,
      },
    );
  }

  Future<void> _issueCheque() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_selectedBookId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a cheque book')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isBookFull) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('This cheque book is full'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));
    final chequeNotifier = ref.read(chequesProvider.notifier);
    final txNotifier = ref.read(transactionsProvider.notifier);
    final books = ref.read(chequeBooksProvider);
    final selectedBook = books.firstWhere((b) => b.id == _selectedBookId!);
    final accounts = ref.read(accountsProvider);
    final account = accounts.firstWhere((a) => a.id == selectedBook.accountId);

    // Check balance for non-post-dated cheques
    if (account.balance < amount && !_date.isAfter(DateTime.now())) {
      setState(() => _isSaving = false);
      final proceed = await showOverdraftWarningDialog(
        context,
        accountName: account.accountName,
        bankName: account.bankName,
        balance: account.balance,
        chequeAmount: amount,
      );
      if (!proceed || !context.mounted) return;
      setState(() => _isSaving = true);
    }

    final nextNumber = await chequeNotifier.getNextNumber(
        _selectedBookId!, selectedBook.startNumber);

    int chequeId;
    if (_isEditMode && widget.editChequeId != null) {
      // Edit mode: Skip transaction and balance deduction (already done on original issue)
      // Preserve original transaction ID and just update the cheque record
      final originalCheque = ref.read(chequesProvider).where((c) => c.id == widget.editChequeId).firstOrNull;
      final originalTxId = originalCheque?.transactionId;
      await chequeNotifier.updateCheque(
        Cheque(
          id: widget.editChequeId!,
          chequebookId: _selectedBookId!,
          transactionId: originalTxId,
          chequeNumber: nextNumber,
          date: _date,
          payee: _payeeCtrl.text.isEmpty ? 'Bearer' : _payeeCtrl.text.trim(),
          amount: amount,
          amountInWords: _amountInWords,
          bearerOrOrder: _isOrder ? 'order' : 'bearer',
          crossed: _crossed,
          status: 'Issued',
        ),
      );
      chequeId = widget.editChequeId!;
    } else {
      // Issue new cheque — the API automatically creates the transaction and deducts balance
      final result = await chequeNotifier.addCheque(
        Cheque(
          id: 0,
          chequebookId: _selectedBookId!,
          chequeNumber: nextNumber,
          date: _date,
          payee: _payeeCtrl.text.isEmpty ? 'Bearer' : _payeeCtrl.text.trim(),
          amount: amount,
          amountInWords: _amountInWords,
          bearerOrOrder: _isOrder ? 'order' : 'bearer',
          crossed: _crossed,
          status: 'Issued',
        ),
      );
      chequeId = result.chequeId;

      // Save the transaction that the API created into local state
      if (result.transactionData != null) {
        await txNotifier.addTransactionFromApi(result.transactionData!);
      }

      // Update local account balance to match what the API calculated
      if (result.newBalance != null) {
        await ref.read(accountsProvider.notifier).updateBalance(
              account.id,
              result.newBalance!,
            );
      }
    }

    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Cheque #$nextNumber ${_isEditMode ? 'updated' : 'issued'}'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
    // Navigate to cheque detail screen using the returned ID
    navigator.pushReplacementNamed('/cheque-detail', arguments: chequeId);
  }

}

/// Dialog to create a new cheque book
Future<ChequeBook?> _showCreateChequeBookDialog(
    BuildContext context, WidgetRef ref) {
  int? selectedAccountId;
  int selectedSize = 25;
  final startNumberCtrl = TextEditingController(text: '1001');

  return showDialog<ChequeBook>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final accounts = ref.read(accountsProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
            title: Text(
              'Create Cheque Book',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: const Color(0xFF1A1D26),
              ),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: selectedAccountId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    hint: Text(
                      'Select account',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    items: accounts.map((a) {
                      return DropdownMenuItem<int>(
                        value: a.id,
                        child: Text(
                          '${a.bankName} — ${a.accountName}',
                          style: GoogleFonts.inter(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedAccountId = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Number of Cheques',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [10, 25, 50].map((size) {
                      final isSelected = selectedSize == size;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: size == 10 ? 0 : 6,
                            right: size == 50 ? 0 : 6,
                          ),
                          child: GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedSize = size),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                        .withValues(alpha: 0.1)
                                    : const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$size',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF1A1D26),
                                    ),
                                  ),
                                  Text(
                                    'leaves',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Starting Number',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: startNumberCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF1A1D26),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. 1001',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  if (selectedAccountId != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$selectedSize cheques • #${startNumberCtrl.text} to #${(int.tryParse(startNumberCtrl.text) ?? 1001) + selectedSize - 1}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF4A4E5C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedAccountId == null) return;
                  if (startNumberCtrl.text.isEmpty) return;
                  final startNum = int.tryParse(startNumberCtrl.text);
                  if (startNum == null) return;

                  final endNum = startNum + selectedSize - 1;
                  final book = ChequeBook(
                    id: 0,
                    accountId: selectedAccountId!,
                    size: selectedSize,
                    startNumber: startNumberCtrl.text.trim(),
                    endNumber: endNum.toString().padLeft(
                        startNumberCtrl.text.length, '0'),
                  );
                  final navigator = Navigator.of(dialogContext);
                  await ref.read(chequeBooksProvider.notifier).addChequeBook(book);
                  final createdBook = ref.read(chequeBooksProvider).last;
                  navigator.pop(createdBook);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
        ),
                child: Text(
                  'Create',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
