import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../providers/cheque_templates_provider.dart';
import '../utils/amount_to_words.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/cheque_renderer.dart';

class TemplateListScreen extends ConsumerStatefulWidget {
  const TemplateListScreen({super.key});

  @override
  ConsumerState<TemplateListScreen> createState() =>
      _TemplateListScreenState();
}

class _TemplateListScreenState extends ConsumerState<TemplateListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(chequeTemplatesProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(chequeTemplatesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/admin/template-list'),
          Expanded(
            child: Column(
              children: [
                const AppHeader(title: 'Cheque Templates'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${templates.length} template${templates.length != 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, '/admin/template-editor');
                              },
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                'Create Template',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: templates.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  itemCount: templates.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) =>
                                      _buildTemplateRow(templates[index]),
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

  Widget _buildTemplateRow(ChequeTemplateWithFields item) {
    final t = item.template;
    final fields = item.fields;
    final bankName = t.bankName.isNotEmpty
        ? t.bankName
        : Constants.getBankName(t.bankKey);
    final textFields =
        fields.where((f) => f.fieldType.name == 'text').length;
    final imageFields =
        fields.where((f) => f.fieldType.name == 'image').length;
    final w = (t.canvasWidth / 96 * 25.4).round();
    final h = (t.canvasHeight / 96 * 25.4).round();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showPreview(context, item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  Constants.getBankLogoPath(t.bankKey),
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        size: 18, color: Color(0xFF2563EB)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.templateName.isNotEmpty ? t.templateName : 'Untitled',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1D26),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bankName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              _infoBadge('$w × $h mm'),
              const SizedBox(width: 8),
              _infoBadge('$textFields text · $imageFields image'),
              const SizedBox(width: 8),
              Text(
                _formatDate(t.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Color(0xFF6B7280)),
                tooltip: 'Edit template',
                onPressed: () {
                  Navigator.pushNamed(context, '/admin/template-editor');
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Color(0xFFEF4444)),
                tooltip: 'Delete template',
                onPressed: () => _confirmDelete(context, t),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPreview(BuildContext context, ChequeTemplateWithFields item) {
    final t = item.template;
    final fields = item.fields;
    final bankName = t.bankName.isNotEmpty
        ? t.bankName
        : Constants.getBankName(t.bankKey);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        Constants.getBankLogoPath(t.bankKey),
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.account_balance_rounded,
                            size: 24,
                            color: Color(0xFF2563EB)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.templateName.isNotEmpty ? t.templateName : bankName,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1D26),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bankName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: Color(0xFF6B7280)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: ChequeRenderer(
                    template: t,
                    fields: fields,
                    bankKey: t.bankKey,
                    bankName: bankName,
                    branch: 'Head Office · Addis Ababa',
                    date: DateTime.now(),
                    payee: 'Tesfaye Belay',
                    amount: 15000,
                    amountInWords: amountToWords(15000),
                    chequeNumber: '000001',
                    status: 'Issued',
                    crossed: false,
                    isPreview: false,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
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

  Widget _infoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _confirmDelete(BuildContext context, dynamic t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete template?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Delete "${t.templateName.isNotEmpty ? t.templateName : Constants.getBankName(t.bankKey)}"? '
          'Cheques for this bank can no longer be written until a new template is created.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(chequeTemplatesProvider.notifier).deleteTemplate(t.id);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.dashboard_customize_outlined,
                size: 32, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          Text(
            'No templates yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a cheque template to get started',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/admin/template-editor');
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(
              'Create Template',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
