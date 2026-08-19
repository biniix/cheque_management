import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// A collection of reusable widgets and helper methods used throughout the app.
/// Keeps screens DRY and consistent.
class AppWidgets {
  AppWidgets._();

  // ─────────────────────────────────────────────────────────
  //  SECTION LABEL
  // ─────────────────────────────────────────────────────────
  static Widget sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: AppText.label(context),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  FORM FIELD
  // ─────────────────────────────────────────────────────────
  static Widget formField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(context, label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.fieldBg(context),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }



  // ─────────────────────────────────────────────────────────
  //  DROPDOWN
  // ─────────────────────────────────────────────────────────
  static Widget dropdown<T>(
    BuildContext context,
    String label, {
    T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(context, label),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldBg(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          hint: null,
          items: items,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PAYMENT METHOD PICKER (cash / cheque / mobile / bank / loan)
  // ─────────────────────────────────────────────────────────
  static Widget paymentMethodPicker(
    BuildContext context, {
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Constants.paymentMethods.map((m) {
        final isSelected = m.key == selected;
        return ChoiceChip(
          label: Text(
            m.value.split(' ').first, // short label: Cash, Cheque, Mobile...
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : AppColors.textPrimary(context),
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(m.key),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.fieldBg(context),
          checkmarkColor: Colors.white,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border(context),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  STATUS BADGE
  // ─────────────────────────────────────────────────────────
  static Widget statusBadge(BuildContext context, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statusBg(status, context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.statusText(status, context),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  STATUS PILL (for cheque leaf / detail views)
  // ─────────────────────────────────────────────────────────
  static Widget statusPill(BuildContext context, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.statusBg(status, context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppColors.statusIcon(status), size: 12, color: AppColors.statusText(status, context)),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.statusText(status, context),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  DETAIL ROW
  // ─────────────────────────────────────────────────────────
  static Widget detailRow(BuildContext context, String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppText.caption(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isMono
                  ? GoogleFonts.inconsolata(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    )
                  : GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  STAT CARD
  // ─────────────────────────────────────────────────────────
  static Widget statCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ACTION CARD (for quick actions / cheques screen)
  // ─────────────────────────────────────────────────────────
  static Widget actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? bgColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null ? color.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: onTap != null ? color : Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: onTap != null ? color : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  QUICK ACTION CARD (home screen)
  // ─────────────────────────────────────────────────────────
  static Widget quickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  EMPTY STATE
  // ─────────────────────────────────────────────────────────
  static Widget emptyState(BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? buttonLabel,
    VoidCallback? onButtonTap,
    Color iconColor = AppColors.primary,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.infoOf(context, bg: true),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppText.h4(context),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppText.body3(context),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onButtonTap,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(buttonLabel, style: AppText.button(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SEGMENTED TOGGLE (bearer/order, open/crossed, etc.)
  // ─────────────────────────────────────────────────────────
  static Widget segmentedToggle(
    BuildContext context, {
    required String option1,
    required String option2,
    required String desc1,
    required String desc2,
    required bool isSelected,
    required VoidCallback onToggle,
  }) {
    return Row(
      children: [
        Expanded(
          child: _toggleOption(
            context,
            option1,
            desc1,
            !isSelected,
            onToggle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _toggleOption(
            context,
            option2,
            desc2,
            isSelected,
            onToggle,
          ),
        ),
      ],
    );
  }

  static Widget _toggleOption(
    BuildContext context,
    String title,
    String subtitle,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF5B5BD6).withValues(alpha: 0.1)
              : AppColors.fieldBg(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF5B5BD6) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF5B5BD6) : AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: selected ? const Color(0xFF5B5BD6).withValues(alpha: 0.7) : AppColors.textTertiary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ICON CONTAINER (for list items)
  // ─────────────────────────────────────────────────────────
  static Widget iconBox({
    required IconData icon,
    required Color color,
    required Color bgColor,
    double size = 40,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size > 40 ? 14 : 12),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  INFO BANNER
  // ─────────────────────────────────────────────────────────
  static Widget infoBanner(BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
  }) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.infoOf(context, bg: true),
        borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppText.caption(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TOAST HELPERS
  // ─────────────────────────────────────────────────────────
  /// Compact toast anchored to the bottom-right corner instead of stretching
  /// full width. On narrow screens the left margin shrinks so it never overflows.
  static void showToast(BuildContext context, String message, {bool isSuccess = true}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    const toastWidth = 340.0;
    final leftMargin = screenWidth > toastWidth + 48
        ? screenWidth - toastWidth - 16
        : 16.0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(left: leftMargin, right: 16, bottom: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Opens [child] in a popup dialog with a blurred, darkened background and a
  /// fade + scale pop-in. Returns the dialog's result (from Navigator.pop).
  static Future<T?> showBlurredDialog<T>(
    BuildContext context,
    Widget child, {
    String barrierLabel = 'Dialog',
    double maxWidth = 540,
    double maxHeight = 620,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, anim, _, child) {
        return Stack(
          children: [
            // Full-screen blur behind the popup
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: const SizedBox.expand(),
              ),
            ),
            FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            ),
          ],
        );
      },
      pageBuilder: (context, _, __) => Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  CONFIRM DIALOG
  // ─────────────────────────────────────────────────────────
  /// Modern confirmation dialog: blurred, darkened backdrop with a fade +
  /// bounce pop-in, an icon badge, centered copy, and two full-width buttons
  /// (soft Cancel + accent Confirm). Pass [confirmColor] (e.g. red for
  /// destructive actions) and a matching [icon] to style it.
  static Future<bool> confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    Color? confirmColor,
    IconData icon = Icons.help_outline_rounded,
  }) async {
    final accent = confirmColor ?? AppColors.success;

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirmation',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, anim, _, child) {
        return Stack(
          children: [
            // Soft blur behind the popup
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: const SizedBox.expand(),
              ),
            ),
            FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            ),
          ],
        );
      },
      pageBuilder: (dialogContext, _, __) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: accent),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.h4(context),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppText.body3(context).copyWith(height: 1.5),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.chipBg(context),
                            foregroundColor: AppColors.textSecondary(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            confirmLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }

  // ─────────────────────────────────────────────────────────
  //  DATE PICKER (closes immediately on tap)
  // ─────────────────────────────────────────────────────────
  /// Opens a calendar date picker that closes right away when a date is
  /// tapped — no "OK" button needed. Returns the picked date, or null if the
  /// dialog was dismissed.
  static Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: CalendarDatePicker(
            initialDate: initialDate,
            firstDate: firstDate ?? DateTime(2020),
            lastDate: lastDate ?? DateTime(2100),
            onDateChanged: (picked) => Navigator.pop(dialogContext, picked),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  INTERNAL HELPERS
  // ─────────────────────────────────────────────────────────

}
