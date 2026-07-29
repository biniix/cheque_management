import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../widgets/bank_picker.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../constants.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  String? _selectedBankKey;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/accounts'),
          Expanded(
            child: Scaffold(
              key: _messengerKey,
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  const AppHeader(title: 'Add Account'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                // Bank Picker
                                BankPicker(
                                  selectedBankKey: _selectedBankKey,
                                  onSelected: (key) =>
                                      setState(() => _selectedBankKey = key),
                                  label: 'Bank',
                                ),
                                const SizedBox(height: 20),

                                // Account Name
                                _buildField(
                                  'Account Name',
                                  _nameCtrl,
                                  hint: 'e.g. Main Account',
                                  validator: (v) {
                                    if (v?.isEmpty ?? true) return 'Required';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Account Number
                                _buildField(
                                  'Account Number',
                                  _numberCtrl,
                                  hint: 'e.g. 1000234471',
                                  validator: (v) {
                                    if (v?.isEmpty ?? true) return 'Required';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Opening Balance
                                _buildField(
                                  'Opening Balance (ETB)',
                                  _balanceCtrl,
                                  hint: 'e.g. 5000.00',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
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
                                  : Text(
                                      'Add Account',
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
                ],
              ),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    
    if (_selectedBankKey == null) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Please select a bank'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final accountsNotifier = ref.read(accountsProvider.notifier);
    final balance = double.tryParse(_balanceCtrl.text) ?? 0.0;

    final a = Account(
      id: 0,
      bankName: Constants.getBankName(_selectedBankKey!),
      bankKey: _selectedBankKey!,
      accountName: _nameCtrl.text.trim(),
      accountNumber: _numberCtrl.text.trim(),
      balance: balance,
    );

    await accountsNotifier.addAccount(a);

    if (context.mounted) {
      navigator.pop('${a.bankName} account added');
    }
  }
}
