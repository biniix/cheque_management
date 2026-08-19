<div align="center">

# 📒 Cheque Management

**Personal Ledger & Cheque Management System**

A modern Flutter application for managing bank accounts, writing cheques, tracking transactions, and organizing customer information — built for Ethiopian banks.

[![Flutter](https://img.shields.io/badge/Flutter-3.44%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

</div>

---

## ✨ Features

### 🔒 PIN Protection
- Secure your ledger with a personal passcode
- AES-hashed authentication using Dart's `crypto` package

### 💾 Local-First Storage
- All data stored locally on your device via SharedPreferences
- No internet connection required — works fully offline

### 🏦 Multi-Bank Account Management
- Add and manage multiple bank accounts
- Track real-time balances across all accounts
- View account details with bank logos
- 30+ Ethiopian banks supported out of the box

### 📝 Cheque Management
- **Write cheques** — Create and customize cheques with payee, amount, and date
- **Preview before printing** — See exactly how the cheque will look
- **Print cheques** — Generate printable PDF versions
- **Bearer or Order** — Support for both bearer and order cheques
- **Crossed cheques** — Option to mark cheques as crossed ("A/C Payee Only")
- **Track status** — Monitor cheques as Issued, Cleared, Stale, or Void
- **Post-dated & stale detection** — Automatic identification of post-dated and stale cheques
- **Amount in words** — Auto-converts numeric amounts to words

### 📒 Cheque Books
- Create and organize cheque books for each account
- Track cheque numbers within each book
- View all cheques belonging to a book

### 💰 Transactions
- **Deposits** — Record money coming into your accounts
- **Transfers** — Move money between your accounts
- **Cheque transactions** — Automatically linked to issued cheques
- **Transaction history** — Filterable and searchable transaction list

### 👥 Customer Management
- Store customer details with bank information
- Link customers to transactions and cheques

### 📊 Dashboard & Analytics
- Beautiful home dashboard with account overview
- Interactive charts powered by `fl_chart`
- Quick access to all major features

### 🎨 Modern UI/UX
- Clean, professional design with smooth transitions
- Responsive layout with sidebar navigation
- Shimmer loading effects
- Custom theming and typography

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0+)
- Dart 3.0+
- Android Studio / VS Code

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/my-ledger.git
cd my-ledger

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build for Web

```bash
flutter build web
```

### Build for Android

```bash
flutter build apk
```

---

## 📁 Project Structure

```
cheque_management/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── router.dart                  # Route definitions with fade transitions
│   ├── theme.dart                   # App theme configuration
│   ├── constants.dart               # App constants & Ethiopian bank list
│   │
│   ├── models/                      # Data models
│   │   ├── account.dart             # Bank account model
│   │   ├── audit_log.dart           # Audit log entry model
│   │   ├── cheque.dart              # Cheque model
│   │   ├── cheque_book.dart         # Cheque book model
│   │   ├── customer.dart            # Customer model
│   │   ├── employee.dart            # Employee model
│   │   └── transaction.dart         # Transaction model
│   │
│   ├── providers/                   # State management (Riverpod)
│   │   ├── accounts_provider.dart
│   │   ├── audit_logs_provider.dart
│   │   ├── auth_provider.dart
│   │   ├── cheques_provider.dart
│   │   ├── cheque_books_provider.dart
│   │   ├── customers_provider.dart
│   │   ├── employees_provider.dart
│   │   └── transactions_provider.dart
│   │
│   ├── screens/                     # App screens
│   │   ├── login_screen.dart
│   │   ├── change_password_screen.dart
│   │   ├── home_screen.dart
│   │   ├── accounts_screen.dart
│   │   ├── add_account_screen.dart
│   │   ├── edit_account_screen.dart
│   │   ├── bank_detail_screen.dart
│   │   ├── customers_screen.dart
│   │   ├── add_customer_screen.dart
│   │   ├── edit_customer_screen.dart
│   │   ├── deposit_screen.dart
│   │   ├── transfer_screen.dart
│   │   ├── create_chequebook_screen.dart
│   │   ├── write_cheque_screen.dart
│   │   ├── view_cheques_screen.dart
│   │   ├── cheque_preview_screen.dart
│   │   ├── cheque_detail_screen.dart
│   │   ├── print_cheque_screen.dart
│   │   ├── statement_screen.dart
│   │   ├── transactions/
│   │   │   └── transactions_screen.dart
│   │   └── admin/
│   │       ├── employee_list_screen.dart
│   │       ├── add_employee_screen.dart
│   │       ├── edit_employee_screen.dart
│   │       └── audit_logs_screen.dart
│   │
│   ├── widgets/                     # Reusable widgets
│   │   ├── app_header.dart
│   │   ├── sidebar.dart
│   │   ├── bank_picker.dart
│   │   ├── cheque_leaf.dart
│   │   └── audit_log_sheet.dart
│   │
│   ├── services/                    # Services & API
│   │   ├── api_service.dart
│   │   └── local_store.dart
│   │
│   ├── design/                      # Design system
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── shared_widgets.dart
│   │
│   └── utils/                       # Utilities
│       ├── number_to_words.dart
│       ├── overdraft_dialog.dart
│       └── password_generator.dart
│
├── assets/
│   ├── banks/                       # Bank logo images (PNG)
│   └── logos/                       # App logos
│
├── test/
│   └── widget_test.dart
│
└── pubspec.yaml                     # Dependencies & configuration
```

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter** | Cross-platform UI framework |
| **Dart** | Programming language |
| **Riverpod** | State management |
| **SharedPreferences** | Local data persistence |
| **`fl_chart`** | Interactive charts & graphs |
| **`pdf` & `printing`** | Cheque PDF generation & printing |
| **Google Fonts** | Typography |
| **Shimmer** | Loading animations |
| **`http`** | API communication |
| **`intl`** | Date & number formatting |

---

## 🏦 Supported Banks

Cheque Management comes with built-in support for **30+ Ethiopian banks** including:

| # | Bank |
|---|------|
| 1 | Commercial Bank of Ethiopia (CBE) |
| 2 | Dashen Bank |
| 3 | Bank of Abyssinia |
| 4 | Awash Bank |
| 5 | Wegagen Bank |
| 6 | Nib International Bank |
| 7 | Zemen Bank |
| 8 | Cooperative Bank of Oromia |
| 9 | Oromia Bank |
| 10 | Abay Bank |
| ... | *(and 20+ more)* |

Also supports mobile money services: **M-PESA** & **Telebirr** 📱

---

## 🧪 Running Tests

```bash
flutter test
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">
  Made with ❤️ using Flutter
</div>
