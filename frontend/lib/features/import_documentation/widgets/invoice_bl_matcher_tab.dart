import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';



import '../../../core/constants/api_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';
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
  List<PlatformFile> _invoiceFiles = [];
  List<PlatformFile> _blFiles = [];
  List<PlatformFile> _packingFiles = [];
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!ref.read(importFilesProvider).isLoading) {
        await ref.read(importFilesProvider.notifier).fetchImportFiles();
      }
      final files = ref.read(importFilesProvider).valueOrNull ?? [];
      if (_activeFileId == null && files.isNotEmpty && mounted) {
        setState(() {
          _activeFileId = files.first.importFileId;
        });
      }
    });
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
    _dio.close(force: true);
    _invoiceTextCtrl.dispose();
    _blTextCtrl.dispose();
    _packingTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String docType) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'tif', 'tiff', 'txt', 'csv', 'doc', 'docx', 'xlsx', 'xls'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final count = result.files.length;
        final ext = (file.name.split('.').last).toLowerCase();
        final isTextFormat = ['txt', 'csv', 'json', 'xml', 'log'].contains(ext);

        if (!mounted) return;
        final l = context.l10n;
        setState(() {
          if (docType == 'invoice') {
            _invoiceFiles = result.files;
            _invoiceFileName = count == 1 ? file.name : '${file.name} (+$count)';
            _invoiceFileBytes = file.bytes;
            if (isTextFormat && file.bytes != null && count == 1) {
              try {
                _invoiceTextCtrl.text = utf8.decode(file.bytes!, allowMalformed: true);
              } catch (_) {
                _invoiceTextCtrl.text = '';
              }
            } else {
              _invoiceTextCtrl.text = l.invoiceBlMatcherInvoiceFilesLoaded(count, result.files.map((f) => f.name).join(", "));
            }
          } else if (docType == 'packing') {
            _showPackingList = true;
            _packingFiles = result.files;
            _packingFileName = count == 1 ? file.name : '${file.name} (+$count)';
            _packingFileBytes = file.bytes;
            if (isTextFormat && file.bytes != null && count == 1) {
              try {
                _packingTextCtrl.text = utf8.decode(file.bytes!, allowMalformed: true);
              } catch (_) {
                _packingTextCtrl.text = '';
              }
            } else {
              _packingTextCtrl.text = l.invoiceBlMatcherPackingFilesLoaded(count, result.files.map((f) => f.name).join(", "));
            }
          } else {
            _blFiles = result.files;
            _blFileName = count == 1 ? file.name : '${file.name} (+$count)';
            _blFileBytes = file.bytes;
            if (isTextFormat && file.bytes != null && count == 1) {
              try {
                _blTextCtrl.text = utf8.decode(file.bytes!, allowMalformed: true);
              } catch (_) {
                _blTextCtrl.text = '';
              }
            } else {
              _blTextCtrl.text = l.invoiceBlMatcherBlFilesLoaded(count, result.files.map((f) => f.name).join(", "));
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.invoiceBlMatcherFilesSelectedSuccess(count, result.files.map((f) => f.name).join(", "))),
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
            content: Text(context.l10n.invoiceBlMatcherFileReadError(e)),
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
      _invoiceFiles = [];
      _blFiles = [];
      _packingFiles = [];
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.invoiceBlMatcherSampleLoadedSuccess),
          backgroundColor: AppTheme.cobalt,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _runCrossMatching() async {
    final hasInvoiceFile = _invoiceFiles.isNotEmpty || _invoiceFileBytes != null;
    final hasBlFile = _blFiles.isNotEmpty || _blFileBytes != null;
    final hasPackingFile = _packingFiles.isNotEmpty || _packingFileBytes != null;
    final invText = _invoiceTextCtrl.text.trim();
    final blText = _blTextCtrl.text.trim();
    final plText = _packingTextCtrl.text.trim();

    final hasInvContent = hasInvoiceFile || (invText.isNotEmpty && !invText.startsWith('['));
    final hasBlContent = hasBlFile || (blText.isNotEmpty && !blText.startsWith('['));
    final hasPlContent = hasPackingFile || (plText.isNotEmpty && !plText.startsWith('['));

    if (!hasInvContent && !hasBlContent && !hasPlContent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.invoiceBlMatcherValidationRequired),
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

        if (_invoiceFiles.isNotEmpty) {
          for (final f in _invoiceFiles) {
            if (f.bytes != null) {
              formData.files.add(MapEntry(
                'invoice_files',
                MultipartFile.fromBytes(f.bytes!, filename: f.name),
              ));
            }
          }
        } else if (_invoiceFileBytes != null) {
          formData.files.add(MapEntry(
            'invoice_file',
            MultipartFile.fromBytes(_invoiceFileBytes!, filename: _invoiceFileName ?? 'invoice.pdf'),
          ));
        } else if (invText.isNotEmpty && !invText.startsWith('[')) {
          formData.fields.add(MapEntry('invoice_text', invText));
        }

        if (_packingFiles.isNotEmpty) {
          for (final f in _packingFiles) {
            if (f.bytes != null) {
              formData.files.add(MapEntry(
                'packing_list_files',
                MultipartFile.fromBytes(f.bytes!, filename: f.name),
              ));
            }
          }
        } else if (_packingFileBytes != null) {
          formData.files.add(MapEntry(
            'packing_list_file',
            MultipartFile.fromBytes(_packingFileBytes!, filename: _packingFileName ?? 'packing_list.pdf'),
          ));
        } else if (plText.isNotEmpty && !plText.startsWith('[')) {
          formData.fields.add(MapEntry('packing_list_text', plText));
        }

        if (_blFiles.isNotEmpty) {
          for (final f in _blFiles) {
            if (f.bytes != null) {
              formData.files.add(MapEntry(
                'bl_files',
                MultipartFile.fromBytes(f.bytes!, filename: f.name),
              ));
            }
          }
        } else if (_blFileBytes != null) {
          formData.files.add(MapEntry(
            'bl_file',
            MultipartFile.fromBytes(_blFileBytes!, filename: _blFileName ?? 'bl.pdf'),
          ));
        } else if (blText.isNotEmpty && !blText.startsWith('[')) {
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
              content: Text(context.l10n.invoiceBlMatcherMatchCompletedSuccess(data['match_score_percentage'])),
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
        showErrorDetailsDialog(context, title: context.l10n.invoiceBlMatcherMatchErrorTitle, error: e);
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
          SnackBar(
            content: Text(context.l10n.invoiceBlMatcherSelectFileFirstWarning),
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
              content: Text(res['message'] ?? context.l10n.invoiceBlMatcherSyncSuccess),
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
        showErrorDetailsDialog(context, title: context.l10n.invoiceBlMatcherSyncFailedTitle, error: e);
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
    final importFiles = ref.watch(importFilesProvider).valueOrNull ?? [];
    final l = context.l10n;

    return SelectionArea(
      child: SingleChildScrollView(
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        l.invoiceBlMatcherAnalyzingProgress,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildHeaderControlBar(List<dynamic> importFiles) {
    final l = context.l10n;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.invoiceBlMatcherTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  l.invoiceBlMatcherSubtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 320,
            child: SearchableDropdownField<int>(
              labelText: l.invoiceBlMatcherLinkImportFile,
              hintText: l.invoiceBlMatcherSelectFileHint,
              value: _activeFileId,
              items: importFiles
                  .map(
                    (f) => SearchableDropdownItem<int>(
                      value: f.importFileId,
                      label: '${f.primaryNameWithCode} - ${f.supplierName} (${f.status})',
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
    final l = context.l10n;

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
                  label: Text(
                    l.invoiceBlMatcherAddPackingListButton,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.orange),
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
              title: l.invoiceBlMatcherInvoiceBoxTitle,
              icon: Icons.receipt_long,
              color: AppTheme.cobalt,
              controller: _invoiceTextCtrl,
              fileName: _invoiceFileName,
              docType: 'invoice',
              placeholder: l.invoiceBlMatcherInvoicePlaceholder,
            );

            final packingBox = _buildDocumentInputBox(
              title: l.invoiceBlMatcherPackingBoxTitle,
              icon: Icons.inventory_2,
              color: AppTheme.orange,
              controller: _packingTextCtrl,
              fileName: _packingFileName,
              docType: 'packing',
              placeholder: l.invoiceBlMatcherPackingPlaceholder,
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
              title: l.invoiceBlMatcherBlBoxTitle,
              icon: Icons.directions_boat,
              color: AppTheme.emerald,
              controller: _blTextCtrl,
              fileName: _blFileName,
              docType: 'bl',
              placeholder: l.invoiceBlMatcherBlPlaceholder,
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
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String? fileName,
    required String docType,
    required String placeholder,
    VoidCallback? onRemove,
  }) {
    final l = context.l10n;

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
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickFile(docType),
                icon: const Icon(Icons.upload_file, size: 16),
                label: Text(fileName != null ? l.invoiceBlMatcherChangeFile : l.invoiceBlMatcherUploadFile),
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
                  tooltip: l.invoiceBlMatcherRemovePackingList,
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
                      l.invoiceBlMatcherUploadedFile(fileName),
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
    final l = context.l10n;

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
          label: Text(
            l.invoiceBlMatcherExecuteMatchButton,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
          label: Text(
            l.invoiceBlMatcherLoadSampleButton,
            style: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12),
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
          label: Text(l.invoiceBlMatcherResetButton, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildMatchSummaryCard() {
    final l = context.l10n;
    final res = _matchResult ?? {};
    final score = res['match_score_percentage'] ?? 0.0;
    final isSafe = res['is_safe_for_certification'] == true;
    final criticalCount = (res['critical_discrepancies_count'] as num?)?.toInt() ?? 0;
    final warningCount = (res['warning_discrepancies_count'] as num?)?.toInt() ?? 0;

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
                      isSafe ? l.invoiceBlMatcherStatusSafeTitle : l.invoiceBlMatcherStatusCriticalTitle,
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
                        l.invoiceBlMatcherMatchScore(score),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isSafe
                      ? l.invoiceBlMatcherStatusSafeDesc
                      : l.invoiceBlMatcherStatusCriticalDesc(criticalCount),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              _buildBadgeCounter(l.invoiceBlMatcherCriticalCount(criticalCount), criticalCount, AppTheme.crimson),
              const SizedBox(height: 6),
              _buildBadgeCounter(l.invoiceBlMatcherWarningCount(warningCount), warningCount, AppTheme.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCounter(String labelText, int count, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: count > 0 ? col.withOpacity(0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: count > 0 ? col : Colors.grey.shade300),
      ),
      child: Text(
        labelText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: count > 0 ? col : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildComparisonMatrixTable() {
    final l = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final matrix = ((_matchResult?['comparison_matrix']) as List<dynamic>?) ?? [];

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
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined, size: 18, color: AppTheme.charcoal),
                const SizedBox(width: 8),
                Text(
                  l.invoiceBlMatcherMatrixTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
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
              columns: [
                DataColumn(label: Text(l.invoiceBlMatcherColCheckItem, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l.invoiceBlMatcherColInvoiceValue, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l.invoiceBlMatcherColBlValue, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l.invoiceBlMatcherColMatchStatus, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l.invoiceBlMatcherColActionRequired, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: matrix.map((item) {
                final status = item['match_status'] ?? 'MATCH';
                final isMatch = status == 'MATCH';
                final isMinor = status == 'MISMATCH_MINOR';

                final statusCol = isMatch ? AppTheme.emerald : (isMinor ? AppTheme.orange : AppTheme.crimson);
                final statusTxt = isMatch
                    ? l.invoiceBlMatcherStatusMatch
                    : (isMinor ? l.invoiceBlMatcherStatusMinor : l.invoiceBlMatcherStatusMismatch);

                final checkItemName = isArabic
                    ? (item['field_name_ar'] ?? item['field_name_en'] ?? '')
                    : (item['field_name_en'] ?? item['field_name_ar'] ?? '');

                final invoiceVal = '${item['invoice_value'] ?? '—'}';
                final blVal = '${item['bl_value'] ?? '—'}';
                final detailsTxt = '${item['details'] ?? ''}';

                final rowSummary = '$checkItemName\t$invoiceVal\t$blVal\t$statusTxt\t$detailsTxt';

                return DataRow(
                  cells: [
                    DataCell(
                      CopyableTableCell(
                        value: checkItemName,
                        rowSummary: rowSummary,
                        child: Text(
                          checkItemName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: invoiceVal,
                        rowSummary: rowSummary,
                        child: Text(
                          invoiceVal,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cobalt),
                        ),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: blVal,
                        rowSummary: rowSummary,
                        child: Text(
                          blVal,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.emerald),
                        ),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: statusTxt,
                        rowSummary: rowSummary,
                        child: Container(
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
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: detailsTxt,
                        rowSummary: rowSummary,
                        child: Text(
                          detailsTxt,
                          style: TextStyle(fontSize: 11, color: isMatch ? Colors.grey.shade800 : statusCol),
                        ),
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
    final l = context.l10n;
    final inv = _matchResult?['invoice_data'] ?? {};
    final bl = _matchResult?['bl_data'] ?? {};

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Extracted Invoice Data Card
        Expanded(
          child: _buildDataSummaryCard(
            title: l.invoiceBlMatcherExtractedInvoiceTitle,
            icon: Icons.receipt_long,
            color: AppTheme.cobalt,
            data: inv,
          ),
        ),
        const SizedBox(width: 16),
        // Extracted B/L Data Card
        Expanded(
          child: _buildDataSummaryCard(
            title: l.invoiceBlMatcherExtractedBlTitle,
            icon: Icons.directions_boat,
            color: AppTheme.emerald,
            data: bl,
          ),
        ),
      ],
    );
  }

  String _localizeDataKey(String key, AppLocalizations l, bool isArabic) {
    switch (key) {
      case 'invoice_number':
      case 'invoice_no':
        return l.smartExtractorFieldInvoiceNo;
      case 'invoice_date':
        return l.smartExtractorFieldInvoiceDate;
      case 'acid_number':
      case 'acid':
        return l.smartExtractorFieldAcidNo;
      case 'importer_tax_id':
        return l.smartExtractorFieldImporterTaxId;
      case 'supplier_name':
      case 'supplier':
      case 'shipper':
        return l.smartExtractorFieldSupplier;
      case 'importer_name':
      case 'importer':
      case 'consignee':
        return l.smartExtractorFieldImporter;
      case 'incoterm':
      case 'incoterms':
        return l.smartExtractorFieldIncoterms;
      case 'total_amount':
      case 'total_value':
      case 'invoice_value':
        return l.smartExtractorFieldTotalAmount;
      case 'currency':
        return isArabic ? 'العملة' : 'Currency';
      case 'gross_weight_kg':
      case 'total_gross_weight':
        return l.smartExtractorFieldTotalGrossWeight;
      case 'bl_number':
      case 'bl_no':
        return l.smartExtractorFieldBlNo;
      case 'carrier_name':
      case 'carrier':
        return l.smartExtractorFieldCarrier;
      case 'pol':
      case 'port_of_loading':
        return l.smartExtractorFieldPol;
      case 'pod':
      case 'port_of_discharge':
        return l.smartExtractorFieldPod;
      case 'total_cbm':
        return l.smartExtractorFieldTotalCbm;
      case 'total_packages':
      case 'packages_count':
        return l.smartExtractorFieldPackagesCount;
      case 'containers':
        return isArabic ? 'الحاويات' : 'Containers';
      default:
        return key.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
  }

  Widget _buildDataSummaryCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, dynamic> data,
  }) {
    final l = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
            final displayLabel = _localizeDataKey(e.key, l, isArabic);
            final valStr = '${e.value}';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      '$displayLabel:',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: CopyableText(
                      valStr,
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
    final l = context.l10n;
    final letter = (_matchResult?['correction_letter'] ?? '').toString();

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
              Expanded(
                child: Text(
                  l.invoiceBlMatcherCorrectionLetterTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  CopyHelper.copy(
                    context,
                    letter,
                    customMessage: l.invoiceBlMatcherLetterCopiedSuccess,
                  );
                },
                icon: const Icon(Icons.copy, size: 14),
                label: Text(l.invoiceBlMatcherCopyLetterButton),
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
    final l = context.l10n;
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
                Text(
                  l.invoiceBlMatcherSyncFooterTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                ),
                Text(
                  _activeFileId != null
                      ? l.invoiceBlMatcherSyncFooterDesc
                      : l.invoiceBlMatcherSyncFooterNoFile,
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
            label: Text(l.invoiceBlMatcherExportReportButton, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            label: Text(
              l.invoiceBlMatcherCertifySyncButton,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
    final l = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final score = _matchResult?['match_score_percentage'] ?? 0;
    final status = _matchResult?['overall_status'] ?? 'UNKNOWN';
    final isSafe = _matchResult?['is_safe_for_certification'] == true;
    final criticals = (_matchResult?['critical_discrepancies_count'] as num?)?.toInt() ?? 0;
    final warnings = (_matchResult?['warning_discrepancies_count'] as num?)?.toInt() ?? 0;
    final matrix = _matchResult?['comparison_matrix'] as List<dynamic>? ?? [];
    final correctionLetter = _matchResult?['correction_letter']?.toString() ?? '';

    final reportBuffer = StringBuffer();
    reportBuffer.writeln('===============================================================');
    reportBuffer.writeln('    ${l.invoiceBlMatcherReportDialogTitle}');
    reportBuffer.writeln('===============================================================');
    reportBuffer.writeln(l.invoiceBlMatcherReportMatchRatio(score));
    reportBuffer.writeln('${l.invoiceBlMatcherColMatchStatus} : $status');
    reportBuffer.writeln('${l.invoiceBlMatcherSyncFooterTitle} : ${isSafe ? l.reqBadgeYes : l.reqBadgeNo}');
    reportBuffer.writeln(l.invoiceBlMatcherCriticalCount(criticals));
    reportBuffer.writeln(l.invoiceBlMatcherWarningCount(warnings));
    reportBuffer.writeln('---------------------------------------------------------------');
    reportBuffer.writeln('${l.invoiceBlMatcherColCheckItem}\t${l.invoiceBlMatcherColInvoiceValue}\t${l.invoiceBlMatcherColBlValue}\t${l.invoiceBlMatcherColMatchStatus}\t${l.invoiceBlMatcherColActionRequired}');
    for (final row in matrix) {
      final r = row as Map<String, dynamic>;
      final checkItem = isArabic ? (r['field_name_ar'] ?? r['field_name_en'] ?? '') : (r['field_name_en'] ?? r['field_name_ar'] ?? '');
      final invVal = r['invoice_value'] ?? '—';
      final blVal = r['bl_value'] ?? '—';
      final matchStat = r['match_status'] == 'MATCH'
          ? l.invoiceBlMatcherStatusMatch
          : (r['match_status'] == 'MISMATCH_MINOR' ? l.invoiceBlMatcherStatusMinor : l.invoiceBlMatcherStatusMismatch);
      final details = r['details'] ?? '';
      reportBuffer.writeln('$checkItem\t$invVal\t$blVal\t$matchStat\t$details');
    }
    if (correctionLetter.isNotEmpty) {
      reportBuffer.writeln('---------------------------------------------------------------');
      reportBuffer.writeln('${l.invoiceBlMatcherCorrectionLetterTitle}:');
      reportBuffer.writeln(correctionLetter);
    }
    reportBuffer.writeln('===============================================================');

    final reportText = reportBuffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.cobalt),
            const SizedBox(width: 10),
            Text(l.invoiceBlMatcherReportDialogTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 480,
          child: SelectionArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l.invoiceBlMatcherReportMatchRatio(score)}  |  ${isSafe ? l.invoiceBlMatcherReportSafeStatus : l.invoiceBlMatcherReportUnsafeStatus}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSafe ? AppTheme.emerald : AppTheme.crimson,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(l.invoiceBlMatcherCopyReportButton),
                      onPressed: () {
                        CopyHelper.copy(
                          context,
                          reportText,
                          customMessage: l.invoiceBlMatcherReportCopiedSuccess,
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
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.invoiceBlMatcherCloseButton)),
        ],
      ),
    );
  }
}
