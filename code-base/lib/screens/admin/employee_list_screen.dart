import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import 'add_employee_screen.dart';
import 'edit_employee_screen.dart';
import '../../models/employee.dart';
import '../../providers/employees_provider.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/app_header.dart';
import '../../design/shared_widgets.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await ref.read(employeesProvider.notifier).load();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, Employee employee) async {
    final confirmed = await AppWidgets.confirmDialog(
      context,
      title: 'Remove employee?',
      message:
          '${employee.name} (${employee.employeeId}) will be removed from the system. This cannot be undone.',
      confirmLabel: 'Remove',
      confirmColor: const Color(0xFFDC2626),
      icon: Icons.delete_outline_rounded,
    );

    if (!confirmed) return;
    try {
      await ref.read(employeesProvider.notifier).deleteEmployee(employee.id);
      if (context.mounted) {
        AppWidgets.showToast(context, '${employee.name} removed',
            isSuccess: false);
      }
    } catch (_) {
      if (context.mounted) {
        AppWidgets.showToast(context, 'Failed to remove employee',
            isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? employees
        : employees
            .where((e) =>
                e.name.toLowerCase().contains(query) ||
                e.employeeId.toLowerCase().contains(query) ||
                e.position.toLowerCase().contains(query))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/admin/employees'),
          Expanded(
            child: Column(
              children: [
                const AppHeader(title: 'Employees'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              filtered.length == employees.length
                                  ? '${employees.length} Employee${employees.length != 1 ? 's' : ''}'
                                  : '${filtered.length} of ${employees.length}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openAddEmployee,
                              icon: const Icon(Icons.person_add_alt_1_rounded,
                                  size: 16),
                              label: const Text('Add New Employee'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: null,
                            prefixIcon: const Icon(Icons.search_rounded,
                                size: 18, color: Color(0xFF9CA3AF)),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: _loading
                              ? const Center(child: CircularProgressIndicator())
                              : filtered.isEmpty
                                  ? (employees.isEmpty
                                      ? Center(child: _buildEmptyState(context))
                                      : _buildNoResults(context))
                                  : ListView.separated(
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) =>
                                          _buildEmployeeCard(
                                              context, filtered[index]),
                                    ),
                        ),
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

  Future<void> _openEmployeeDialog(Widget form) async {
    final result = await AppWidgets.showBlurredDialog<String>(
      context,
      form,
      barrierLabel: 'Employee form',
    );
    if (result != null && mounted) {
      AppWidgets.showToast(context, result);
    }
  }

  void _openAddEmployee() {
    _openEmployeeDialog(const AddEmployeeForm());
  }

  void _openEditEmployee(Employee emp) {
    _openEmployeeDialog(EditEmployeeForm(employeeId: emp.id));
  }

  Widget _buildEmployeeCard(BuildContext context, Employee emp) {
    final isAdmin = emp.isAdmin;

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      emp.name,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1D26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? const Color(0xFFDBEAFE)
                          : emp.isActive
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      emp.employeeId,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isAdmin
                            ? const Color(0xFF2563EB)
                            : emp.isActive
                                ? const Color(0xFF059669)
                                : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: emp.isActive
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                emp.isActive ? 'Active' : 'Inactive',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: emp.isActive
                      ? const Color(0xFF059669)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),

            IconButton(
              tooltip: 'View details',
              icon: const Icon(Icons.info_outline_rounded,
                  size: 16, color: Color(0xFF374151)),
              onPressed: () => _showDetail(context, emp),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
            ),
            IconButton(
              tooltip: 'Edit employee',
              icon: const Icon(Icons.edit_outlined,
                  size: 16, color: Color(0xFF374151)),
              onPressed: () => _openEditEmployee(emp),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),

            if (!isAdmin)
              IconButton(
                tooltip: 'Remove employee',
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: Color(0xFFDC2626)),
                onPressed: () => _confirmDelete(context, emp),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Employee emp) {
    final isAdmin = emp.isAdmin;
    final modules =
        Constants.modules.where((m) => emp.canAccess(m.key)).toList();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              emp.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1D26),
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? const Color(0xFFDBEAFE)
                                  : emp.isActive
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              emp.employeeId,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isAdmin
                                    ? const Color(0xFF2563EB)
                                    : emp.isActive
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow('Employee ID', emp.employeeId),
                _detailRow(
                    'Position', emp.position.isNotEmpty ? emp.position : '—'),
                _detailRow('Role', isAdmin ? 'Admin' : 'Employee'),
                _detailRow('Status', emp.isActive ? 'Active' : 'Inactive'),
                _detailRow('Member since',
                    DateFormat('MMM d, yyyy').format(emp.createdAt)),
                if (modules.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Module Access',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final m in modules)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            m.value.split(' / ').first,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 40, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(
            'No employees match your search',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
        ],
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
            child: const Icon(Icons.group_add_rounded,
                size: 28, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          Text(
            'No employees yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first employee to get started',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
