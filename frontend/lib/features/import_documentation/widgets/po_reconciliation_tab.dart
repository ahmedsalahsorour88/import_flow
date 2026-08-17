import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../models/import_documentation_model.dart';
import '../providers/import_documentation_provider.dart';


class POReconciliationTab extends ConsumerStatefulWidget {
  final int? initialImportFileId;
  const POReconciliationTab({super.key, this.initialImportFileId});

  @override
  ConsumerState<POReconciliationTab> createState() => _POReconciliationTabState();
}

class _POReconciliationTabState extends ConsumerState<POReconciliationTab> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedImportFileId;
  final TextEditingController _finalInvNumberCtrl = TextEditingController();
  final TextEditingController _finalPLNumberCtrl = TextEditingController();

  List<POReconciliationItemModel> _invoiceItems = [];
  List<POReconciliationItemModel> _packingItems = [];
  bool _isSubmitting = false;
  POReconciliationResultModel? _reconciliationResult;

  // --- SMART EXTRACTION & 3-WAY RECONCILIATION TOOL STATE ---
  bool _showSmartExtractionTool = true;
  bool _isExtracting = false;
  final TextEditingController _invoiceTextCtrl = TextEditingController();
  final TextEditingController _packingTextCtrl = TextEditingController();
  String? _selectedInvoiceFileName;
  String? _selectedPackingFileName;
  Uint8List? _invoiceFileBytes;
  Uint8List? _packingFileBytes;
  Map<String, dynamic>? _extractedReconciliationData;

  static const String sampleGIIndustrialInvoice = '''
G.I. INDUSTRIAL HOLDING SPA
Via G. Agnelli, 7 - 33053 Latisana (UD) - Italy
P.IVA IT01982510305
COMMERCIAL INVOICE Date 30/06/2026 Page 1
V1/ 2562
Client id. no. 801765
V.A.T. ID Number 200183044
Messrs
ECO ASSOCIATES
7 HOSNI OSMAN ST., SEFARAT DISTRICT
11471 NASR CITY, CAIRO
Egitto
Payment condition 100% AVV. MERCE PRONTA-PICK UP CONF.
Bank IT80Q0503412301USD100004026
SWIFT BAPPIT21682
Shipping - Delivery terms - As per INCOTERMS 2020
EX WORKS EXTRA UE

Your order ECO/049/2026/REV00
Our order confirmation M26 413 date 5/03/26
Commessa 27/360012
CYK4R6018210001 RTAXT/K/EC/MS 182 IM/RFM/RFL/PF/NS DOUBLE SKIN PACKAGED ROOF TOP 84158200 2,000 NR 18.602,37500 37.204,75 NI
QCR12026802R AG - RUBBER SHOCK ABSORBERS 2,000 NR 268,12500 536,25 NI

ACID NR. 2001830441013710010
IMPORTER TAX ID: 200183044
EXPORTER REGISTRATION NUMBER: 01982510305

Total goods 37.741,00
TOTAL INVOICE AMOUNT 37.741,00 EUR
Net weight kg 2.254,000
Gross weight kg 2.274,000
Packages 4
''';

  static const String sampleGIIndustrialPackingList = '''
Latisana, 30/06/2026
ECO ASSOCIATES
7 HOSNI OSMAN ST. SEFARAT DISTRICT
11471 NASR CITY, CAIRO
EGYPT

NOSTRO ORDINE / OUR ORDER M26 413
COMMESSA 27/360012
VOSTRO ORDINE / YOUR ORDER ECO/049/2026/REV00
ACID NUMBER 2001830441013710010

PACKING AND WEIGHT LIST
DESCRIZIONE / DESCRIPTION Q.TY (NO) LENGTH (mm.) WIDTH (mm.) HEIGHT (mm.) NET (KG) GROSS (KG) (NO) (TYPE)
RTAXT/K/EC/MS 182 IM/RFM/RFL/PF/NS 2 3950 2250 2250 2250 2270 2 PACKAGE
QCR12026802R 1 275 265 160 4 4 2 BOX
KG / COLLI 2254,0 2274,0 4,0 TOTAL
''';

  @override
  void initState() {
    super.initState();
    _selectedImportFileId = widget.initialImportFileId;
    Future.microtask(() async {
      await ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      if (_selectedImportFileId != null && mounted) {
        _loadPOItems(_selectedImportFileId!);
      }
    });
  }

  void _loadSampleData() {
    setState(() {
      _invoiceTextCtrl.text = sampleGIIndustrialInvoice.trim();
      _packingTextCtrl.text = sampleGIIndustrialPackingList.trim();
      _selectedInvoiceFileName = 'Commercial_Invoice_V1_2562.pdf';
      _selectedPackingFileName = 'Packing_and_Weight_List_M26_413.pdf';
      _invoiceFileBytes = null;
      _packingFileBytes = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✔ تم تحميل النموذج التجريبي الحقيقي (G.I. INDUSTRIAL / ECO ASSOCIATES) بنجاح'),
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickFile(bool isInvoice) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'csv', 'xlsx', 'docx', 'doc', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final ext = (file.name.split('.').last).toLowerCase();
        final isTextFormat = ['txt', 'csv', 'json', 'xml', 'log'].contains(ext);

        setState(() {
          if (isInvoice) {
            _selectedInvoiceFileName = file.name;
            _invoiceFileBytes = file.bytes;
            if (isTextFormat && file.bytes != null) {
              try {
                _invoiceTextCtrl.text = utf8.decode(file.bytes!, allowMalformed: true);
              } catch (_) {
                _invoiceTextCtrl.text = '';
              }
            } else {
              // For binary PDF/DOC/XLSX, do NOT put raw binary into the text controller to avoid browser hang
              _invoiceTextCtrl.text = '[تم تحميل ملف رقمي: ${file.name} — سيتم استخراج ومعالجة بنوده آلياً عند الضغط على زر الاستخراج والمطابقة]';
            }
          } else {
            _selectedPackingFileName = file.name;
            _packingFileBytes = file.bytes;
            if (isTextFormat && file.bytes != null) {
              try {
                _packingTextCtrl.text = utf8.decode(file.bytes!, allowMalformed: true);
              } catch (_) {
                _packingTextCtrl.text = '';
              }
            } else {
              // For binary PDF/DOC/XLSX, do NOT put raw binary into the text controller to avoid browser hang
              _packingTextCtrl.text = '[تم تحميل ملف رقمي: ${file.name} — سيتم استخراج ومعالجة بنوده آلياً عند الضغط على زر الاستخراج والمطابقة]';
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✔ تم اختيار ملف ${file.name} بنجاح'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء اختيار الملف: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runSmartExtractionAndComparison() async {
    final hasInvoiceFile = _invoiceFileBytes != null;
    final hasPackingFile = _packingFileBytes != null;
    final invText = _invoiceTextCtrl.text.trim();
    final plText = _packingTextCtrl.text.trim();

    final hasInvContent = hasInvoiceFile || (invText.isNotEmpty && !invText.startsWith('[تم تحميل'));
    final hasPlContent = hasPackingFile || (plText.isNotEmpty && !plText.startsWith('[تم تحميل'));

    if (!hasInvContent && !hasPlContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال أو رفع نص الفاتورة و/أو قائمة التعبئة أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isExtracting = true);
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      Response response;

      if (hasInvoiceFile || hasPackingFile) {
        // Use Multipart upload endpoint for binary/pdf files
        final formData = FormData();
        if (_selectedImportFileId != null) {
          formData.fields.add(MapEntry('import_file_id', _selectedImportFileId.toString()));
        }

        if (hasInvoiceFile) {
          formData.files.add(MapEntry(
            'invoice_file',
            MultipartFile.fromBytes(_invoiceFileBytes!, filename: _selectedInvoiceFileName ?? 'invoice.pdf'),
          ));
        } else if (invText.isNotEmpty && !invText.startsWith('[تم تحميل')) {
          formData.fields.add(MapEntry('invoice_text', invText));
        }

        if (hasPackingFile) {
          formData.files.add(MapEntry(
            'packing_file',
            MultipartFile.fromBytes(_packingFileBytes!, filename: _selectedPackingFileName ?? 'packing_list.pdf'),
          ));
        } else if (plText.isNotEmpty && !plText.startsWith('[تم تحميل')) {
          formData.fields.add(MapEntry('packing_text', plText));
        }

        response = await dio.post(
          '${ApiConstants.baseUrl}/import-documentation/po-reconciliation/extract-files-and-compare',
          data: formData,
        );
      } else {
        // Use JSON endpoint for pure text
        final payload = {
          'import_file_id': _selectedImportFileId,
          'invoice_raw_text': invText,
          'packing_list_raw_text': plText,
          'system_items': _invoiceItems.map((i) => i.toJson()).toList(),
        };

        response = await dio.post(
          '${ApiConstants.baseUrl}/import-documentation/po-reconciliation/extract-and-compare',
          data: payload,
        );
      }

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _extractedReconciliationData = response.data;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✔ تم الاستخراج الذكي والمطابقة مع بيانات السستم بنجاح! راجع الفوارق بالجدول أدناه.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الاستخراج والمطابقة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }


  void _applyExtractedDataToTables() {
    if (_extractedReconciliationData == null) return;

    final invData = _extractedReconciliationData!['extracted_invoice_data'] as Map<String, dynamic>? ?? {};
    final plData = _extractedReconciliationData!['extracted_packing_data'] as Map<String, dynamic>? ?? {};
    final recInv = (_extractedReconciliationData!['reconciled_invoice_items'] as List<dynamic>? ?? [])
        .map((x) => POReconciliationItemModel.fromJson(x as Map<String, dynamic>))
        .toList();
    final recPl = (_extractedReconciliationData!['reconciled_packing_items'] as List<dynamic>? ?? [])
        .map((x) => POReconciliationItemModel.fromJson(x as Map<String, dynamic>))
        .toList();

    setState(() {
      if (invData['invoice_number'] != null && invData['invoice_number'].toString().isNotEmpty) {
        _finalInvNumberCtrl.text = invData['invoice_number'].toString();
      }
      if (plData['packing_list_number'] != null && plData['packing_list_number'].toString().isNotEmpty) {
        _finalPLNumberCtrl.text = plData['packing_list_number'].toString();
      } else if (_selectedPackingFileName != null && _finalPLNumberCtrl.text.isEmpty) {
        _finalPLNumberCtrl.text = _selectedPackingFileName!.replaceAll(RegExp(r'\.(pdf|txt|csv|docx|xlsx)$', caseSensitive: false), '');
      }

      if (recInv.isNotEmpty) {
        _invoiceItems = recInv;
      }
      if (recPl.isNotEmpty) {
        _packingItems = recPl;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✔ تم تطبيق كافة البيانات والكميات والأسعار والأوزان المستخرجة في جداول المطابقة بنجاح!'),
        backgroundColor: Colors.teal,
      ),
    );
  }



  @override
  void didUpdateWidget(covariant POReconciliationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImportFileId != oldWidget.initialImportFileId && widget.initialImportFileId != null) {
      _selectedImportFileId = widget.initialImportFileId;
      Future.microtask(() async {
        await ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
        if (mounted) _loadPOItems(_selectedImportFileId!);
      });
    }
  }

  void _loadPOItems(int fileId) {
    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file == null) return;

    _finalInvNumberCtrl.text = file.piNumber ?? 'INV-FINAL-${file.importFileCode}';
    _finalPLNumberCtrl.text = 'PL-FINAL-${file.importFileCode}';

    final poList = ref.read(purchaseOrdersProvider).purchaseOrders;
    final linkedPOs = poList.where((p) => p.importFileId == fileId || (file.poIds?.contains(p.poId) ?? false)).toList();

    List<POReconciliationItemModel> invList = [];
    List<POReconciliationItemModel> plList = [];

    for (var po in linkedPOs) {
      // 1. Load Commercial Invoice Line Items for Section 1
      for (var itm in po.items) {
        invList.add(POReconciliationItemModel(
          poItemId: itm.itemId,
          itemCode: (itm.itemCode != null && itm.itemCode!.isNotEmpty) ? itm.itemCode! : '1',
          description: itm.descriptionAr.isNotEmpty ? itm.descriptionAr : (itm.descriptionEn ?? 'بند الفاتورة'),
          hsCode: itm.hsCode,
          packageType: 'Carton',
          initialQuantity: itm.quantity,
          finalQuantity: itm.quantity,
          initialUnitPrice: itm.unitPrice,
          unitPrice: itm.unitPrice,
          finalUnitPrice: itm.unitPrice,
          initialPackagesCount: 1.0,
          finalPackagesCount: 1.0,
          initialNetWeightKg: itm.netWeightKg,
          finalNetWeightKg: itm.netWeightKg,
          initialGrossWeightKg: itm.grossWeightKg,
          finalGrossWeightKg: itm.grossWeightKg,
          initialCbm: itm.totalCbm,
          finalCbm: itm.totalCbm,
          variancePercentage: 0.0,
          priceVariancePercentage: 0.0,
          weightVariancePercentage: 0.0,
        ));
      }

      // 2. Load Packing List Breakdown for Section 2
      if (po.packingListItems.isNotEmpty) {
        for (int i = 0; i < po.packingListItems.length; i++) {
          final pl = po.packingListItems[i];

          double initPackages = pl.qtyPkg > 0 ? pl.qtyPkg : 1.0;
          double initNetW = (pl.netWeightUnitKg > 0 && pl.qtyPkg > 0)
              ? (pl.netWeightUnitKg * pl.qtyPkg)
              : (pl.totalNetWeightKg > 0 ? pl.totalNetWeightKg : 0.0);
          double initGrossW = (pl.grossWeightUnitKg > 0 && pl.qtyPkg > 0)
              ? (pl.grossWeightUnitKg * pl.qtyPkg)
              : (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : 0.0);
          double initCbm = (pl.calculatedCbm > 0)
              ? pl.calculatedCbm
              : (pl.totalCbm > 0 ? pl.totalCbm : 0.0);
          String pkgType = pl.packageType.isNotEmpty ? pl.packageType : 'Carton';
          String code = pl.itemCode.isNotEmpty ? pl.itemCode : 'PL-${i + 1}';

          plList.add(POReconciliationItemModel(
            poItemId: (pl.packingItemId != null && pl.packingItemId! > 0) ? pl.packingItemId : (i + 1),
            itemCode: code,
            description: pl.itemCode.isNotEmpty ? pl.itemCode : 'بند تعبئة $pkgType (${initPackages.toInt()} طرد)',
            hsCode: pl.hsCode,
            packageType: pkgType,
            initialQuantity: pl.qtyPcs > 0 ? pl.qtyPcs : initPackages,
            finalQuantity: pl.qtyPcs > 0 ? pl.qtyPcs : initPackages,
            initialUnitPrice: 0.0,
            unitPrice: 0.0,
            finalUnitPrice: 0.0,
            initialPackagesCount: initPackages,
            finalPackagesCount: initPackages,
            initialNetWeightKg: initNetW,
            finalNetWeightKg: initNetW,
            initialGrossWeightKg: initGrossW,
            finalGrossWeightKg: initGrossW,
            initialCbm: initCbm,
            finalCbm: initCbm,
            variancePercentage: 0.0,
            priceVariancePercentage: 0.0,
            weightVariancePercentage: 0.0,
          ));
        }
      }
    }

    if (invList.isEmpty) {
      invList = [
        POReconciliationItemModel(
          itemCode: 'ITEM-001',
          description: 'Industrial Control & Equipment Unit',
          packageType: 'Carton',
          initialQuantity: 100.0,
          finalQuantity: 100.0,
          initialUnitPrice: 250.0,
          unitPrice: 250.0,
          finalUnitPrice: 250.0,
          initialPackagesCount: 10.0,
          finalPackagesCount: 10.0,
          initialNetWeightKg: 20700.0,
          finalNetWeightKg: 20700.0,
          initialGrossWeightKg: 24500.0,
          finalGrossWeightKg: 24500.0,
          initialCbm: 58.4,
          finalCbm: 58.4,
        ),
      ];
    }

    if (plList.isEmpty) {
      plList = invList.map((inv) => inv).toList();
    }

    setState(() {
      _invoiceItems = invList;
      _packingItems = plList;
    });
  }

  Future<void> _submitCertification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Send both invoice items and packing list items for certification
      final combined = [..._invoiceItems, ..._packingItems];
      final payload = {
        'import_file_id': _selectedImportFileId,
        'final_invoice_number': _finalInvNumberCtrl.text.trim(),
        'final_packing_list_number': _finalPLNumberCtrl.text.trim(),
        'items': combined.map((i) => i.toJson()).toList(),
      };

      final res = await ref.read(poReconciliationProvider).submitPOFinalReconciliation(payload);
      setState(() {
        _reconciliationResult = res;
      });

      ref.invalidate(importFilesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✔ تم اعتماد الأرقام النهائية للفاتورة والباكينج ليست بنجاح وتحديث بيانات المنظومة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الاعتماد: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    double totalAmount = _invoiceItems.fold(0.0, (s, itm) => s + (itm.finalQuantity * (itm.finalUnitPrice > 0 ? itm.finalUnitPrice : itm.unitPrice)));
    double totalPackages = _packingItems.fold(0.0, (s, itm) => s + itm.finalPackagesCount);
    double totalGrossWeight = _packingItems.fold(0.0, (s, itm) => s + itm.finalGrossWeightKg);
    double totalNetWeight = _packingItems.fold(0.0, (s, itm) => s + itm.finalNetWeightKg);
    double totalCbm = _packingItems.fold(0.0, (s, itm) => s + itm.finalCbm);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.fact_check, color: AppTheme.cobalt, size: 28),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'مراجعة وتأكيد الفاتورة التجارية والباكينج ليست النهائية (PO Final Reconciliation & Review)',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_reconciliationResult != null)

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'معتمدة ومحدثة في المنظومة',
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'البيانات والكميات والأسعار والأوزان المعتمدة هنا هي المرجع الحاكم لدرافت البوليصة، والمخزون بالطريق، والإفراج الجمركي، واستلام المخزن.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SearchableDropdownField<int>(
                            value: _selectedImportFileId,
                            labelText: 'ملف الشحنة الاستيرادي *',
                            searchHintText: 'ابحث برقم الملف أو كود الشحنة...',
                            items: importFiles
                                .map((f) => SearchableDropdownItem<int>(
                                      value: f.importFileId,
                                      label: '${f.importFileCode} - ${f.companyName} (${f.supplierName})',
                                    ))
                                .toList(),
                            onChanged: (v) async {
                              if (v != null) {
                                setState(() => _selectedImportFileId = v);
                                await ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
                                if (mounted) _loadPOItems(v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _finalInvNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'رقم الفاتورة التجارية النهائية *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.receipt_long),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _finalPLNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'رقم قائمة التعبئة النهائية *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory_2),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SMART EXTRACTION & 3-WAY RECONCILIATION TOOL CARD
            _buildSmartExtractionCard(),
            const SizedBox(height: 20),

            // Summary Metrics Cards
            Row(
              children: [
                _buildSummaryCard('إجمالي الفاتورة النهائية', '${totalAmount.toStringAsFixed(2)} \$', Icons.monetization_on, AppTheme.cobalt),
                const SizedBox(width: 12),
                _buildSummaryCard('إجمالي الطرود الفعلية', '${totalPackages.toStringAsFixed(0)} طرد', Icons.all_inbox, AppTheme.charcoal),
                const SizedBox(width: 12),
                _buildSummaryCard('إجمالي الوزن القائم (Gross)', '${totalGrossWeight.toStringAsFixed(2)} كجم', Icons.scale, AppTheme.orange),
                const SizedBox(width: 12),
                _buildSummaryCard('إجمالي الوزن الصافي (Net)', '${totalNetWeight.toStringAsFixed(2)} كجم', Icons.fitness_center, AppTheme.emerald),
                const SizedBox(width: 12),
                _buildSummaryCard('إجمالي الحجم (CBM)', '${totalCbm.toStringAsFixed(3)} م³', Icons.view_in_ar, AppTheme.cobalt),
              ],
            ),
            const SizedBox(height: 20),

            // SECTION 1: INVOICE & PRICE RECONCILIATION TABLE
            Card(
              elevation: 2,

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.receipt, color: AppTheme.cobalt),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '1. مراجعة وتأكيد بنود وأسعار الفاتورة التجارية النهائية (Invoice Items & Price Review)',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.charcoal,
                                side: const BorderSide(color: AppTheme.charcoal),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              icon: const Icon(Icons.restart_alt, size: 16),
                              label: const Text('إعادة تعيين للقيم الأصلية', style: TextStyle(fontSize: 12.5)),
                              onPressed: () {
                                if (_selectedImportFileId != null) {
                                  _loadPOItems(_selectedImportFileId!);
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(

                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cobalt,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              icon: _isSubmitting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.verified, color: Colors.white),
                              label: const Text('اعتماد ومطابقة البيانات النهائية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: _isSubmitting ? null : _submitCertification,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_invoiceItems.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Text('يرجى اختيار ملف الشحنة لعرض بنود أمر الشراء للمطابقة', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(label: Text('كود الصنف')),
                            DataColumn(label: Text('الوصف')),
                            DataColumn(label: Text('كمية PO')),
                            DataColumn(label: Text('الكمية النهائية *')),
                            DataColumn(label: Text('فارق الكمية %')),
                            DataColumn(label: Text('سعر الوحدة (PO) \$')),
                            DataColumn(label: Text('* مراجعة السعر النهائي \$')),
                            DataColumn(label: Text('فارق السعر %')),
                            DataColumn(label: Text('إجمالي الفاتورة (\$)')),
                          ],
                          rows: _invoiceItems.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var itm = entry.value;
                            double currentPrice = itm.finalUnitPrice > 0 ? itm.finalUnitPrice : itm.unitPrice;
                            double lineTotal = itm.finalQuantity * currentPrice;
                            double priceVariance = itm.initialUnitPrice > 0 ? ((currentPrice - itm.initialUnitPrice) / itm.initialUnitPrice) * 100.0 : 0.0;
                            double qtyVariance = itm.initialQuantity > 0 ? ((itm.finalQuantity - itm.initialQuantity) / itm.initialQuantity) * 100.0 : 0.0;

                            return DataRow(cells: [
                              DataCell(Text(itm.itemCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(SizedBox(width: 220, child: Text(itm.description, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))),
                              DataCell(Text(itm.initialQuantity.toStringAsFixed(1))),
                              DataCell(
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    initialValue: itm.finalQuantity.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      double? q = double.tryParse(v);
                                      if (q != null) {
                                        setState(() {
                                          _invoiceItems[idx] = itm.copyWith(
                                            finalQuantity: q,
                                            variancePercentage: itm.initialQuantity > 0 ? ((q - itm.initialQuantity) / itm.initialQuantity) * 100.0 : 0.0,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(_buildVarianceBadge(qtyVariance)),
                              DataCell(Text(itm.initialUnitPrice.toStringAsFixed(2))),
                              DataCell(
                                SizedBox(
                                  width: 110,
                                  child: TextFormField(
                                    initialValue: currentPrice.toStringAsFixed(2),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      prefixText: '\$ ',
                                      contentPadding: EdgeInsets.all(6),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) {
                                      double? p = double.tryParse(v);
                                      if (p != null) {
                                        setState(() {
                                          _invoiceItems[idx] = itm.copyWith(
                                            finalUnitPrice: p,
                                            unitPrice: p,
                                            priceVariancePercentage: itm.initialUnitPrice > 0 ? ((p - itm.initialUnitPrice) / itm.initialUnitPrice) * 100.0 : 0.0,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(_buildVarianceBadge(priceVariance)),
                              DataCell(Text('${lineTotal.toStringAsFixed(2)} \$', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                            ]);
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 2: PACKING LIST & ACTUAL WEIGHTS / PACKAGES RECONCILIATION TABLE
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.teal),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '2. مراجعة وتأكيد بيان العبوة والباكينج ليست النهائية (Packing List & Actual Packages/Weights)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      'مراجعة الأعداد الفعلية للطرود/الكراتين، والأوزان الصافية والقائمة الفعلية، والحجم الفعلي لتطابق درافت البوليصة والمخزن.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const Divider(height: 20),
                    if (_packingItems.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Text('يرجى اختيار ملف الشحنة لعرض بنود بيان التعبئة للمطابقة', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(label: Text('كود الصنف')),
                            DataColumn(label: Text('الوصف')),
                            DataColumn(label: Text('نوع التغليف')),
                            DataColumn(label: Text('طرود PO')),
                            DataColumn(label: Text('الطرود الفعلية بالباكينج *')),
                            DataColumn(label: Text('الصافي الأولي (كجم)')),
                            DataColumn(label: Text('الصافي الفعلي (كجم) *')),
                            DataColumn(label: Text('القائم الأولي (كجم)')),
                            DataColumn(label: Text('القائم الفعلي (كجم) *')),
                            DataColumn(label: Text('فارق الوزن %')),
                            DataColumn(label: Text('الحجم الأولي CBM')),
                            DataColumn(label: Text('الحجم الفعلي CBM *')),
                          ],
                          rows: _packingItems.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var itm = entry.value;
                            double weightVariance = itm.initialGrossWeightKg > 0
                                ? ((itm.finalGrossWeightKg - itm.initialGrossWeightKg) / itm.initialGrossWeightKg) * 100.0
                                : 0.0;

                            return DataRow(cells: [
                              DataCell(Text(itm.itemCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(SizedBox(width: 150, child: Text(itm.description, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                              DataCell(
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    initialValue: itm.packageType,
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      _packingItems[idx] = itm.copyWith(packageType: v);
                                    },
                                  ),
                                ),
                              ),
                              DataCell(Text(itm.initialPackagesCount.toStringAsFixed(0))),
                              DataCell(
                                SizedBox(
                                  width: 75,
                                  child: TextFormField(
                                    initialValue: itm.finalPackagesCount.toStringAsFixed(0),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      double? p = double.tryParse(v);
                                      if (p != null) {
                                        setState(() {
                                          _packingItems[idx] = itm.copyWith(finalPackagesCount: p);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(Text(itm.initialNetWeightKg.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade700))),
                              DataCell(
                                SizedBox(
                                  width: 85,
                                  child: TextFormField(
                                    initialValue: itm.finalNetWeightKg.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      double? p = double.tryParse(v);
                                      if (p != null) {
                                        setState(() {
                                          _packingItems[idx] = itm.copyWith(finalNetWeightKg: p);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(Text(itm.initialGrossWeightKg.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade700))),
                              DataCell(
                                SizedBox(
                                  width: 85,
                                  child: TextFormField(
                                    initialValue: itm.finalGrossWeightKg.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      double? p = double.tryParse(v);
                                      if (p != null) {
                                        setState(() {
                                          _packingItems[idx] = itm.copyWith(
                                            finalGrossWeightKg: p,
                                            weightVariancePercentage: itm.initialGrossWeightKg > 0 ? ((p - itm.initialGrossWeightKg) / itm.initialGrossWeightKg) * 100.0 : 0.0,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(_buildVarianceBadge(weightVariance)),
                              DataCell(Text(itm.initialCbm.toStringAsFixed(3), style: TextStyle(color: Colors.grey.shade700))),
                              DataCell(
                                SizedBox(
                                  width: 85,
                                  child: TextFormField(
                                    initialValue: itm.finalCbm.toString(),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      double? p = double.tryParse(v);
                                      if (p != null) {
                                        setState(() {
                                          _packingItems[idx] = itm.copyWith(finalCbm: p);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2)),
                  const SizedBox(height: 3),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVarianceBadge(double variance) {
    bool isZero = variance == 0.0;
    bool isPositive = variance > 0;
    Color color = isZero ? Colors.grey : (isPositive ? Colors.green : Colors.red);
    String text = isZero ? '0.0%' : '${isPositive ? '+' : ''}${variance.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  // --- SMART EXTRACTION & 3-WAY RECONCILIATION CARD WIDGET ---
  Widget _buildSmartExtractionCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.cobalt.withOpacity(0.35), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar with Toggle & 1-Click Sample
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppTheme.cobalt, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚡ أداة الرفع والاستخراج الذكي والمطابقة الثلاثية (Smart 3-Way Extractor & Matcher)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'استخراج بنود الفاتورة النهائية وقائمة التعبئة ومطابقتها آلياً مع أمر الشراء بالسستم وكشف الفوارق',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A085),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.dataset_linked, size: 16),
                      label: const Text('تحميل نموذج تجريبي حقيقي (G.I. INDUSTRIAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _loadSampleData,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _showSmartExtractionTool ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppTheme.charcoal,
                      ),
                      tooltip: _showSmartExtractionTool ? 'إخفاء الأداة' : 'عرض الأداة',
                      onPressed: () {
                        setState(() => _showSmartExtractionTool = !_showSmartExtractionTool);
                      },
                    ),
                  ],
                ),
              ],
            ),


            if (_showSmartExtractionTool) ...[
              const Divider(height: 24),
              // Side by Side Input Boxes
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: Commercial Invoice Input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.receipt_long, color: AppTheme.cobalt, size: 20),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '1. الفاتورة التجارية النهائية (Commercial Invoice)',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 11),
                                    ),
                                    icon: const Icon(Icons.upload_file, size: 14),
                                    label: Text(_selectedInvoiceFileName != null ? 'تغيير الملف' : 'رفع ملف PDF/Text'),
                                    onPressed: () => _pickFile(true),
                                  ),
                                  if (_invoiceTextCtrl.text.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                      tooltip: 'مسح',
                                      onPressed: () {
                                        setState(() {
                                          _invoiceTextCtrl.clear();
                                          _selectedInvoiceFileName = null;
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (_selectedInvoiceFileName != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.attach_file, size: 13, color: AppTheme.cobalt),
                                  const SizedBox(width: 4),
                                  Text(_selectedInvoiceFileName!, style: const TextStyle(fontSize: 11.5, color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _invoiceTextCtrl,
                            maxLines: 7,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'الصق نص الفاتورة التجارية هنا أو ارفع الملف...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // RIGHT: Packing and Weight List Input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.inventory_2, color: Colors.teal, size: 20),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '2. قائمة التعبئة والأوزان (Packing & Weight List)',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 11),
                                    ),
                                    icon: const Icon(Icons.upload_file, size: 14),
                                    label: Text(_selectedPackingFileName != null ? 'تغيير الملف' : 'رفع ملف PDF/Text'),
                                    onPressed: () => _pickFile(false),
                                  ),
                                  if (_packingTextCtrl.text.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                      tooltip: 'مسح',
                                      onPressed: () {
                                        setState(() {
                                          _packingTextCtrl.clear();
                                          _selectedPackingFileName = null;
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (_selectedPackingFileName != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.attach_file, size: 13, color: Colors.teal),
                                  const SizedBox(width: 4),
                                  Text(_selectedPackingFileName!, style: const TextStyle(fontSize: 11.5, color: Colors.teal, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _packingTextCtrl,
                            maxLines: 7,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'الصق نص بيان التعبئة والأوزان هنا أو ارفع الملف...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Execute Button
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  icon: _isExtracting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.compare_arrows, size: 20),
                  label: Text(
                    _isExtracting ? 'جاري الاستخراج والمطابقة الذكية...' : '⚡ تنفيذ الاستخراج الذكي والمطابقة مع بيانات السستم',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: _isExtracting ? null : _runSmartExtractionAndComparison,
                ),
              ),

              // Discrepancies Result Section
              if (_extractedReconciliationData != null) ...[
                const SizedBox(height: 20),
                _buildDiscrepanciesResultSection(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscrepanciesResultSection() {
    final overallStatus = _extractedReconciliationData!['overall_status'] as String? ?? 'FULLY_MATCHED';
    final headerDiscrepancies = _extractedReconciliationData!['header_discrepancies'] as List<dynamic>? ?? [];
    final invData = _extractedReconciliationData!['extracted_invoice_data'] as Map<String, dynamic>? ?? {};
    final plData = _extractedReconciliationData!['extracted_packing_data'] as Map<String, dynamic>? ?? {};

    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    if (overallStatus == 'FULLY_MATCHED') {
      statusColor = Colors.green;
      statusTitle = '🟢 مطابقة ناجحة 100% — لا توجد أي فوارق جوهرية أو مخالفات جمركية';
      statusIcon = Icons.check_circle;
    } else if (overallStatus == 'ACCEPTED_WITH_WARNINGS') {
      statusColor = Colors.orange.shade800;
      statusTitle = '🟡 مطابقة مقبولة مع وجود فوارق طفيفة مسموح بها في الأوزان أو الكميات';
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = Colors.red;
      statusTitle = '❌ تم اكتشاف فوارق حرجة في رقم ACID أو البطاقة الضريبية تتطلب المراجعة قبل الاعتماد!';
      statusIcon = Icons.error_outline;
    }


    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Strip Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 22),
                  const SizedBox(width: 8),
                  Text(statusTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: statusColor)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.playlist_add_check, size: 18),
                label: const Text('✔ تطبيق البيانات المستخرجة في جداول المطابقة أدناه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _applyExtractedDataToTables,
              ),
            ],
          ),
          const Divider(height: 20),

          // Header Checks Table
          const Text('فحص ومطابقة البيانات الحاكمة (Header & Compliance Checks):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 44,
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('بند الفحص')),
                DataColumn(label: Text('القيمة بالسستم')),
                DataColumn(label: Text('القيمة بالمستند المرفوع')),
                DataColumn(label: Text('حالة المطابقة')),
                DataColumn(label: Text('التفاصيل')),
              ],
              rows: headerDiscrepancies.map((d) {
                final map = d as Map<String, dynamic>;
                final status = map['status'] as String? ?? 'MATCH';
                return DataRow(cells: [
                  DataCell(Text(map['field_name_ar'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                  DataCell(Text(map['system_value']?.toString() ?? '—', style: TextStyle(color: Colors.grey.shade800, fontSize: 12))),
                  DataCell(Text(map['extracted_value']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt))),
                  DataCell(_buildDiscrepancyBadge(status)),
                  DataCell(Text(map['details']?.toString() ?? '', style: TextStyle(fontSize: 12, color: status == 'MATCH' ? Colors.green.shade800 : Colors.red.shade800))),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Summary Key Extracted Values Preview
          Row(
            children: [
              _buildExtractedPill('رقم الفاتورة', invData['invoice_number']?.toString() ?? 'N/A', Icons.receipt),
              const SizedBox(width: 8),
              _buildExtractedPill('رقم ACID', invData['acid_number']?.toString() ?? plData['acid_number']?.toString() ?? 'N/A', Icons.security),
              const SizedBox(width: 8),
              _buildExtractedPill('المصدر الأجنبي', invData['shipper']?.toString() ?? 'N/A', Icons.business),
              const SizedBox(width: 8),
              _buildExtractedPill('إجمالي القيمة', '${invData['total_amount']?.toString() ?? '0'} ${invData['currency'] ?? 'EUR'}', Icons.payments),
              const SizedBox(width: 8),
              _buildExtractedPill('إجمالي الطرود', '${plData['total_packages']?.toString() ?? invData['qty_pkg']?.toString() ?? '0'} طرد', Icons.all_inbox),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscrepancyBadge(String status) {
    Color bg;
    Color fg;
    String label;

    if (status == 'MATCH') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      label = 'مطابق ✔';
    } else if (status == 'MINOR_VARIANCE') {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      label = 'فارق طفيف ⚠️';
    } else {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
      label = 'غير مطابق ❌';
    }


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildExtractedPill(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.cobalt),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

