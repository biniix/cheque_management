import 'dart:convert';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/cheque_template.dart';
import '../models/cheque_template_field.dart';
import '../providers/cheque_templates_provider.dart';
import '../utils/amount_to_words.dart';
import '../widgets/cheque_renderer.dart';

/// Admin cheque template editor, laid out like a design tool:
///
///   FIELDS panel (left)  ·  big design canvas (center)  ·  PROPERTIES (right)
///
/// Clicking a field type in the FIELDS panel (or tapping a field directly on
/// the canvas) selects it; the PROPERTIES panel edits position, size and
/// typography live on the canvas — the same [ChequeRenderer] used when writing
/// and printing real cheques.
class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({super.key});

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  // ── Template-level state ──
  String _bankKey = '';
  final _templateNameCtrl = TextEditingController();
  final _canvasWidthCtrl = TextEditingController(text: '816');
  final _canvasHeightCtrl = TextEditingController(text: '336');
  String _backgroundPath = '';
  bool _useBankLogoBackground = false;

  // ── Field / selection state ──
  List<ChequeTemplateField> _fields = [];
  int? _selectedFieldId;
  int? _editingTemplateId;
  int _nextFieldId = -1; // negative ids for unsaved rows

  // ── Canvas state ──
  double _zoom = 1.0;
  bool _showFilled = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chequeTemplatesProvider.notifier).load());
  }

  @override
  void dispose() {
    _templateNameCtrl.dispose();
    _canvasWidthCtrl.dispose();
    _canvasHeightCtrl.dispose();
    super.dispose();
  }

  String get _bankName => Constants.getBankName(_bankKey);

  double get _canvasWidth => double.tryParse(_canvasWidthCtrl.text) ?? 816;
  double get _canvasHeight => double.tryParse(_canvasHeightCtrl.text) ?? 336;

  ChequeTemplateField? get _selectedField {
    for (final f in _fields) {
      if (f.id == _selectedFieldId) return f;
    }
    return null;
  }

  void _resetForm() {
    setState(() {
      _editingTemplateId = null;
      _bankKey = '';
      _templateNameCtrl.clear();
      _canvasWidthCtrl.text = '816';
      _canvasHeightCtrl.text = '336';
      _backgroundPath = '';
      _useBankLogoBackground = true;
      _fields = [];
      _selectedFieldId = null;
      _nextFieldId = -1;
    });
  }

  void _loadForEdit(ChequeTemplateWithFields item) {
    setState(() {
      _editingTemplateId = item.template.id;
      _bankKey = item.template.bankKey;
      _templateNameCtrl.text = item.template.templateName;
      _canvasWidthCtrl.text = item.template.canvasWidth.toStringAsFixed(0);
      _canvasHeightCtrl.text = item.template.canvasHeight.toStringAsFixed(0);
      _backgroundPath = item.template.backgroundImagePath;
      _useBankLogoBackground = !item.template.backgroundIsDataUri;
      _fields = List.of(item.fields);
      _selectedFieldId = _fields.isNotEmpty ? _fields.first.id : null;
      _nextFieldId = -1;
      _zoom = 1.0;
    });
  }

  ChequeTemplateField _newField(
    ChequeTemplateFieldName name,
    ChequeTemplateFieldType type, {
    double x = 40,
    double y = 40,
    double fontSize = 13,
    String fontWeight = 'normal',
  }) {
    final id = _nextFieldId--;
    if (type == ChequeTemplateFieldType.image) {
      return ChequeTemplateField.image(
        id: id,
        templateId: _editingTemplateId ?? 0,
        fieldName: name,
        x: x,
        y: y,
        imageWidth: name == ChequeTemplateFieldName.bankLogo ? 48 : 110,
        imageHeight: name == ChequeTemplateFieldName.bankLogo ? 48 : null,
      );
    }
    return ChequeTemplateField.text(
      id: id,
      templateId: _editingTemplateId ?? 0,
      fieldName: name,
      x: x,
      y: y,
      fontSize: fontSize,
      fontWeight: fontWeight,
      alignment: 'left',
      maxWidth: name == ChequeTemplateFieldName.amountWords ? 420 : null,
    );
  }

  void _addDefaultFields() {
    // Y values are stored as distance from bottom of canvas.
    // Canvas default height is 336.
    final h = _canvasHeight;
    setState(() {
      _fields = [
        _newField(ChequeTemplateFieldName.bankLogo,
            ChequeTemplateFieldType.image,
            x: 32, y: h - 26),
        _newField(ChequeTemplateFieldName.bankName,
            ChequeTemplateFieldType.text,
            x: 96, y: h - 24,
            fontSize: 18, fontWeight: 'w700'),
        _newField(ChequeTemplateFieldName.branch,
            ChequeTemplateFieldType.text,
            x: 96, y: h - 50,
            fontSize: 10),
        _newField(ChequeTemplateFieldName.date, ChequeTemplateFieldType.text,
            x: 640, y: h - 30),
        _newField(ChequeTemplateFieldName.payee, ChequeTemplateFieldType.text,
            x: 40, y: h - 118),
        _newField(ChequeTemplateFieldName.amountWords,
            ChequeTemplateFieldType.text,
            x: 40, y: h - 156),
        _newField(ChequeTemplateFieldName.amountNumeric,
            ChequeTemplateFieldType.text,
            x: 620, y: h - 118, fontSize: 16, fontWeight: 'w700'),
        _newField(ChequeTemplateFieldName.digitalStamp,
            ChequeTemplateFieldType.image,
            x: 660, y: h - 250),
      ];
      _selectedFieldId = _fields.isNotEmpty ? _fields.first.id : null;
    });
  }

  /// Adds a field type from the FIELDS panel — or selects it if it already
  /// exists on the canvas.
  void _addFieldType(ChequeTemplateFieldName name) {
    final existing = _fields.where((f) => f.fieldName == name).firstOrNull;
    if (existing != null) {
      setState(() => _selectedFieldId = existing.id);
      return;
    }
    final isImage = name == ChequeTemplateFieldName.bankLogo ||
        name == ChequeTemplateFieldName.digitalStamp;
    final f = _newField(
      name,
      isImage ? ChequeTemplateFieldType.image : ChequeTemplateFieldType.text,
      x: 60,
      y: 70 + (_fields.length * 10),
    );
    setState(() {
      _fields = [..._fields, f];
      _selectedFieldId = f.id;
    });
  }

  void _updateField(ChequeTemplateField updated) {
    setState(() {
      _fields = [
        for (final f in _fields) f.id == updated.id ? updated : f,
      ];
    });
  }

  void _removeSelectedField() {
    final id = _selectedFieldId;
    if (id == null) return;
    setState(() {
      _fields = _fields.where((f) => f.id != id).toList();
      _selectedFieldId = null;
    });
  }

  Future<void> _pickBackgroundImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    final mime = _mimeType(file.name);
    if (!mounted) return;
    setState(() {
      _backgroundPath = 'data:$mime;base64,$base64';
      _useBankLogoBackground = false;
    });
  }

  String _mimeType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/png';
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_bankKey.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Choose a bank first')));
      return;
    }
    if (_templateNameCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Enter a template name')));
      return;
    }
    if (_fields.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Add at least one field')));
      return;
    }

    final background = _useBankLogoBackground || _backgroundPath.isEmpty
        ? Constants.getBankLogoPath(_bankKey)
        : _backgroundPath;

    final template = ChequeTemplate(
      id: _editingTemplateId ?? 0,
      bankKey: _bankKey,
      bankName: _bankName,
      templateName: _templateNameCtrl.text.trim(),
      backgroundImagePath: background,
      canvasWidth: _canvasWidth,
      canvasHeight: _canvasHeight,
    );

    await ref
        .read(chequeTemplatesProvider.notifier)
        .saveTemplate(template, _fields);

    if (!mounted) return;
    // Reload the just-saved template (fresh field ids) into the editor.
    final templates = ref.read(chequeTemplatesProvider);
    final saved = templates
        .where((t) => t.template.bankKey == _bankKey)
        .lastOrNull;
    if (saved != null) _loadForEdit(saved);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Template "${template.templateName}" saved for ${template.bankName}',
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteTemplate() async {
    final current = ref
        .read(chequeTemplatesProvider)
        .where((t) => t.template.id == _editingTemplateId)
        .firstOrNull;
    if (current == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete template?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Delete "${current.template.templateName}" for ${current.template.bankName}? '
          'Cheques for this bank can no longer be written until a new template '
          'is created.',
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
      await ref
          .read(chequeTemplatesProvider.notifier)
          .deleteTemplate(current.template.id);
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(chequeTemplatesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Cheque Template Editor',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1D26),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1D26)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _setupBar(templates),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _fieldsPanel(),
                  const SizedBox(width: 10),
                  _canvasArea(),
                  const SizedBox(width: 10),
                  _propertiesPanel(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ── Top setup bar: bank, name, canvas size, background ──
  Widget _setupBar(List<ChequeTemplateWithFields> templates) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _setupDropdown<String>(
            value: _bankKey.isEmpty ? null : _bankKey,
            hint: 'Bank',
            width: 200,
            items: {
              for (final e in Constants.sortedBankEntries) e.key: e.value,
            },
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _bankKey = v;
                if (_fields.isEmpty) _addDefaultFields();
              });
            },
          ),
          SizedBox(
            width: 190,
            child: TextField(
              controller: _templateNameCtrl,
              style: GoogleFonts.inter(fontSize: 12),
              decoration: _setupInputDecoration('Template name'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            width: 170,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _canvasWidthCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: _setupInputDecoration('W px'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('×',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF9CA3AF))),
                ),
                Expanded(
                  child: TextField(
                    controller: _canvasHeightCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: _setupInputDecoration('H px'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          _chip('White', !_useBankLogoBackground && _backgroundPath.isEmpty, () {
            setState(() {
              _useBankLogoBackground = false;
              _backgroundPath = '';
            });
          }),
          _chip('Bank logo', _useBankLogoBackground, () {
            setState(() {
              _useBankLogoBackground = true;
              _backgroundPath = Constants.getBankLogoPath(_bankKey);
            });
          }),
          _chip('Upload scan', !_useBankLogoBackground && _backgroundPath.isNotEmpty, _pickBackgroundImage),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 19, color: Color(0xFFEF4444)),
            tooltip: 'Delete template',
            onPressed: _editingTemplateId != null ? _deleteTemplate : null,
          ),
        ],
      ),
    );
  }

  Widget _setupDropdown<T>({
    required T? value,
    required String hint,
    required double width,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: _setupInputDecoration(hint),
        items: items.entries
            .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: GoogleFonts.inter(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: (v) => onChanged(v),
      ),
    );
  }

  InputDecoration _setupInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                selected ? const Color(0xFF2563EB) : const Color(0xFFE8ECF0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  // ── Left FIELDS panel ──
  Widget _fieldsPanel() {
    const types = [
      ChequeTemplateFieldName.bankName,
      ChequeTemplateFieldName.bankLogo,
      ChequeTemplateFieldName.date,
      ChequeTemplateFieldName.payee,
      ChequeTemplateFieldName.amountNumeric,
      ChequeTemplateFieldName.amountWords,
      ChequeTemplateFieldName.branch,
      ChequeTemplateFieldName.digitalStamp,
    ];
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'FIELDS',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: types.map(_fieldTypeTile).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldTypeTile(ChequeTemplateFieldName name) {
    final exists = _fields.where((f) => f.fieldName == name).isNotEmpty;
    final selected = _selectedField?.fieldName == name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _addFieldType(name),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(
                  Icons.text_fields_rounded,
                  size: 16,
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                ),
                if (exists)
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: Color(0xFF10B981)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Central design canvas ──
  Widget _canvasArea() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            _canvasToolbar(),
            Expanded(
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasW = _canvasWidth;
                    final canvasH = _canvasHeight;
                    final baseScale = math.min(
                      (constraints.maxWidth - 48) / canvasW,
                      (constraints.maxHeight - 32) / canvasH,
                    );
                    final scale = math.max(baseScale * _zoom, 0.05);
                    return Center(
                      child: SizedBox(
                        width: canvasW * scale,
                        height: canvasH * scale,
                        child: ChequeRenderer(
                          template: _previewTemplate(),
                          fields: _fields,
                          bankKey: _bankKey,
                          bankName: _bankName,
                          branch: 'Head Office · Addis Ababa',
                          date: DateTime.now(),
                          payee: _showFilled ? 'Biniyam Teklu' : '',
                          amount: _showFilled ? 15000.50 : 0,
                          amountInWords: _showFilled
                              ? amountToWords(15000.50)
                              : '',
                          status: 'Issued',
                          crossed: false,
                          isPreview: !_showFilled,
                          selectedFieldId: _selectedFieldId,
                          onFieldTap: (f) =>
                              setState(() => _selectedFieldId = f.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ChequeTemplate _previewTemplate() => ChequeTemplate(
        id: 0,
        bankKey: _bankKey,
        bankName: _bankName,
        templateName: _templateNameCtrl.text.trim(),
        backgroundImagePath: _useBankLogoBackground && _bankKey.isNotEmpty
            ? Constants.getBankLogoPath(_bankKey)
            : _backgroundPath,
        canvasWidth: _canvasWidth,
        canvasHeight: _canvasHeight,
      );

  Widget _canvasToolbar() {
    final w = (_canvasWidth / 96 * 25.4).round();
    final h = (_canvasHeight / 96 * 25.4).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_bankKey.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_bankName.toUpperCase()} · $w × $h mm',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2563EB),
                  letterSpacing: 0.4,
                ),
              ),
            )
          else
            Text(
              'NO BANK SELECTED',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.zoom_out_rounded,
                size: 20, color: Color(0xFF374151)),
            tooltip: 'Zoom out',
            onPressed: () =>
                setState(() => _zoom = math.max(0.4, _zoom - 0.25)),
          ),
          Text(
            '${(_zoom * 100).round()}%',
            style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF374151)),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded,
                size: 20, color: Color(0xFF374151)),
            tooltip: 'Zoom in',
            onPressed: () =>
                setState(() => _zoom = math.min(2.5, _zoom + 0.25)),
          ),
          IconButton(
            icon: Icon(
              _showFilled ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              size: 20,
              color: _showFilled
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF374151),
            ),
            tooltip: 'Toggle filled preview',
            onPressed: () => setState(() => _showFilled = !_showFilled),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/admin/template-list');
            },
            icon: const Icon(Icons.list_rounded, size: 16),
            label: Text(
              'All Templates',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded, size: 16),
            label: Text(
              'Save',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
      ),
    );
  }

  // ── Right PROPERTIES panel ──
  Widget _propertiesPanel() {
    final f = _selectedField;
    final isImage = f?.fieldType == ChequeTemplateFieldType.image;
    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Text(
                  'PROPERTIES',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFFEF4444)),
                  tooltip: 'Delete field',
                  onPressed: f != null ? _removeSelectedField : null,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: f == null
                ? Center(
                    child: Text(
                      'Select a field from the canvas or FIELDS list',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        f.fieldName.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D26),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.fieldName.description,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _sectionLabel('POSITION'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _propNum(
                            key: ValueKey('px-${f.id}'),
                            label: 'X (px)',
                            initial: f.x,
                            onChanged: (d) =>
                                _updateField(f.copyWith(x: d)),
                          ),
                          const SizedBox(width: 8),
                          _propNum(
                            key: ValueKey('py-${f.id}'),
                            label: 'Y from bottom',
                            initial: _canvasHeight - f.y,
                            onChanged: (d) =>
                                _updateField(f.copyWith(y: _canvasHeight - d)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isImage)
                        Row(
                          children: [
                            _propNum(
                              key: ValueKey('pw-${f.id}'),
                              label: 'Width (px)',
                              initial: f.imageWidth,
                              onChanged: (d) =>
                                  _updateField(f.copyWith(imageWidth: d)),
                            ),
                            const SizedBox(width: 8),
                            _propNum(
                              key: ValueKey('ph-${f.id}'),
                              label: 'Height (px)',
                              initial: f.imageHeight,
                              onChanged: (d) =>
                                  _updateField(f.copyWith(imageHeight: d)),
                            ),
                          ],
                        )
                      else
                        _propNum(
                          key: ValueKey('pmw-${f.id}'),
                          label: 'Max width (px) — wraps long text',
                          initial: f.maxWidth,
                          onChanged: (d) =>
                              _updateField(f.copyWith(maxWidth: d)),
                        ),
                      const SizedBox(height: 16),
                      _sectionLabel('TYPOGRAPHY'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _propNum(
                            key: ValueKey('pfs-${f.id}'),
                            label: 'Font size',
                            initial: f.fontSize,
                            onChanged: (d) =>
                                _updateField(f.copyWith(fontSize: d)),
                          ),
                          const SizedBox(width: 8),
                          _propDropdown(
                            key: ValueKey('pfw-${f.id}'),
                            label: 'Weight',
                            value: f.fontWeight ?? 'normal',
                            items: const {
                              'normal': 'Normal',
                              'w500': 'Medium',
                              'w600': 'Semi-bold',
                              'w700': 'Bold',
                            },
                            onChanged: (v) =>
                                _updateField(f.copyWith(fontWeight: v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _propDropdown(
                            key: ValueKey('psi-${f.id}'),
                            label: 'Style',
                            value: f.italic ? 'italic' : 'normal',
                            items: const {
                              'normal': 'Normal',
                              'italic': 'Italic',
                            },
                            onChanged: (v) =>
                                _updateField(f.copyWith(italic: v == 'italic')),
                          ),
                          const SizedBox(width: 8),
                          _propDropdown(
                            key: ValueKey('pal-${f.id}'),
                            label: 'Align',
                            value: f.alignment ?? 'left',
                            items: const {
                              'left': 'Left',
                              'center': 'Center',
                              'right': 'Right',
                            },
                            onChanged: (v) =>
                                _updateField(f.copyWith(alignment: v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _colorRow(f),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: const Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _propNum({
    required Key key,
    required String label,
    required double? initial,
    required ValueChanged<double> onChanged,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 10, color: const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 4),
          TextFormField(
            key: key,
            initialValue: initial?.toStringAsFixed(1) ?? '',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) onChanged(d);
            },
          ),
        ],
      ),
    );
  }

  Widget _propDropdown({
    required Key key,
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 10, color: const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            key: key,
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            items: items.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value,
                          style: GoogleFonts.inter(fontSize: 12)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _colorRow(ChequeTemplateField f) {
    const swatches = ['#1A1D26', '#2563EB', '#DC2626', '#10B981', '#6B7280'];
    final hex = (f.colorHex ?? '#1A1D26').toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('COLOR'),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final c in swatches)
              GestureDetector(
                onTap: () => _updateField(f.copyWith(colorHex: c)),
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF000000 | int.parse(c.substring(1), radix: 16)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hex == c
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE8ECF0),
                      width: hex == c ? 2 : 1,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                key: ValueKey('pcolor-${f.id}'),
                initialValue: hex,
                style: GoogleFonts.inconsolata(
                    fontSize: 12, color: const Color(0xFF1A1D26)),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: (v) {
                  final cleaned = v.trim().replaceFirst('#', '');
                  if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned)) {
                    _updateField(f.copyWith(colorHex: '#${cleaned.toUpperCase()}'));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
