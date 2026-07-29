import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

class BankPicker extends StatefulWidget {
  final String? selectedBankKey;
  final ValueChanged<String> onSelected;
  final String label;

  const BankPicker({
    super.key,
    this.selectedBankKey,
    required this.onSelected,
    this.label = 'Select Bank',
  });

  @override
  State<BankPicker> createState() => _BankPickerState();
}

class _BankPickerState extends State<BankPicker> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, String>> get _filteredBanks {
    final entries = Constants.sortedBankEntries;
    if (_searchQuery.isEmpty) return entries;
    final query = _searchQuery.toLowerCase();
    return entries.where((e) {
      return e.key.toLowerCase().contains(query) ||
          e.value.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1D26),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.selectedBankKey != null
                    ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                if (widget.selectedBankKey != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      Constants.getBankLogoPath(widget.selectedBankKey!),
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.account_balance,
                            size: 14, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.selectedBankKey != null
                        ? Constants.getBankName(widget.selectedBankKey!)
                        : 'Choose a bank',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: widget.selectedBankKey != null
                          ? const Color(0xFF1A1D26)
                          : const Color(0xFF9CA3AF),
                      fontWeight: widget.selectedBankKey != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),const Icon(Icons.expand_more_rounded, size: 20, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) {
          return StatefulBuilder(
            builder: (ctx, setSheetState) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Bank',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setSheetState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search banks...',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 14, color: const Color(0xFF9CA3AF)),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // List
                  Expanded(
                    child: _filteredBanks.isEmpty
                        ? Center(
                            child: Text('No banks found',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF9CA3AF))))
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: _filteredBanks.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 64),
                            itemBuilder: (ctx, index) {
                              final entry = _filteredBanks[index];
                              final isSelected =
                                  entry.key == widget.selectedBankKey;
                              return InkWell(
                                onTap: () {
                                  widget.onSelected(entry.key);
                                  Navigator.pop(ctx);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 4),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          Constants.getBankLogoPath(entry.key),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F6),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                                Icons.account_balance,
                                                size: 20,
                                                color: Color(0xFF9CA3AF)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: const Color(0xFF1A1D26),
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2563EB),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                              Icons.check_rounded,
                                              size: 16, color: Colors.white),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
