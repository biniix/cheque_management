import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../design/app_colors.dart';
import '../services/api_service.dart';

/// Shown right after login when the user is still on the admin-given password.
/// They must pick their own before using the app (back navigation is blocked).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Live-revalidate the strength checklist as the user types.
    _newCtrl.addListener(_onNewPasswordChanged);
  }

  void _onNewPasswordChanged() => setState(() {});

  bool get _minLenMet => _newCtrl.text.length >= 6;
  bool get _hasLetter => RegExp(r'[a-zA-Z]').hasMatch(_newCtrl.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newCtrl.text);
  bool get _newPasswordSatisfied =>
      _newCtrl.text.isNotEmpty && _minLenMet && _hasLetter && _hasNumber;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(_oldCtrl.text, _newCtrl.text);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final authState = ref.read(authProvider);
      final route = authState.isAdmin ? '/admin/employees' : '/home';
      Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Failed to change password. Check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Password change is mandatory — block system back / Android back button.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/logos/cheque_management.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Set a new password',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For security, choose a password only you know.\n'
                    'Your admin will not see it.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildField(
                            'Current password',
                            _oldCtrl,
                            obscure: _obscureOld,
                            onToggleObscure: () =>
                                setState(() => _obscureOld = !_obscureOld),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                            validator: (v) {
                              if (v?.isEmpty ?? true) {
                                return 'Current password is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _buildField(
                            'New password',
                            _newCtrl,
                            obscure: _obscureNew,
                            onToggleObscure: () =>
                                setState(() => _obscureNew = !_obscureNew),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                            validator: _validateNewPassword,
                          ),
                          const SizedBox(height: 6),
                          _buildRequirements(),
                          const SizedBox(height: 14),

                          _buildField(
                            'Confirm new password',
                            _confirmCtrl,
                            obscure: _obscureConfirm,
                            onToggleObscure: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) {
                              if (v?.isEmpty ?? true) {
                                return 'Please confirm your new password';
                              }
                              if (v != _newCtrl.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 14, color: AppColors.danger),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.dangerText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : Text(
                                      'Update Password',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Live password-strength checklist under the New password field.
  /// Gray while untouched → red until every requirement is met → green once met.
  Widget _buildRequirements() {
    final untouched = _newCtrl.text.isEmpty;
    final met = _newPasswordSatisfied;

    final Color iconColor = untouched
        ? const Color(0xFF9CA3AF)
        : met
            ? const Color(0xFF10B981)
            : const Color(0xFFDC2626);
    final Color textColor = untouched
        ? const Color(0xFF9CA3AF)
        : met
            ? const Color(0xFF10B981)
            : const Color(0xFFDC2626);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: untouched
            ? const Color(0xFFF5F7FA)
            : met
                ? const Color(0xFFECFDF5)
                : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: untouched
              ? const Color(0xFFF0F0F0)
              : met
                  ? const Color(0xFFA7F3D0)
                  : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        children: [
          _requirementRow('At least 6 characters', _minLenMet, iconColor, textColor),
          const SizedBox(height: 6),
          _requirementRow(
              'Contains a letter (a–z)', _hasLetter, iconColor, textColor),
          const SizedBox(height: 6),
          _requirementRow(
              'Contains a number (0–9)', _hasNumber, iconColor, textColor),
        ],
      ),
    );
  }

  Widget _requirementRow(
      String label, bool met, Color iconColor, Color textColor) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 13,
          color: iconColor,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: met ? FontWeight.w600 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  String? _validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'New password is required';
    if (v.length < 6) return 'Min. 6 characters';
    if (!RegExp(r'[a-zA-Z]').hasMatch(v)) {
      return 'Must contain at least one letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) {
      return 'Must contain at least one number';
    }
    return null;
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    required bool obscure,
    required VoidCallback onToggleObscure,
    required TextInputAction textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: null,
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 16,
                color: AppColors.textTertiary(context),
              ),
              onPressed: onToggleObscure,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            filled: true,
            fillColor: AppColors.fieldBg(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.danger, width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
