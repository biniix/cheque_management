import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

/// A bank field with autocomplete: as the user types, matching banks from the
/// predefined list pop up below the field. If no known bank matches, whatever
/// the user typed is kept — so new/custom banks can be added.
class BankPicker extends StatefulWidget {
  /// Currently selected/typed bank name (known or custom).
  final String? selectedBankName;

  /// Called with the bank name (null when the field is emptied).
  final ValueChanged<String?> onChanged;

  final String label;

  const BankPicker({
    super.key,
    this.selectedBankName,
    required this.onChanged,
    this.label = 'Bank',
  });

  @override
  State<BankPicker> createState() => _BankPickerState();
}

class _BankPickerState extends State<BankPicker> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedBankName ?? '');
  }

  @override
  void didUpdateWidget(BankPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBankName != widget.selectedBankName) {
      _controller.text = widget.selectedBankName ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(String text) {
    final value = text.trim();
    widget.onChanged(value.isEmpty ? null : value);
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
        Autocomplete<MapEntry<String, String>>(
          displayStringForOption: (entry) => entry.value,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) {
              return const Iterable<MapEntry<String, String>>.empty();
            }
            return Constants.sortedBankEntries.where((entry) =>
                entry.value.toLowerCase().contains(query) ||
                entry.key.toLowerCase().contains(query));
          },
          onSelected: (entry) => _commit(entry.value),
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              onChanged: (v) => _commit(v),
              onSubmitted: (_) => onFieldSubmitted(),
              textInputAction: TextInputAction.next,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A1D26),
              ),
              decoration: InputDecoration(
                hintText: null,
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF2563EB), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: options.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 64),
                    itemBuilder: (context, index) {
                      final entry = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(entry),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  Constants.getBankLogoPath(entry.key),
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                        Icons.account_balance,
                                        size: 14,
                                        color: Color(0xFF9CA3AF)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1A1D26),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
