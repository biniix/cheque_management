import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/bank_detail_screen.dart';
import 'screens/add_account_screen.dart';
import 'screens/add_customer_screen.dart';
import 'screens/deposit_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/create_chequebook_screen.dart';
import 'screens/write_cheque_screen.dart';
import 'screens/view_cheques_screen.dart';
import 'screens/print_cheque_screen.dart';
import 'screens/cheque_preview_screen.dart';
import 'screens/cheque_detail_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/customers_screen.dart';

class AppRouter {
  /// Creates a route with a smooth fade + slight scale transition.
  static Route<dynamic> _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      settings: settings,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _fadeRoute(const LoginScreen(), settings);
      case '/home':
        return _fadeRoute(const HomeScreen(), settings);
      case '/accounts':
        return _fadeRoute(const AccountsScreen(), settings);
      case '/bank-detail':
        final accountKey = settings.arguments as String? ?? '';
        return _fadeRoute(BankDetailScreen(accountKey: accountKey), settings);
      case '/add-account':
        return _fadeRoute(const AddAccountScreen(), settings);
      case '/customers':
        return _fadeRoute(const CustomersScreen(), settings);
      case '/add-customer':
        return _fadeRoute(const AddCustomerScreen(), settings);
      case '/deposit':
        return _fadeRoute(const DepositScreen(), settings);
      case '/transfer':
        return _fadeRoute(const TransferScreen(), settings);
      case '/create-chequebook':
        return _fadeRoute(const CreateChequebookScreen(), settings);
      case '/write-cheque':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final editId = args['edit'] as int?;
        return _fadeRoute(WriteChequeScreen(editChequeId: editId), settings);
      case '/view-cheques':
        return _fadeRoute(const ViewChequesScreen(), settings);
      case '/cheque-preview':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _fadeRoute(
          ChequePreviewScreen(
            chequebookId: args['chequebookId'] as int? ?? 0,
            payee: args['payee'] as String? ?? '',
            amount: args['amount'] as double? ?? 0.0,
            amountInWords: args['amountInWords'] as String? ?? '',
            date: DateTime.tryParse(args['date'] as String? ?? '') ?? DateTime.now(),
            isOrder: args['isOrder'] as bool? ?? false,
            crossed: args['crossed'] as bool? ?? false,
            editChequeId: args['editChequeId'] as int?,
          ),
          settings,
        );
      case '/cheque-detail':
        final chequeId = settings.arguments as int? ?? 0;
        return _fadeRoute(ChequeDetailScreen(chequeId: chequeId), settings);
      case '/print-cheque':
        final chequeId = settings.arguments as int? ?? 0;
        return _fadeRoute(PrintChequeScreen(chequeId: chequeId), settings);
      case '/transactions':
        return _fadeRoute(const TransactionsScreen(), settings);
      default:
        return _fadeRoute(const LoginScreen(), settings);
    }
  }
}
