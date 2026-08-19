import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import '../../models/employee.dart';
import '../../providers/employees_provider.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/app_header.dart';
import '../../design/shared_widgets.dart';
import '../../utils/password_generator.dart';

class EditEmployeeScreen extends ConsumerStatefulWidget {
  final int employeeId;

  const EditEmployeeScreen({super.key, required this.employeeId});

  @override
  ConsumerState<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends ConsumerState<EditEmployeeScreen> {
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
                const AppHeader(title: 'Edit Employee'),
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
                          child: EditEmployeeForm(
                              employeeId: widget.employeeId),
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

/// The edit-employee form. Reusable: it is shown full-screen on its own route
/// and inside the blurred popup dialog opened from the employee list.
class EditEmployeeForm extends ConsumerStatefulWidget {
  final int employeeId;

  const EditEmployeeForm({super.key, required this.employeeId});

  @override
  ConsumerState<EditEmployeeForm> createState() => _EditEmployeeFormState();
}

class _EditEmployeeFormState extends ConsumerState<EditEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late Set<String> _selectedModules;
  bool _obscurePassword = true;
  bool _isActive = true;
  bool _saving = false;
  bool _loaded = false;

  Employee? _employee;

  @override
  void initState() {
    super.initState();
    _selectedModules = {};
    _load();
  }

  Future<void> _load() async {
    final employees = ref.read(employeesProvider);
    Employee? emp;
    if (employees.isEmpty) {
      await ref.read(employeesProvider.notifier).load();
      final loaded = ref.read(employeesProvider);
      for (final e in loaded) {
        if (e.id == widget.employeeId) {
          emp = e;
          break;
        }
      }
    } else {
      for (final e in employees) {
        if (e.id == widget.employeeId) {
          emp = e;
          break;
        }
      }
    }

    if (emp == null) {
      if (mounted) {
        AppWidgets.showToast(context, 'Employee not found', isSuccess: false);
        Navigator.pop(context);
      }
      return;
    }

    final employee = emp;
    setState(() {
      _employee = employee;
      _nameCtrl.text = employee.name;
      _positionCtrl.text = employee.position;
      _selectedModules = employee.moduleAccess.toSet();
      _isActive = employee.isActive;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _positionCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Fill the reset-password field with a random password (same generator as
  /// the add-employee form), so the admin can hand a strong password to an
  /// employee who forgot theirs.
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
      final emp = _employee;
      await ref.read(employeesProvider.notifier).updateEmployee(
            widget.employeeId,
            name: _nameCtrl.text.trim(),
            position: _positionCtrl.text.trim(),
            password: _passwordCtrl.text,
            moduleAccess: _selectedModules.toList(),
          );
      // Activate / deactivate if the status changed (admin is protected)
      if (emp != null && !emp.isAdmin && _isActive != emp.isActive) {
        await ref
            .read(employeesProvider.notifier)
            .toggleActive(widget.employeeId, _isActive);
      }
      if (!mounted) return;
      Navigator.pop(context, 'Employee updated successfully');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppWidgets.showToast(context, 'Failed to update employee',
          isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _employee == null) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final emp = _employee!;
    final isAdmin = emp.isAdmin;

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
            decoration: _inputDecoration('Full name'),
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

          _buildLabel('Reset Password'),
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
                      'Enter new password',
                      hintText: 'Enter new password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: const Color(0xFF9CA3AF),
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length < 6) {
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
          const SizedBox(height: 6),
          Text(
            'Leave empty to keep the current password',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('Account Status'),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isActive
                        ? 'Employee can sign in'
                        : 'Employee cannot sign in',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isActive
                          ? const Color(0xFF059669)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                if (isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Always active',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  )
                else
                  IconButton(
                    tooltip: _isActive
                        ? 'Deactivate account'
                        : 'Activate account',
                    icon: Icon(
                      Icons.check_circle_rounded,
                      size: 26,
                      color: _isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFF9CA3AF),
                    ),
                    onPressed: () => setState(() => _isActive = !_isActive),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('Module Access'),
          const SizedBox(height: 8),
          if (isAdmin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_outlined,
                      size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Admin has access to all modules',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            )
          else ...[
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
          ],
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                      'Save Changes',
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

  /// Single module checkbox used inside the two-column module access grid.
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

  InputDecoration _inputDecoration(
    String hint, {
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
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
