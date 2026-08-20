import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import '../../providers/employees_provider.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/app_header.dart';
import '../../design/shared_widgets.dart';
import '../../utils/password_generator.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/admin/employees'),
          Expanded(
            child: Column(
              children: [
                const AppHeader(title: 'Add New Employee'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF0F0F0)),
                          ),
                          child: const AddEmployeeForm(),
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
}

class AddEmployeeForm extends ConsumerStatefulWidget {
  const AddEmployeeForm({super.key});

  @override
  ConsumerState<AddEmployeeForm> createState() => _AddEmployeeFormState();
}

class _AddEmployeeFormState extends ConsumerState<AddEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final Set<String> _selectedModules = {};
  bool _obscurePassword = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _positionCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _generatePassword() {
    setState(() {
      _passwordCtrl.text = generatePassword();
      _obscurePassword = false;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final employee = await ref.read(employeesProvider.notifier).addEmployee(
            name: _nameCtrl.text.trim(),
            position: _positionCtrl.text.trim(),
            password: _passwordCtrl.text,
            moduleAccess: _selectedModules.toList(),
          );
      if (!mounted) return;
      Navigator.pop(
          context, 'Employee ${employee.employeeId} created successfully');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppWidgets.showToast(context, 'Failed to create employee',
          isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Full Name'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: _inputDecoration('e.g. Yeabsira Getachew'),
            validator: (v) => (v?.trim().isEmpty ?? true)
                ? 'Full name is required'
                : null,
          ),
          const SizedBox(height: 12),
          _buildLabel('Position'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _positionCtrl,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: _inputDecoration('e.g. Accountant'),
          ),
          const SizedBox(height: 12),
          _buildLabel('Initial Password'),
          const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: _inputDecoration(
                      'Min. 6 characters',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: const Color(0xFF9CA3AF),
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if ((v?.isEmpty ?? true)) {
                        return 'Password is required';
                      }
                      if (v!.length < 6) {
                        return 'Min. 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _generatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Generate'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel('Module Access'),
          const SizedBox(height: 8),
          for (var i = 0; i < Constants.modules.length; i += 2)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _moduleTile(Constants.modules[i])),
                if (i + 1 < Constants.modules.length)
                  Expanded(child: _moduleTile(Constants.modules[i + 1]))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Create Employee',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _moduleTile(MapEntry<String, String> module) {
    return CheckboxListTile(
      value: _selectedModules.contains(module.key),
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            _selectedModules.add(module.key);
          } else {
            _selectedModules.remove(module.key);
          }
        });
      },
      title: Text(
        module.value,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1D26),
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: const VisualDensity(vertical: -4),
      activeColor: const Color(0xFF2563EB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
