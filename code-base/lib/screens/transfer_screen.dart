import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../design/shared_widgets.dart';
import '../providers/accounts_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/transactions_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  int? _selectedAccountId;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _payeeCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _method = 'cash';
  bool _isSaving = false;
  bool _useExistingCustomer = true;
  int? _selectedCustomerId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(accountsProvider.notifier).load());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _payeeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final customers = ref.watch(customersProvider);
    final sortedAccounts = accounts.toList()
      ..sort((a, b) =>
          a.bankName.toLowerCase().compareTo(b.bankName.toLowerCase()));
    final sortedCustomers = customers.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/transfer'),
          Expanded(
            child: Column(
              children: [
                const AppHeader(title: 'Record Transfer'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFF0F0F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Account
                                    Text(
                                      'From Account',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1D26),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<int>(
                                      initialValue: _selectedAccountId ??
                                          accounts.firstOrNull?.id,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color(0xFFF5F7FA),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 10),
                                      ),
                                      items: sortedAccounts.map((a) {
                                        return DropdownMenuItem<int>(
                                          value: a.id,
                                          child: Text(
                                            '${a.bankName} - ${a.accountName}',
                                            style:
                                                GoogleFonts.inter(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (v) => setState(
                                          () => _selectedAccountId = v),
                                      validator: (v) =>
                                          v == null ? 'Required' : null,
                                    ),
                                    const SizedBox(height: 14),

                                    // Customer toggle
                                    Text(
                                      'Payee',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1D26),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => setState(() =>
                                                _useExistingCustomer = true),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: _useExistingCustomer
                                                    ? const Color(0xFF5B5BD6)
                                                        .withValues(alpha: 0.1)
                                                    : const Color(0xFFF5F7FA),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: _useExistingCustomer
                                                      ? const Color(0xFF5B5BD6)
                                                      : Colors.transparent,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Existing',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: _useExistingCustomer
                                                        ? const Color(
                                                            0xFF5B5BD6)
                                                        : const Color(
                                                            0xFF6B7280),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => setState(() =>
                                                _useExistingCustomer = false),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: !_useExistingCustomer
                                                    ? const Color(0xFF5B5BD6)
                                                        .withValues(alpha: 0.1)
                                                    : const Color(0xFFF5F7FA),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: !_useExistingCustomer
                                                      ? const Color(0xFF5B5BD6)
                                                      : Colors.transparent,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'New',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: !_useExistingCustomer
                                                        ? const Color(
                                                            0xFF5B5BD6)
                                                        : const Color(
                                                            0xFF6B7280),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Payee field
                                    if (_useExistingCustomer &&
                                        customers.isNotEmpty)
                                      DropdownButtonFormField<int>(
                                        initialValue: _selectedCustomerId,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color(0xFFF5F7FA),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 14),
                                        ),
                                        items: sortedCustomers.map((c) {
                                          return DropdownMenuItem<int>(
                                            value: c.id,
                                            child: Text(
                                              c.name,
                                              style: GoogleFonts.inter(
                                                  fontSize: 13),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (v) => setState(
                                            () => _selectedCustomerId = v),
                                      )
                                    else
                                      _buildField(
                                        'Payee Name',
                                        _payeeCtrl,
                                        hint: 'e.g. Amanuel Tesfaye',
                                        validator: (v) {
                                          if (!_useExistingCustomer &&
                                              (v?.isEmpty ?? true)) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    const SizedBox(height: 14),

                                    // Amount
                                    _buildField(
                                      'Amount (ETB)',
                                      _amountCtrl,
                                      hint: 'e.g. 5000.00',
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        if (v?.isEmpty ?? true) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(v!) == null ||
                                            double.parse(v) <= 0) {
                                          return 'Enter a valid amount';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Payment method
                                    Text(
                                      'Payment Method',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1D26),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    AppWidgets.paymentMethodPicker(
                                      context,
                                      selected: _method,
                                      onChanged: (m) =>
                                          setState(() => _method = m),
                                    ),
                                    const SizedBox(height: 14),

                                    // Date
                                    Text(
                                      'Date',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1D26),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      readOnly: true,
                                      controller: TextEditingController(
                                        text: DateFormat('MMM d, yyyy')
                                            .format(_date),
                                      ),
                                      onTap: () async {
                                        final picked = await AppWidgets.pickDate(
                                          context,
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
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 10),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // Description
                                    _buildField(
                                      'Description (optional)',
                                      _descCtrl,
                                      hint: 'e.g. Supplier payment',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Save
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    elevation: 0,
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : Text(
                                          'Record Transfer',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1D26),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1A1D26),
          ),
          decoration: InputDecoration(
            hintText: null,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_selectedAccountId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please select an account'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final amount = double.parse(_amountCtrl.text);
    final accountsNotifier = ref.read(accountsProvider.notifier);
    final txNotifier = ref.read(transactionsProvider.notifier);
    final accounts = ref.read(accountsProvider);
    final account = accounts.firstWhere((a) => a.id == _selectedAccountId);

    // Check balance
    if (account.balance < amount) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    String payeeName = '';
    if (_useExistingCustomer && _selectedCustomerId != null) {
      final customers = ref.read(customersProvider);
      final customer =
          customers.where((c) => c.id == _selectedCustomerId).firstOrNull;
      payeeName = customer?.name ?? '';
    } else {
      payeeName = _payeeCtrl.text.trim();
    }

    await txNotifier.addTransaction(
      Transaction(
        id: 0,
        accountId: account.id,
        type: 'transfer',
        method: _method,
        amount: -amount,
        date: _date,
        payee: payeeName,
        description:
            _descCtrl.text.isEmpty ? 'Transfer' : _descCtrl.text.trim(),
      ),
    );

    await accountsNotifier.updateBalance(account.id, account.balance - amount);

    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('ETB ${amount.toStringAsFixed(2)} transferred'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          duration: const Duration(milliseconds: 1500),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1000));
      if (context.mounted) navigator.pop();
    }
  }
}
