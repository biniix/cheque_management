import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer.dart';
import '../providers/customers_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../design/app_colors.dart';
import '../design/shared_widgets.dart';

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
                              onPressed: () async {
                                final result = await Navigator.pushNamed(context, '/add-customer');
                                if (result != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result as String),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                    ),
                                  );
                                }
                              },
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
                            onButtonTap: () async {
                              final result = await Navigator.pushNamed(context, '/add-customer');
                              if (result != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result as String),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                  ),
                                );
                              }
                            },
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.infoOf(context, bg: true),
                borderRadius: BorderRadius.circular(18)),
              child: Center(
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.bankName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Acct: ${customer.bankAccountNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
