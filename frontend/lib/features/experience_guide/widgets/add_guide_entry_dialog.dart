import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/experience_guide_provider.dart';

class AddGuideEntryDialog extends ConsumerStatefulWidget {
  final String? initialHsCode;
  final String? initialCategory;
  final String? initialDestinationPort;
  final String? initialSupplier;
  final String? initialShippingLine;
  final VoidCallback? onSuccess;

  const AddGuideEntryDialog({
    super.key,
    this.initialHsCode,
    this.initialCategory,
    this.initialDestinationPort,
    this.initialSupplier,
    this.initialShippingLine,
    this.onSuccess,
  });

  @override
  ConsumerState<AddGuideEntryDialog> createState() => _AddGuideEntryDialogState();
}

class _AddGuideEntryDialogState extends ConsumerState<AddGuideEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  String _entryType = 'required_document';
  String _severity = 'critical';
  bool _isSubmitting = false;

  final List<Map<String, String>> _scopes = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();

    // Pre-seed scopes from shipment parameters if provided
    if (widget.initialHsCode != null && widget.initialHsCode!.trim().isNotEmpty) {
      _scopes.add({'scope_type': 'hs_code', 'scope_value': widget.initialHsCode!.trim()});
    }
    if (widget.initialCategory != null && widget.initialCategory!.trim().isNotEmpty) {
      _scopes.add({'scope_type': 'product_category', 'scope_value': widget.initialCategory!.trim()});
    }
    if (widget.initialDestinationPort != null && widget.initialDestinationPort!.trim().isNotEmpty) {
      _scopes.add({'scope_type': 'destination_port', 'scope_value': widget.initialDestinationPort!.trim()});
    }
    if (widget.initialSupplier != null && widget.initialSupplier!.trim().isNotEmpty) {
      _scopes.add({'scope_type': 'supplier', 'scope_value': widget.initialSupplier!.trim()});
    }
    if (widget.initialShippingLine != null && widget.initialShippingLine!.trim().isNotEmpty) {
      _scopes.add({'scope_type': 'shipping_line', 'scope_value': widget.initialShippingLine!.trim()});
    }

    if (_scopes.isEmpty) {
      _scopes.add({'scope_type': 'hs_code', 'scope_value': ''});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addScope() {
    setState(() {
      _scopes.add({'scope_type': 'hs_code', 'scope_value': ''});
    });
  }

  void _removeScope(int index) {
    setState(() {
      _scopes.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Filter valid scopes
    final validScopes = _scopes
        .where((s) => (s['scope_value'] ?? '').trim().isNotEmpty)
        .map((s) => {
              'scope_type': s['scope_type'],
              'scope_value': s['scope_value']!.trim(),
            })
        .toList();

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'entry_type': _entryType,
        'severity': _severity,
        'created_by': 'المستخدم الحالي',
        'scopes': validScopes,
      };

      await ref.read(experienceGuideProvider.notifier).createEntry(payload);

      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.guideEntrySavedSuccess),
            backgroundColor: AppTheme.flatEmerald,
          ),
        );
        if (widget.onSuccess != null) widget.onSuccess!();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حفظ التوجيه: $e'),
            backgroundColor: AppTheme.flatCrimson,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bookmark_add_outlined, color: AppTheme.flatCobalt, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          l10n.addGuideEntryBtn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.flatCharcoal,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: l10n.guideEntryTitleLabel,
                            hintText: 'مثال: اشتراطات صنف الأكوستيك وإلزامية ميناء الإسكندرية',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'يرجى إدخال عنوان التوجيه';
                            }
                            if (val.trim().length < 3) {
                              return 'العنوان يجب أن يتكون من 3 أحرف على الأقل';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Content
                        TextFormField(
                          controller: _contentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.guideEntryContentLabel,
                            hintText: 'اكتب تفاصيل التوجيه، والمستندات الإلزامية مثل شهادة المنشأ الأصلية أو الميناء المحدد...',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.description_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'يرجى إدخال تفاصيل التوجيه والاشتراطات';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Dropdowns: Type & Severity
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _entryType,
                                decoration: InputDecoration(
                                  labelText: l10n.guideEntryTypeLabel,
                                  border: const OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'required_document', child: Text('مستند إلزامي مسبق')),
                                  DropdownMenuItem(value: 'alert', child: Text('تنبيه إجرائي حرج')),
                                  DropdownMenuItem(value: 'task', child: Text('مهمة متابعة إجبارية')),
                                  DropdownMenuItem(value: 'info', child: Text('معلومة استرشادية')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _entryType = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _severity,
                                decoration: InputDecoration(
                                  labelText: l10n.guideSeverityLabel,
                                  border: const OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'critical',
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning, color: AppTheme.flatCrimson, size: 16),
                                        SizedBox(width: 6),
                                        Text('حرج وإلزامي'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'warning',
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: AppTheme.flatOrange, size: 16),
                                        SizedBox(width: 6),
                                        Text('تحذير هام'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'info',
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: AppTheme.flatCobalt, size: 16),
                                        SizedBox(width: 6),
                                        Text('توجيه استرشادي'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _severity = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Scopes Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.guideScopesHeader,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.flatCharcoal,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add_circle_outline, size: 16),
                              label: Text(l10n.guideAddScopeBtn, style: const TextStyle(fontSize: 12)),
                              onPressed: _addScope,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ..._scopes.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final scope = entry.value;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 170,
                                  child: DropdownButtonFormField<String>(
                                    value: scope['scope_type'],
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'hs_code', child: Text('بند التعريفة')),
                                      DropdownMenuItem(value: 'product_category', child: Text('تصنيف الصنف')),
                                      DropdownMenuItem(value: 'destination_port', child: Text('ميناء الوصول')),
                                      DropdownMenuItem(value: 'supplier', child: Text('المورد الأجنبي')),
                                      DropdownMenuItem(value: 'shipping_line', child: Text('الخط الملاحي')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _scopes[idx]['scope_type'] = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: scope['scope_value'],
                                    decoration: const InputDecoration(
                                      hintText: 'قيمة النطاق (مثال: 8520 أو الإسكندرية)',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (val) {
                                      _scopes[idx]['scope_value'] = val;
                                    },
                                  ),
                                ),
                                if (_scopes.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.flatCrimson, size: 20),
                                    onPressed: () => _removeScope(idx),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 20),

                // Footer Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.flatCobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
