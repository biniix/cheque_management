import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/audit_log_sheet.dart';
import '../design/shared_widgets.dart';
import 'add_account_screen.dart';
import 'edit_account_screen.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(accountsProvider.notifier).load());
  }

  Future<void> _openAddAccount() async {
    final result = await AppWidgets.showBlurredDialog<String>(
      context,
      const AddAccountForm(),
      barrierLabel: 'Add Account',
    );
    if (result != null && mounted) {
      AppWidgets.showToast(context, result);
    }
  }

  Future<void> _openEditAccount(Account account) async {
    final result = await AppWidgets.showBlurredDialog<String>(
      context,
      EditAccountForm(account: account),
      barrierLabel: 'Edit Account',
    );
    if (result != null && mounted) {
      AppWidgets.showToast(context, result);
    }
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, Account account) async {
    final confirmed = await AppWidgets.confirmDialog(
      context,
      title: 'Delete account?',
      message:
          '${account.bankName}${account.accountName.isNotEmpty ? ' (${account.accountName})' : ''} and all its transactions will be removed. This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: const Color(0xFFDC2626),
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    try {
      await ref.read(accountsProvider.notifier).deleteAccount(account.id);
      if (context.mounted) {
        AppWidgets.showToast(context, '${account.bankName} account deleted',
            isSuccess: false);
      }
    } catch (_) {
      if (context.mounted) {
        AppWidgets.showToast(
            context, 'Failed to delete account', isSuccess: false);
      }
    }
  }

  void _showAccountAudit(Account account) {
    final label = account.accountName.isNotEmpty
        ? '${account.bankName} · ${account.accountName}'
        : account.bankName;
    showAuditLogDialog(
      context,
      entity: 'account',
      entityId: account.id,
      title: label,
      entityIcon: Icons.account_balance_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final sortedAccounts = List<Account>.from(accounts)
      ..sort((a, b) => a.bankName.compareTo(b.bankName));
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/accounts'),
          Expanded(
            child: Column(
              children: [
                const AppHeader(title: 'Accounts'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${sortedAccounts.length} Bank Account${sortedAccounts.length != 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openAddAccount,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Account'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (sortedAccounts.isEmpty)
                          _buildEmptyState(context)
                        else
                          ...sortedAccounts.map((account) {
                            return _buildAccountCard(context, account, currencyFormat);
                          }),
                      ],
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

  Widget _buildAccountCard(
      BuildContext context, Account account, NumberFormat currencyFormat) {
    final bankName = account.bankName;
    final balance = account.balance;
    final isVisible = account.isVisible;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/bank-detail',
            arguments: account.id.toString(),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Row(
              children: [

                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          bankName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1D26),
                          ),
                        ),
                      ),
                      if (account.accountName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1D5DB),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              account.accountName,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: account.accountNumber));
                    AppWidgets.showToast(context, 'Account number copied');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isVisible
                            ? account.accountNumber
                            : '•' * account.accountNumber.length,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isVisible
                              ? const Color(0xFF374151)
                              : const Color(0xFF9CA3AF),
                          letterSpacing: isVisible ? 1.5 : 1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isVisible) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.copy_rounded,
                          size: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isVisible
                          ? 'ETB ${currencyFormat.format(balance)}'
                          : '••••••',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D26),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(accountsProvider.notifier)
                            .toggleVisibility(account.id);
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isVisible
                              ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                              : const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: 15,
                          color: isVisible
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                if (ref.watch(authProvider).isAdmin)
                  IconButton(
                    tooltip: 'View who did this',
                    icon: const Icon(Icons.info_outline_rounded,
                        size: 16, color: Color(0xFF2563EB)),
                    onPressed: () => _showAccountAudit(account),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                IconButton(
                  tooltip: 'Edit account',
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: Color(0xFF374151)),
                  onPressed: () => _openEditAccount(account),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  tooltip: 'Delete account',
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: Color(0xFFDC2626)),
                  onPressed: () => _confirmDeleteAccount(context, account),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.account_balance_rounded,
                size: 28, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          Text(
            'No bank accounts yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first bank account to get started',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openAddAccount,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Account'),
          ),
        ],
      ),
    );
  }
}
