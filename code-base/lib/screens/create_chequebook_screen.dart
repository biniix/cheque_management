import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cheque_book.dart';
import '../providers/accounts_provider.dart';
import '../providers/cheque_books_provider.dart';
import '../providers/cheque_templates_provider.dart';

class CreateChequebookScreen extends ConsumerStatefulWidget {
  const CreateChequebookScreen({super.key});

  @override
  ConsumerState<CreateChequebookScreen> createState() =>
      _CreateChequebookScreenState();
}

class _CreateChequebookScreenState
    extends ConsumerState<CreateChequebookScreen> {
  int? _selectedAccountId;
  int? _selectedTemplateId;
  int _size = 25;
  final _startNumberCtrl = TextEditingController(text: '1001');
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(accountsProvider.notifier).load();
      await ref.read(chequeTemplatesProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _startNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    // Wallets (Telebirr / M-PESA) are not banks — you cannot issue a cheque
    // book against them.
    final bankAccounts = accounts
        .where((a) => a.bankKey != 'telebirr' && a.bankKey != 'mpesa')
        .toList();

    final templates = ref.watch(chequeTemplatesProvider);
    final selectedAccount = _selectedAccountId != null
        ? accounts.where((a) => a.id == _selectedAccountId).firstOrNull
        : null;
    // Templates for the selected account's bank — the user picks one of the
    // existing templates when creating the book.
    final bankTemplates = selectedAccount != null
        ? templates
            .where((t) => t.template.bankKey == selectedAccount.bankKey)
            .toList()
        : <ChequeTemplateWithFields>[];
    final hasBankTemplate = selectedAccount != null && bankTemplates.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Create Cheque Book',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                    // Account
                    Text(
                      'Account',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1D26),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedAccountId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      items: bankAccounts.map((a) {
                        return DropdownMenuItem<int>(
                          value: a.id,
                          child: Text(
                            '${a.bankName} - ${a.accountName}',
                            style: GoogleFonts.inter(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() {
                        _selectedAccountId = v;
                        _selectedTemplateId = null;
                      }),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Template — pick from the templates that exist for this bank.
                    Text(
                      'Cheque Template',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1D26),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedAccount != null && !hasBankTemplate)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_rounded,
                                size: 16, color: Color(0xFFEF4444)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No cheque template exists for ${selectedAccount.bankName}. Create one under Admin → Cheque Templates before creating a book.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        initialValue: _selectedTemplateId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        hint: Text(
                          'Choose a template…',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        items: bankTemplates.map((t) {
                          return DropdownMenuItem<int>(
                            value: t.template.id,
                            child: Text(
                              t.template.templateName,
                              style: GoogleFonts.inter(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedTemplateId = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    const SizedBox(height: 20),

                    // Size
                    Text(
                      'Number of Cheques',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1D26),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      // Buttons are sized proportionally to the leaf count
                      // (10 : 25 : 50) so 50 is biggest and 10 smallest.
                      children: [10, 25, 50].map((size) {
                        final isSelected = _size == size;
                        return Expanded(
                          flex: size,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: size == 50 ? 0 : 8,
                              right: size == 10 ? 0 : 8,
                            ),
                            child: GestureDetector(
                              onTap: () => setState(() => _size = size),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                          .withValues(alpha: 0.1)
                                      : const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF1A1D26),
                                      ),
                                    ),
                                    Text(
                                      'leaves',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
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
                    const SizedBox(height: 20),

                    // Start Number
                    _buildField(
                      'Starting Cheque Number',
                      _startNumberCtrl,
                      hint: 'e.g. 1001',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(v!) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Preview
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 20, color: Color(0xFF2563EB)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cheque Book Summary',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1D26),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_size cheques • #${_startNumberCtrl.text} to #${(int.tryParse(_startNumberCtrl.text) ?? 1001) + _size - 1}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
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
                          'Create Cheque Book',
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
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }
    if (_selectedTemplateId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please choose a cheque template')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final startNum = int.parse(_startNumberCtrl.text);
    final endNum = startNum + _size - 1;

    final book = ChequeBook(
      id: 0,
      accountId: _selectedAccountId!,
      size: _size,
      startNumber: _startNumberCtrl.text.trim(),
      endNumber: endNum.toString().padLeft(_startNumberCtrl.text.length, '0'),
      templateId: _selectedTemplateId,
    );

    await ref.read(chequeBooksProvider.notifier).addChequeBook(book);

    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Cheque book created with $_size leaves'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      navigator.pop();
    }
  }
}
