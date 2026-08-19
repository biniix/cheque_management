import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cheque_template.dart';
import '../models/cheque_template_field.dart';
import '../services/local_store.dart';

/// A template bundled with its positioned fields, ready for rendering.
class ChequeTemplateWithFields {
  final ChequeTemplate template;
  final List<ChequeTemplateField> fields;

  const ChequeTemplateWithFields({required this.template, required this.fields});

  ChequeTemplateField? fieldFor(ChequeTemplateFieldName name) {
    for (final f in fields) {
      if (f.fieldName == name) return f;
    }
    return null;
  }
}

/// Resolve the active template for a bank key. Only one template per bank is
/// used by the write-cheque flow; the most recently created one wins.
ChequeTemplateWithFields? templateForBank(
  List<ChequeTemplateWithFields> templates,
  String bankKey,
) {
  if (bankKey.isEmpty) return null;
  ChequeTemplateWithFields? match;
  for (final t in templates) {
    if (t.template.bankKey == bankKey) match = t;
  }
  return match;
}

/// Resolve the exact template a cheque book was created with.
ChequeTemplateWithFields? templateById(
  List<ChequeTemplateWithFields> templates,
  int? id,
) {
  if (id == null) return null;
  for (final t in templates) {
    if (t.template.id == id) return t;
  }
  return null;
}

/// Persists cheque templates + their fields through `LocalStore`
/// (SharedPreferences), matching every other model in the app.
class ChequeTemplatesNotifier
    extends StateNotifier<List<ChequeTemplateWithFields>> {
  final LocalStore _store;

  static const String _templatesKey = 'cheque_templates';
  static const String _fieldsKey = 'cheque_template_fields';

  ChequeTemplatesNotifier(this._store) : super([]);

  Future<void> load() async {
    try {
      final templateJson = await _store.getAll(_templatesKey);
      final fieldJson = await _store.getAll(_fieldsKey);

      final templates = templateJson.map(ChequeTemplate.fromJson).toList();
      final fields = fieldJson.map(ChequeTemplateField.fromJson).toList();

      state = templates.map((t) {
        return ChequeTemplateWithFields(
          template: t,
          fields: fields.where((f) => f.templateId == t.id).toList(),
        );
      }).toList();
    } catch (e) {
      state = [];
    }
  }

  /// Upsert a template and atomically replace its field set.
  Future<void> saveTemplate(
    ChequeTemplate template,
    List<ChequeTemplateField> fields,
  ) async {
    final templateJson = await _store.getAll(_templatesKey);
    final allFieldJson = await _store.getAll(_fieldsKey);

    final existingIndex =
        templateJson.indexWhere((j) => j['id'] == template.id);
    var savedId = template.id;

    if (existingIndex != -1) {
      templateJson[existingIndex] = template.toJson();
    } else {
      savedId = await _store.nextId(_templatesKey);
      final fresh = template.copyWith(id: savedId);
      templateJson.add(fresh.toJson());
      // Re-key any copied fields onto the new template id.
      template = fresh;
    }

    // Replace the field set: drop old rows for this template, add new ones.
    allFieldJson.removeWhere((j) => j['template_id'] == savedId);
    var fieldId = await _store.nextId(_fieldsKey);
    for (final f in fields) {
      final row = f.copyWith(id: fieldId, templateId: savedId).toJson();
      allFieldJson.add(row);
      fieldId++;
    }

    await _store.saveList(_templatesKey, templateJson);
    await _store.saveList(_fieldsKey, allFieldJson);

    await load();
  }

  Future<void> deleteTemplate(int id) async {
    final templateJson = await _store.getAll(_templatesKey);
    final allFieldJson = await _store.getAll(_fieldsKey);
    templateJson.removeWhere((j) => j['id'] == id);
    allFieldJson.removeWhere((j) => j['template_id'] == id);
    await _store.saveList(_templatesKey, templateJson);
    await _store.saveList(_fieldsKey, allFieldJson);
    await load();
  }
}

final chequeTemplatesProvider =
    StateNotifierProvider<ChequeTemplatesNotifier, List<ChequeTemplateWithFields>>(
        (ref) {
  return ChequeTemplatesNotifier(LocalStore());
});
