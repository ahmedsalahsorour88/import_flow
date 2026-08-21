import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';



import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';

class InvoiceBLMatcherTab extends ConsumerStatefulWidget {
  final int? selectedImportFileId;
  final Function(int)? onImportFileChanged;

  const InvoiceBLMatcherTab({
    super.key,
    this.selectedImportFileId,
    this.onImportFileChanged,
  });

  @override
  ConsumerState<InvoiceBLMatcherTab> createState() => _InvoiceBLMatcherTabState();
}

class _InvoiceBLMatcherTabState extends ConsumerState<InvoiceBLMatcherTab> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  final TextEditingController _invoiceTextCtrl = TextEditingController();
  final TextEditingController _blTextCtrl = TextEditingController();
  final TextEditingController _packingTextCtrl = TextEditingController();

  String? _invoiceFileName;
  String? _blFileName;
  String? _packingFileName;
  Uint8List? _invoiceFileBytes;
  Uint8List? _blFileBytes;
  Uint8List? _packingFileBytes;
  bool _showPackingList = true;
  bool _isLoading = false;
  bool _isSyncing = false;

  Map<String, dynamic>? _matchResult;
  int? _activeFileId;

  // Real Sample Data Presets
  static const String sampleShawInvoice = '''
Commercial Invoice
Shaw Europe Limited
Blackaddie Road, Sanquhar, United Kingdom, DG4 6DB
VAT Number 428102677

Order Date 24-06-2026
Order Number 35220
Shipment Number 688990
Purchase Order RSA-ARCE-Found Ever

Bill To:
ARCHI BRANDS FOR CORPET AND FLOOR TRADING
44 Street 18, Maadi Sarayat, Cairo, Egypt
Tax ID 759552827
''';

  static const String sampleMscBL = '''
MEDITERRANEAN SHIPPING COMPANY S.A.
BILL OF LADING No. MEDURE910647
DRAFT - SCAC Code: MEDU

SHIPPER:
SHAW EUROPE LTD
BUILDING E, BLACKADDIE RD SANQUHAR, DG4 6DB. UNITED KINGDOM

CONSIGNEE:
ARCHI Brands for Corpet and Floor Trading
St.81 with st.18 building 44, 3rd floor, SARAYAT EL MAADI, Cairo- Egypt
VAT No: 759-552-827

VESSEL AND VOYAGE NO: MSC GISELLE - NL630A
PORT OF LOADING: FELIXSTOWE, UNITED KINGDOM
PORT OF DISCHARGE: SOX - SOKHNA, EGYPT
PLACE OF DELIVERY: SOKHNA, EGYPT

ACID NUMBER: 7595528271019210013
IMPORTER TAX ID: 759552827
EXPORTER REGISTRATION NUMBER: 428102677

CONTAINER NUMBER: BEAU5851356 / 40HC / SEAL: 177345
PACKAGES: 31 PALLETS (CONTAINING 960 BOXES)
COMMODITY: TUFTED CARPET TILES OF NYLON
HS CODE: 5703299100
Gross Cargo Weight: 20,030.000 kgs.
Total Items: 31 Total: 20,030.000 kgs.
''';

  @override
  void initState() {
    super.initState();
    _activeFileId = widget.selectedImportFileId;
  }

  @override
  void didUpdateWidget(covariant InvoiceBLMatcherTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedImportFileId != oldWidget.selectedImportFileId) {
      setState(() {
        _activeFileId = widget.selectedImportFileId;
      });
    }
  }

  @override
  void dispose() {
    _invoiceTextCtrl.dispose();
    _blTextCtrl.dispose();
    _packingTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String docType) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'csv', 'doc', 'docx', 'xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final ext = (file.name.split('.').last).toLowerCase();
        final isTextFormat = ['txt', 'csv', 'json', 'xml', 'log'].contains(ext);

        if (!mounted) return;
        setState(() {
          if (docType == 'invoice') {
            _invoiceFileName = file.name;
            _invoiceFileBytes = file.bytes;
            if (isTextFormat && file.bytes != null) {
              try {
                _invoiceTextCtrl.text = utf8.decode(file.bytes!, allowMalformed: true);
              } catch (_) {
                _invoiceTextCtrl.text = '';
              }
            } else {
              _invoiceTextCtrl.text = '[تم تحميل ملف رقمي: ${file.name} — سيتم استخراج ومطابقة محتواه آلياً عند الضغط على زر المطابقة]';
            }
          } else if (docType == 'packing') {
            _showPackingList = true;
            _packingFileName = file.name;
            _packingFileBytes = file.bytes;
            if (isTextFormat && file.bytes != null) {
              try {
                _packingTextCtrl.text = utf8.decode(file.bytes!, allowMalformed: true);
              } catch (_) {
                _packingTextCtrl.text = '';
              }
            } else {
              _packingTextCtrl.text = '[تم تحميل كشف تعبئة رقمي: ${file.name} — سيتم استخراج الأوزان والأحجام والطرود آلياً عند المطابقة]';
            }
          } else {
            _blFileName = file.name;
            _blFileBytes = file.bytes;
            if (isTextFormat && file.bytes != null) {
              try {
                _blTextCtrl.text = utf8.decode(file.bytes!, allowMalformed: true);
              } catch (_) {
                _blTextCtrl.text = '';
              }
            } else {
              _blTextCtrl.text = '[تم تحميل ملف رقمي: ${file.name} — سيتم استخراج ومطابقة محتواه آلياً عند الضغط على زر المطابقة]';
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم اختيار ملف ${file.name} بنجاح'),
              backgroundColor: AppTheme.emerald,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر قراءة الملف: $e'),
            backgroundColor: AppTheme.crimson,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _loadSampleData() {
    setState(() {
      _invoiceTextCtrl.text = sampleShawInvoice.trim();
      _invoiceFileName = 'ShawContract_Commercial_Invoice.txt';
      _blTextCtrl.text = sampleMscBL.trim();
      _blFileName = 'MSC_Draft_BL_MEDURE910647.txt';
      _invoiceFileBytes = null;
      _blFileBytes = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحميل بيانات العينات الفعلية (Shaw Europe + MSC B/L)'),
          backgroundColor: AppTheme.cobalt,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _runCrossMatching() async {
    final hasInvoiceFile = _invoiceFileBytes != null;
    final hasBlFile = _blFileBytes != null;
    final hasPackingFile = _packingFileBytes != null;
    final invText = _invoiceTextCtrl.text.trim();
    final blText = _blTextCtrl.text.trim();
    final plText = _packingTextCtrl.text.trim();

    final hasInvContent = hasInvoiceFile || (invText.isNotEmpty && !invText.startsWith('[تم تحميل'));
    final hasBlContent = hasBlFile || (blText.isNotEmpty && !blText.startsWith('[تم تحميل'));
    final hasPlContent = hasPackingFile || (plText.isNotEmpty && !plText.startsWith('[تم تحميل'));

    if (!hasInvContent && !hasBlContent && !hasPlContent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى إدخال أو رفع نصوص ومستندات الفاتورة أو كشف التعبئة أو بوليصة الشحن للمطابقة'),
            backgroundColor: AppTheme.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Response response;

      if (hasInvoiceFile || hasBlFile || hasPackingFile) {
        final formData = FormData();
        if (_activeFileId != null) {
          formData.fields.add(MapEntry('import_file_id', _activeFileId.toString()));
        }

        if (hasInvoiceFile) {
          formData.files.add(MapEntry(
            'invoice_file',
            MultipartFile.fromBytes(_invoiceFileBytes!, filename: _invoiceFileName ?? 'invoice.pdf'),
          ));
        } else if (invText.isNotEmpty && !invText.startsWith('[تم تحميل')) {
          formData.fields.add(MapEntry('invoice_text', invText));
        }

        if (hasPackingFile) {
          formData.files.add(MapEntry(
            'packing_list_file',
            MultipartFile.fromBytes(_packingFileBytes!, filename: _packingFileName ?? 'packing_list.pdf'),
          ));
        } else if (plText.isNotEmpty && !plText.startsWith('[تم تحميل')) {
          formData.fields.add(MapEntry('packing_list_text', plText));
        }

        if (hasBlFile) {
          formData.files.add(MapEntry(
            'bl_file',
            MultipartFile.fromBytes(_blFileBytes!, filename: _blFileName ?? 'bl.pdf'),
          ));
        } else if (blText.isNotEmpty && !blText.startsWith('[تم تحميل')) {
          formData.fields.add(MapEntry('bl_text', blText));
        }

        response = await _dio.post(
          '${ApiConstants.baseUrl}/import-documentation/invoice-bl/extract-files-and-match',
          data: formData,
        );
      } else {
        response = await _dio.post(
          '${ApiConstants.baseUrl}/import-documentation/invoice-bl/extract-and-match',
          data: {
            'import_file_id': _activeFileId,
            'invoice_raw_text': _invoiceTextCtrl.text,
            'bl_raw_text': _blTextCtrl.text,
            'packing_list_raw_text': _packingTextCtrl.text,
          },
        );
      }


      if (response.statusCode == 200) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : jsonDecode(response.data.toString()) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _matchResult = data;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('اكتملت المطابقة الذكية بنجاح! نسبة التطابق: ${data['match_score_percentage']}%'),
              backgroundColor: data['is_safe_for_certification'] == true ? AppTheme.emerald : AppTheme.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ في المطابقة الذكية', error: e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _certifyAndSync() async {
    if (_matchResult == null || _activeFileId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار ملف شحنة وإجراء المطابقة أولاً للمزامنة'),
            backgroundColor: AppTheme.crimson,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/invoice-bl/certify-and-sync',
        data: {
          'import_file_id': _activeFileId,
          'invoice_data': _matchResult!['invoice_data'],
          'bl_data': _matchResult!['bl_data'],
          'sync_to_po': true,
          'sync_to_shipping': true,
        },
      );

      if (response.statusCode == 200) {
        final res = response.data;
        ref.invalidate(importFilesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'تمت المزامنة والاعتماد بنجاح!'),
              backgroundColor: AppTheme.emerald,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Server error ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'فشل مزامنة البيانات', error: e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header & Import File Selector Bar
          _buildHeaderControlBar(importFiles),
          const SizedBox(height: 16),

          // 2. Dual Document Ingestion Section (Invoice vs B/L)
          _buildDualIngestionSection(),
          const SizedBox(height: 16),

          // 3. Action Buttons (Run Match, Load Samples, Reset)
          _buildActionButtonsBar(),
          const SizedBox(height: 20),

          // 4. Comparison Results & Score Matrix
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'جاري التحليل واستخراج الحقول المطابقة بالذكاء الاصطناعي...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          else if (_matchResult != null) ...[
            _buildMatchSummaryCard(),
            const SizedBox(height: 16),
            _buildComparisonMatrixTable(),
            const SizedBox(height: 16),
            _buildExtractedFieldsCards(),
            if (_matchResult!['correction_letter'] != null &&
                _matchResult!['correction_letter'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCorrectionLetterCard(),
            ],
            const SizedBox(height: 24),
            _buildSyncActionFooter(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderControlBar(List<dynamic> importFiles) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cobalt.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.cobalt, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أداة الاستخراج الذكي والمطابقة الفورية (Commercial Invoice vs. Bill of Lading)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
                SizedBox(height: 4),
                Text(
                  'استخراج الحقول المستهدفة ومطابقة الفاتورة النهائية مع البوليصة ومنع أي تعارض جمركي أو بنكي.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 320,
            child: SearchableDropdownField<int>(
              labelText: 'ربط بملف استيراد',
              hintText: 'اختر ملف الشحنة للمزامنة...',
              value: _activeFileId,
              items: importFiles
                  .map(
                    (f) => SearchableDropdownItem<int>(
                      value: f.importFileId,
                      label: '${f.importFileCode} - ${f.supplierName} (${f.status})',
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _activeFileId = val;
                });
                if (widget.onImportFileChanged != null && val != null) {
                  widget.onImportFileChanged!(val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualIngestionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_showPackingList)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showPackingList = true;
                    });
                  },
                  icon: const Icon(Icons.post_add, size: 18, color: AppTheme.orange),
                  label: const Text(
                    '+ إضافة كشف التعبئة كملف إضافي (Packing List)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.orange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.orange),
                    backgroundColor: AppTheme.orange.withOpacity(0.04),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isVeryWide = constraints.maxWidth > 1050;
            final isWide = constraints.maxWidth > 750;

            final invoiceBox = _buildDocumentInputBox(
              titleAr: '1. الفاتورة التجارية النهائية (Commercial Invoice)',
              titleEn: 'Final Commercial Invoice',
              icon: Icons.receipt_long,
              color: AppTheme.cobalt,
              controller: _invoiceTextCtrl,
              fileName: _invoiceFileName,
              docType: 'invoice',
              placeholder: 'الصق نص الفاتورة هنا أو اضغط رفع PDF / ملف تجاري...',
            );

            final packingBox = _buildDocumentInputBox(
              titleAr: '2. كشف التعبئة النهائي (Packing List)',
              titleEn: 'Final Packing List (Additional File)',
              icon: Icons.inventory_2,
              color: AppTheme.orange,
              controller: _packingTextCtrl,
              fileName: _packingFileName,
              docType: 'packing',
              placeholder: 'الصق نص كشف التعبئة هنا أو اضغط رفع كشف التعبئة (PDF/Excel)...',
              onRemove: () {
                setState(() {
                  _showPackingList = false;
                  _packingFileName = null;
                  _packingFileBytes = null;
                  _packingTextCtrl.clear();
                });
              },
            );

            final blBox = _buildDocumentInputBox(
              titleAr: _showPackingList ? '3. مسودة بوليصة الشحن (Draft B/L)' : '2. مسودة بوليصة الشحن (Draft B/L)',
              titleEn: 'Draft Bill of Lading (Carrier / Forwarder)',
              icon: Icons.directions_boat,
              color: AppTheme.emerald,
              controller: _blTextCtrl,
              fileName: _blFileName,
              docType: 'bl',
              placeholder: 'الصق مسودة البوليصة هنا أو اضغط رفع PDF الخط الملاحي...',
            );

            if (_showPackingList) {
              if (isVeryWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: invoiceBox),
                    const SizedBox(width: 14),
                    Expanded(child: packingBox),
                    const SizedBox(width: 14),
                    Expanded(child: blBox),
                  ],
                );
              } else if (isWide) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: invoiceBox),
                        const SizedBox(width: 14),
                        Expanded(child: packingBox),
                      ],
                    ),
                    const SizedBox(height: 14),
                    blBox,
                  ],
                );
              } else {
                return Column(
                  children: [
                    invoiceBox,
                    const SizedBox(height: 14),
                    packingBox,
                    const SizedBox(height: 14),
                    blBox,
                  ],
                );
              }
            }

            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: invoiceBox,
                ),
                SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: blBox,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDocumentInputBox({
    required String titleAr,
    required String titleEn,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String? fileName,
    required String docType,
    required String placeholder,
    VoidCallback? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleAr,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      titleEn,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickFile(docType),
                icon: const Icon(Icons.upload_file, size: 16),
                label: Text(fileName != null ? 'تغيير الملف' : 'رفع ملف'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  tooltip: 'إلغاء وإخفاء كشف التعبئة',
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ],
          ),
          if (fileName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'الملف المرفوع: $fileName',
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 8,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsBar() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _runCrossMatching,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.compare_arrows, size: 20),
          label: const Text(
            'تنفيذ الاستخراج الذكي والمطابقة الفورية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cobalt,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            elevation: 2,
          ),
        ),
        OutlinedButton.icon(
          onPressed: _loadSampleData,
          icon: const Icon(Icons.auto_stories, size: 18, color: AppTheme.charcoal),
          label: const Text(
            'تحميل نموذج تجريبي حقيقي (Shaw Europe + MSC)',
            style: TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _invoiceTextCtrl.clear();
              _blTextCtrl.clear();
              _packingTextCtrl.clear();
              _invoiceFileName = null;
              _blFileName = null;
              _packingFileName = null;
              _invoiceFileBytes = null;
              _blFileBytes = null;
              _packingFileBytes = null;
              _showPackingList = false;
              _matchResult = null;
            });
          },
          icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
          label: const Text('إعادة تعيين', style: TextStyle(color: Colors.grey)),
        ),

      ],
    );
  }

  Widget _buildMatchSummaryCard() {
    final res = _matchResult!;
    final score = res['match_score_percentage'] ?? 0.0;
    final isSafe = res['is_safe_for_certification'] == true;
    final criticalCount = res['critical_discrepancies_count'] ?? 0;
    final warningCount = res['warning_discrepancies_count'] ?? 0;

    final color = isSafe ? (warningCount > 0 ? AppTheme.orange : AppTheme.emerald) : AppTheme.crimson;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSafe ? Icons.verified_rounded : Icons.gpp_bad_rounded,
              color: color,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isSafe ? 'مستندات متطابقة وجاهزة للاعتماد' : 'تم اكتشاف اختلافات حرجة تمنع الاعتماد',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'نسبة المطابقة: $score%',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isSafe
                      ? 'كافة الحقول الجمركية والمصرفية مطابقة بنسبة آمنة. يمكنك مزامنة البيانات مباشرة مع ملف الشحنة.'
                      : 'توجد $criticalCount فوارق حرجة تمنع الإفراج الجمركي أو مطابقة نموذج 4. يجب تعديل البوليصة أو الفاتورة قبل الاعتماد.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              _buildBadgeCounter('فوارق حرجة', criticalCount, AppTheme.crimson),
              const SizedBox(height: 6),
              _buildBadgeCounter('تنبيهات ثانوية', warningCount, AppTheme.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCounter(String label, int count, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: count > 0 ? col.withOpacity(0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: count > 0 ? col : Colors.grey.shade300),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: count > 0 ? col : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildComparisonMatrixTable() {
    final matrix = (_matchResult!['comparison_matrix'] as List<dynamic>?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Icon(Icons.table_chart_outlined, size: 18, color: AppTheme.charcoal),
                SizedBox(width: 8),
                Text(
                  'مصفوفة المطابقة التفصيلية (10 بنود فحص جمركية ومصرفية)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              horizontalMargin: 16,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('بند الفحص والمطابقة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('القيمة بالفاتورة النهائية', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('القيمة بمسودة البوليصة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('حالة المطابقة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('النتيجة والإجراء المطلوب', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: matrix.map((item) {
                final status = item['match_status'] ?? 'MATCH';
                final isMatch = status == 'MATCH';
                final isMinor = status == 'MISMATCH_MINOR';

                final statusCol = isMatch ? AppTheme.emerald : (isMinor ? AppTheme.orange : AppTheme.crimson);
                final statusTxt = isMatch ? 'مطابق ✅' : (isMinor ? 'فارق طفيف ⚠️' : 'غير مطابق ❌');

                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item['field_name_ar'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(item['field_name_en'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        '${item['invoice_value'] ?? '—'}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cobalt),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${item['bl_value'] ?? '—'}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.emerald),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusCol.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusCol),
                        ),
                        child: Text(
                          statusTxt,
                          style: TextStyle(color: statusCol, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        item['details'] ?? '',
                        style: TextStyle(fontSize: 11, color: isMatch ? Colors.grey.shade800 : statusCol),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedFieldsCards() {
    final inv = _matchResult!['invoice_data'] ?? {};
    final bl = _matchResult!['bl_data'] ?? {};

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Extracted Invoice Data Card
        Expanded(
          child: _buildDataSummaryCard(
            title: 'البيانات المستخرجة من الفاتورة',
            icon: Icons.receipt_long,
            color: AppTheme.cobalt,
            data: inv,
          ),
        ),
        const SizedBox(width: 16),
        // Extracted B/L Data Card
        Expanded(
          child: _buildDataSummaryCard(
            title: 'البيانات المستخرجة من مسودة البوليصة',
            icon: Icons.directions_boat,
            color: AppTheme.emerald,
            data: bl,
          ),
        ),
      ],
    );
  }

  Widget _buildDataSummaryCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, dynamic> data,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            ],
          ),
          const Divider(),
          ...data.entries.map((e) {
            if (e.key.startsWith('_') || e.value == null || e.value.toString().isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      '${e.key}:',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${e.value}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCorrectionLetterCard() {
    final letter = _matchResult!['correction_letter'].toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined, color: AppTheme.orange, size: 22),
              const SizedBox(width: 8),
              const Text(
                'خطاب طلب التعديل التلقائي للخط الملاحي (B/L Correction Request)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: letter));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ خطاب التعديل إلى الحافظة بنجاح'),
                      backgroundColor: AppTheme.cobalt,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('نسخ الخطاب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: SelectableText(
              letter,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncActionFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_alt, color: AppTheme.cobalt, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اعتماد النتائج ومزامنة بيانات الفاتورة والبوليصة مع ملف الاستيراد',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                ),
                Text(
                  _activeFileId != null
                      ? 'سيتم تحديث رقم البوليصة، رقم الفاتورة، القيمة الإجمالية، والحاويات في ملف الشحنة المحدد.'
                      : 'يرجى اختيار ملف شحنة من القائمة بالأعلى للمزامنة.',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Export / Copy Match Report Button
          OutlinedButton.icon(
            onPressed: _matchResult == null ? null : _showExportReportDialog,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('تصدير تقرير المطابقة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.cobalt,
              side: const BorderSide(color: AppTheme.cobalt),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: (_activeFileId == null || _isSyncing) ? null : _certifyAndSync,
            icon: _isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: const Text(
              'اعتماد ومزامنة مع ملف الشحنة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportReportDialog() {
    if (_matchResult == null) return;

    final score = _matchResult!['match_score_percentage'] ?? 0;
    final status = _matchResult!['overall_status'] ?? 'UNKNOWN';
    final isSafe = _matchResult!['is_safe_for_certification'] == true;
    final criticals = _matchResult!['critical_discrepancies_count'] ?? 0;
    final warnings = _matchResult!['warning_discrepancies_count'] ?? 0;
    final matrix = _matchResult!['comparison_matrix'] as List<dynamic>? ?? [];
    final correctionLetter = _matchResult!['correction_letter']?.toString() ?? '';

    final reportBuffer = StringBuffer();
    reportBuffer.writeln('===============================================================');
    reportBuffer.writeln('    تقرير المطابقة الذكية: الفاتورة التجارية vs البوليصة');
    reportBuffer.writeln('===============================================================');
    reportBuffer.writeln('نسبة التطابق الإجمالية : $score%');
    reportBuffer.writeln('حالة النتيجة           : $status');
    reportBuffer.writeln('قابل للاعتماد          : ${isSafe ? "نعم ✔" : "لا ✖"}');
    reportBuffer.writeln('الاختلافات الحرجة      : $criticals');
    reportBuffer.writeln('التنبيهات              : $warnings');
    reportBuffer.writeln('---------------------------------------------------------------');
    reportBuffer.writeln('تفاصيل مصفوفة المقارنة:');
    for (final row in matrix) {
      final r = row as Map<String, dynamic>;
      reportBuffer.writeln(
        '  ${r['field_label_ar'] ?? r['field_key']} | ${r['match_status']} | '
        'System: ${r['system_value'] ?? "—"} | Draft: ${r['draft_value'] ?? "—"}',
      );
    }
    if (correctionLetter.isNotEmpty) {
      reportBuffer.writeln('---------------------------------------------------------------');
      reportBuffer.writeln('خطاب التصحيح المقترح:');
      reportBuffer.writeln(correctionLetter);
    }
    reportBuffer.writeln('===============================================================');

    final reportText = reportBuffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_outlined, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('تقرير المطابقة الذكية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 480,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'نسبة التطابق: $score%  |  ${isSafe ? "✅ آمن للاعتماد" : "⚠ يوجد فوارق حرجة"}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSafe ? AppTheme.emerald : AppTheme.crimson,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('نسخ التقرير'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: reportText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✔ تم نسخ التقرير إلى الحافظة'), backgroundColor: AppTheme.emerald),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      reportText,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}
