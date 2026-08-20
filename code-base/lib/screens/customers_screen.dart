import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer.dart';
import '../providers/customers_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/audit_log_sheet.dart';
import '../design/app_colors.dart';
import '../design/shared_widgets.dart';
import 'add_customer_screen.dart';
import 'edit_customer_screen.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(customersProvider.notifier).load());
  }

  Future<void> _openAddCustomer() async {
    final result = await AppWidgets.showBlurredDialog<String>(
      context,
      const AddCustomerForm(),
      barrierLabel: 'Add Customer',
    );
    if (result != null && mounted) {
      AppWidgets.showToast(context, result);
    }
  }

  Future<void> _openEditCustomer(Customer customer) async {
    final result = await AppWidgets.showBlurredDialog<String>(
      context,
      EditCustomerForm(customer: customer),
      barrierLabel: 'Edit Customer',
    );
    if (result != null && mounted) {
      AppWidgets.showToast(context, result);
    }
  }

  void _showCustomerAudit(Customer customer) {
    showAuditLogDialog(
      context,
      entity: 'customer',
      entityId: customer.id,
      title: customer.name,
      entityIcon: Icons.people_rounded,
    );
  }

  Future<void> _confirmDeleteCustomer(
      BuildContext context, Customer customer) async {
    final confirmed = await AppWidgets.confirmDialog(
      context,
      title: 'Delete customer?',
      message:
          '${customer.name} will be removed from the system. This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: const Color(0xFFDC2626),
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    try {
      await ref.read(customersProvider.notifier).deleteCustomer(customer.id);
      if (context.mounted) {
        AppWidgets.showToast(
            context, '${customer.name} removed', isSuccess: false);
      }
    } catch (_) {
      if (context.mounted) {
        AppWidgets.showToast(
            context, 'Failed to remove customer', isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final sortedCustomers = List<Customer>.from(customers)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/customers'),
          Expanded(
            child: Column(
              children: [
                const AppHeader(title: 'Customers'),
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
                              '${sortedCustomers.length} Customer${sortedCustomers.length != 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openAddCustomer,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Customer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
        ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (sortedCustomers.isEmpty)
                          AppWidgets.emptyState(
                            context,
                            icon: Icons.people_rounded,
                            title: 'No customers yet',
                            subtitle: 'Add your first customer to get started',
                            buttonLabel: 'Add Customer',
                            onButtonTap: _openAddCustomer,
                          )
                        else
                          ...sortedCustomers.map((customer) {
                            return _buildCustomerCard(context, customer);
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

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [

            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.infoOf(context, bg: true),
                borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                customer.name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            if (ref.watch(authProvider).isAdmin)
              IconButton(
                tooltip: 'View who did this',
                icon: const Icon(Icons.info_outline_rounded,
                    size: 15, color: Color(0xFF2563EB)),
                onPressed: () => _showCustomerAudit(customer),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            IconButton(
              tooltip: 'Edit customer',
              icon: const Icon(Icons.edit_outlined,
                  size: 15, color: Color(0xFF374151)),
              onPressed: () => _openEditCustomer(customer),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
            IconButton(
              tooltip: 'Delete customer',
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 15, color: Color(0xFFDC2626)),
              onPressed: () => _confirmDeleteCustomer(context, customer),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
          ],
        ),
      ),
    );
  }
}
