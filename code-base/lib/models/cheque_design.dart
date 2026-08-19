import 'package:flutter/material.dart';

/// A per-bank (and optional per-denomination) cheque design template,
/// matching the `/cheque-designs` API response.
///
/// Every getter falls back to the current default design, so a template with
/// only a few fields set still renders correctly.
class ChequeDesign {
  final int id;
  final String bankKey;
  final String denomination; // '' = applies to all leaves of this bank
  final Map<String, dynamic> layout;

  ChequeDesign({
    required this.id,
    required this.bankKey,
    this.denomination = '',
    this.layout = const {},
  });

  factory ChequeDesign.fromJson(Map<String, dynamic> json) => ChequeDesign(
        id: json['id'] as int,
        bankKey: json['bank_key'] as String? ?? '',
        denomination: json['denomination'] as String? ?? '',
        layout: (json['layout'] as Map<String, dynamic>?) ?? const {},
      );

  Map<String, dynamic> _map(String key) =>
      (layout[key] as Map<String, dynamic>?) ?? const {};

  /// Logo placement: 'left' | 'center' | 'right' (default 'left').
  String get logoPosition =>
      (_map('logo')['position'] as String?) ?? 'left';

  double get logoSize => ((_map('logo')['size'] as num?) ?? 36).toDouble();

  Color get primaryColor => _color(layout, 'colors', 'primary', const Color(0xFF1A1D26));

  Color get accentColor => _color(layout, 'colors', 'accent', const Color(0xFF2563EB));

  Color get mutedColor => _color(layout, 'colors', 'muted', const Color(0xFF9CA3AF));

  Color get borderColor => _color(layout, 'colors', 'border', const Color(0xFF1A1D26));

  bool get showHeadOffice =>
      (_map('header')['show_head_office'] as bool?) ?? true;

  /// Cheque number placement: 'right' | 'left' | 'below' (default 'right').
  String get chequeNumberPosition =>
      (_map('cheque_number')['position'] as String?) ?? 'right';

  Alignment get amountBoxAlign {
    switch (_map('amount_box')['align'] as String?) {
      case 'left':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      default:
        return Alignment.centerRight;
    }
  }

  bool get showMicr => (_map('micr')['show'] as bool?) ?? false;

  String get micrText =>
      (_map('micr')['text'] as String?) ??
      '0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0';

  bool get showStatusPill => (_map('status_pill')['show'] as bool?) ?? true;

  static Color _color(
      Map<String, dynamic> root, String section, String key, Color fallback) {
    final hex = (_mapOf(root, section))[key] as String?;
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(0xFF000000 | value);
  }

  static Map<String, dynamic> _mapOf(Map<String, dynamic> root, String key) =>
      (root[key] as Map<String, dynamic>?) ?? const {};
}
