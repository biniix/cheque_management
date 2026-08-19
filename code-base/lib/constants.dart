import 'package:flutter/material.dart';

/// Legacy constants — maintained for backward compatibility.
/// New code should use `AppColors`, `AppText`, and `AppWidgets` from `design/`.
class Constants {
  static const String appName = 'Cheque Management';

  // ── Legacy color constants (delegate to AppColors) ──
  static const int primaryDark = 0xFF1A1D26;
  static const int primaryNavy = 0xFF2D3142;
  static const int accentBlue = 0xFF2563EB;
  static const int accentBlueLight = 0xFF60A5FA;
  static const int accentBlueDark = 0xFF1D4ED8;
  static const int sidebarBg = 0xFFFFFFFF;
  static const int mainBg = 0xFFF5F7FA;
  static const int cardBg = 0xFFFFFFFF;
  static const int successGreen = 0xFF059669;
  static const int successGreenBg = 0xFFD1FAE5;
  static const int dangerRed = 0xFFDC2626;
  static const int dangerRedBg = 0xFFFEE2E2;
  static const int warningAmber = 0xFFF59E0B;
  static const int textPrimary = 0xFF1A1D26;
  static const int textSecondary = 0xFF6B7280;
  static const int textTertiary = 0xFF9CA3AF;
  static const int borderLight = 0xFFE2E8F0;

  static const double sidebarWidth = 260;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;

  // Ethiopian Banks - maps short filename to full name
  static const Map<String, String> ethiopianBanks = {
    'cbe': 'Commercial Bank of Ethiopia',
    'dashen': 'Dashen Bank',
    'boa': 'Bank of Abyssinia',
    'awash': 'Awash Bank',
    'wegagen': 'Wegagen Bank',
    'nib': 'Nib International Bank',
    'zemen': 'Zemen Bank',
    'abay': 'Abay Bank',
    'lion': 'Lion International Bank',
    'oromia': 'Oromia Bank',
    'coop': 'Cooperative Bank of Oromia',
    'berhan': 'Berhan Bank',
    'siinqee': 'Siinqee Bank',
    'gadaa': 'Gadaa Bank',
    'addis': 'Addis International Bank',
    'bunna': 'Bunna Bank',
    'hibret': 'Hibret Bank',
    'amhara': 'Amhara Bank',
    'enat': 'Enat Bank',
    'global': 'Global Bank Ethiopia',
    'goh': 'Goh Betoch Bank',
    'hijra': 'Hijra Bank',
    'ahadu': 'Ahadu Bank',
    'sidama': 'Sidama Bank',
    'tsedey': 'Tsedey Bank',
    'tsehay': 'Tsehay Bank',
    'zamzam': 'ZamZam Bank',
    'rammis': 'Rammis Bank',
    'rays': 'Rays Bank',
    'siket': 'Siket Bank',
    'oib': 'Oromia International Bank',
    'mpesa': 'M-PESA',
    'telebirr': 'Telebirr',
  };

  static List<String> get bankKeys => ethiopianBanks.keys.toList();
  static List<String> get bankNames => ethiopianBanks.values.toList();

  /// Returns bank entries sorted alphabetically by bank name (A-Z)
  static List<MapEntry<String, String>> get sortedBankEntries {
    final entries = ethiopianBanks.entries.toList();
    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries;
  }

  static String getBankName(String key) => ethiopianBanks[key] ?? key;
  static String? getBankKey(String name) {
    return ethiopianBanks.entries
        .firstWhere(
          (e) => e.value == name,
          orElse: () => const MapEntry('', ''),
        )
        .key;
  }

  static String getBankLogoPath(String key) => 'assets/banks/$key.png';

  // ── App modules (used for employee access control) ──
  static const List<MapEntry<String, String>> modules = [
    MapEntry('home', 'Home'),
    MapEntry('accounts', 'Accounts'),
    MapEntry('customers', 'Customers'),
    MapEntry('transactions', 'Transactions'),
    MapEntry('transfers', 'Transfers'),
    MapEntry('deposits', 'Deposits'),
    MapEntry('cheques', 'Cheques'),
  ];

  // ── Payment methods (used on deposit / transfer forms) ──
  static const List<MapEntry<String, String>> paymentMethods = [
    MapEntry('cash', 'Cash'),
    MapEntry('cheque', 'Cheque'),
    MapEntry('mobile', 'Mobile (Telebirr / M-PESA)'),
    MapEntry('bank', 'Bank Transfer'),
    MapEntry('loan', 'Loan'),
  ];

  /// Human-readable label for a payment method key.
  static String paymentMethodLabel(String key) {
    for (final m in paymentMethods) {
      if (m.key == key) return m.value;
    }
    return key.isEmpty ? 'Cash' : key;
  }
}

// Utility gradient constants
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1D26), Color(0xFF2D3142)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Box shadow constants
class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 1),
        ),
      ];
}
