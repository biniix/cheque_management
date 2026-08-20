import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../widgets/bank_picker.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../constants.dart';
import '../design/shared_widgets.dart';

class EditAccountScreen extends ConsumerStatefulWidget {
  final Account account;

  const EditAccountScreen({super.key, required this.account});

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/accounts'),
          Expanded(
            child: Column(
              children: [
                const AppHeader(title: 'Edit Account'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: EditAccountForm(account: widget.account),
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
}

class EditAccountForm extends ConsumerStatefulWidget {
  final Account account;

  const EditAccountForm({super.key, required this.account});

  @override
  ConsumerState<EditAccountForm> createState() => _EditAccountFormState();
}

class _EditAccountFormState extends ConsumerState<EditAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  late String? _bankName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bankName = widget.account.bankName;
    _nameCtrl.text = widget.account.accountName;
    _numberCtrl.text = widget.account.accountNumber;
    _balanceCtrl.text = widget.account.balance.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          BankPicker(
            selectedBankName: _bankName,
            onChanged: (name) => setState(() => _bankName = name),
            label: 'Bank',
          ),
          const SizedBox(height: 20),

          _buildField(
            'Account Name',
            _nameCtrl,
            hint: 'e.g. Main Account',
            validator: (v) {
              if (v?.isEmpty ?? true) {
                return 'Required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          _buildField(
            'Account Number',
            _numberCtrl,
            hint: 'e.g. 1000234471',
            validator: (v) {
              if (v?.isEmpty ?? true) {
                return 'Required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          _buildField(
            'Balance (ETB)',
            _balanceCtrl,
            hint: 'e.g. 5000.00',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

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
                      'Save Changes',
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
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    bool readOnly = false,
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
          readOnly: readOnly,
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
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);

    final bankName = _bankName?.trim() ?? '';
    if (bankName.isEmpty) {
      AppWidgets.showToast(context, 'Please enter a bank name',
          isSuccess: false);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final updated = widget.account.copyWith(
      bankName: bankName,
      bankKey: Constants.getBankKey(bankName) ?? '',
      accountName: _nameCtrl.text.trim(),
      accountNumber: _numberCtrl.text.trim(),
      balance: double.tryParse(_balanceCtrl.text) ?? widget.account.balance,
    );

    await ref.read(accountsProvider.notifier).updateAccount(updated);

    if (context.mounted) {
      navigator.pop('Account updated');
    }
  }
}
