import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../customs_tariff/models/customs_tariff_model.dart';
import '../../customs_tariff/widgets/tariff_form_dialog.dart';
import '../../../core/widgets/universal_entity_extractor_dialog.dart';
import '../../customs_tariff/providers/customs_tariff_provider.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../incoterms/providers/incoterms_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/purchase_order_model.dart';
import '../providers/purchase_orders_provider.dart';
import 'po_reconciliation_warning_dialog.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../currencies/models/currency_model.dart';


class POFormDialog extends ConsumerStatefulWidget {
  final PurchaseOrderModel? po;
  final Map<String, dynamic>? initialExtractedFields;

  const POFormDialog({super.key, this.po, this.initialExtractedFields});

  @override
  ConsumerState<POFormDialog> createState() => _POFormDialogState();
}

class _POFormDialogState extends ConsumerState<POFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _piCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _notesCtrl;

  late DateTime _selectedOrderDate;
  int? _selectedImportFileId;
  int? _selectedProjectId;
  int? _selectedCompanyId;
  int? _selectedSupplierId;
  int? _selectedIncotermId;
  int? _selectedCurrencyId;
  String? _selectedCountryOfOrigin;
  late String _selectedStatus;
  late String _selectedPaymentTerms;

  static String? normalizeCountryName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final clean = raw.trim().toUpperCase();
    final match = countryOptions.where((c) {
      final code = c['code']!.toUpperCase();
      final name = c['name']!.toUpperCase();
      return code == clean || name.contains(clean) || clean.contains(code) || 
             (clean == 'LITHUANIA' && (code == 'LT' || name.contains('LITHUANIA') || name.contains('ليتوانيا'))) || 
             (clean == 'ITALY' && (code == 'IT' || name.contains('ITALY') || name.contains('إيطاليا'))) || 
             (clean == 'CHINA' && (code == 'CN' || name.contains('CHINA') || name.contains('الصين')));
    }).firstOrNull;
    return match != null ? match['name'] : raw;
  }

  static const List<Map<String, String>> countryOptions = [
    {'code': 'CN', 'name': 'CN - الصين (China)'},
    {'code': 'DE', 'name': 'DE - ألمانيا (Germany)'},
    {'code': 'IT', 'name': 'IT - إيطاليا (Italy)'},
    {'code': 'LT', 'name': 'LT - ليتوانيا (Lithuania)'},
    {'code': 'TW', 'name': 'TW - تايوان (Taiwan)'},
    {'code': 'TR', 'name': 'TR - تركيا (Turkey)'},
    {'code': 'FR', 'name': 'FR - فرنسا (France)'},
    {'code': 'ES', 'name': 'ES - إسبانيا (Spain)'},
    {'code': 'GB', 'name': 'GB - المملكة المتحدة (United Kingdom)'},
    {'code': 'US', 'name': 'US - الولايات المتحدة الأمريكية (USA)'},
    {'code': 'BR', 'name': 'BR - البرازيل (Brazil)'},
    {'code': 'AR', 'name': 'AR - الأرجنتين (Argentina)'},
    {'code': 'IN', 'name': 'IN - الهند (India)'},
    {'code': 'JP', 'name': 'JP - اليابان (Japan)'},
    {'code': 'KR', 'name': 'KR - كوريا الجنوبية (South Korea)'},
    {'code': 'SA', 'name': 'SA - المملكة العربية السعودية (Saudi Arabia)'},
    {'code': 'AE', 'name': 'AE - الإمارات العربية المتحدة (UAE)'},
    {'code': 'JO', 'name': 'JO - الأردن (Jordan)'},
    {'code': 'MA', 'name': 'MA - المغرب (Morocco)'},
    {'code': 'TN', 'name': 'TN - تونس (Tunisia)'},
    {'code': 'LB', 'name': 'LB - لبنان (Lebanon)'},
    {'code': 'NL', 'name': 'NL - هولندا (Netherlands)'},
    {'code': 'BE', 'name': 'BE - بلجيكا (Belgium)'},
    {'code': 'AT', 'name': 'AT - النمسا (Austria)'},
    {'code': 'PL', 'name': 'PL - بولندا (Poland)'},
    {'code': 'SE', 'name': 'SE - السويد (Sweden)'},
    {'code': 'CH', 'name': 'CH - سويسرا (Switzerland)'},
    {'code': 'RU', 'name': 'RU - روسيا (Russia)'},
    {'code': 'VN', 'name': 'VN - فيتنام (Vietnam)'},
    {'code': 'TH', 'name': 'TH - تايلاند (Thailand)'},
    {'code': 'MY', 'name': 'MY - ماليزيا (Malaysia)'},
    {'code': 'ID', 'name': 'ID - إندونيسيا (Indonesia)'},
    {'code': 'EG', 'name': 'EG - مصر (Egypt)'},
  ];

  late List<POLineItemModel> _dialogItems;
  late List<PackingListItemModel> _dialogPackingItems;
  bool _isSubmitting = false;

  Future<CustomsTariffModel?> _showHsCodeSearchPicker(BuildContext context, List<CustomsTariffModel> tariffs) async {
    return showDialog<CustomsTariffModel?>(
      context: context,
      builder: (ctx) {
        String search = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = tariffs.where((t) {
              final query = search.trim().toLowerCase();
              if (query.isEmpty) return true;
              return t.hsCode.toLowerCase().contains(query) ||
                  t.hsDescription.toLowerCase().contains(query) ||
                  (t.customsCategory?.toLowerCase().contains(query) ?? false);
            }).toList();

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.search, color: AppTheme.cobalt),
                  SizedBox(width: 8),
                  Text('اختيار البند الجمركي (Customs Tariff / HS Code)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 600,
                height: 450,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'ابحث برقم البند الجمركي أو الوصف (مثال: 8415 أو تكييف)...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.cobalt),
                        suffixIcon: search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setDialogState(() => search = ''),
                              )
                            : null,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setDialogState(() => search = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('لا توجد نتائج مطابقة لمفتاح البحث'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final item = filtered[i];
                                return ListTile(
                                  dense: true,
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cobalt.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.hsCode,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.hsDescription,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'الفئة: ${item.customsCategory ?? "عام"} | جمارك: ${item.customsDutyRate}% | قيمة مضافة: ${item.vatRate}% | رسم تنمية: ${item.developmentFeeRate}%',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(ctx, item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('إلغاء'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateExchangeRateFromCurrency(int? currencyId, List<CurrencyModel> currencies) {
    if (currencyId == null) return;
    final curr = currencies.where((c) => c.currencyId == currencyId).firstOrNull;
    if (curr == null) return;
    if (curr.isBaseCurrency || curr.currencyCode == 'EGP') {
      _rateCtrl.text = '1.0';
      return;
    }

    double? foundRate;
    if (curr.exchangeRates != null && curr.exchangeRates!.isNotEmpty) {
      final orderDateStr = _selectedOrderDate.toString().substring(0, 10);
      final sortedRates = List.from(curr.exchangeRates!)
        ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
      final matching = sortedRates.firstWhere(
        (r) => r.effectiveDate.compareTo(orderDateStr) <= 0,
        orElse: () => sortedRates.first,
      );
      foundRate = matching.commercialRate;
    }

    foundRate ??= curr.latestCommercialRate;
    if (foundRate != null && foundRate > 0) {
      _rateCtrl.text = foundRate.toString();
    }
  }

  DateTime _parseFlexDate(String? rawStr) {
    if (rawStr == null || rawStr.trim().isEmpty) return DateTime.now();
    final s = rawStr.trim();
    final parsedIso = DateTime.tryParse(s);
    if (parsedIso != null) return parsedIso;

    final parts = s.split(RegExp(r'[/-]'));
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]) ?? 1;
      final p1 = int.tryParse(parts[1]) ?? 1;
      final p2 = int.tryParse(parts[2]) ?? DateTime.now().year;
      if (p2 > 1000) {
        return DateTime(p2, p1, p0);
      } else if (p0 > 1000) {
        return DateTime(p0, p1, p2);
      }
    }
    return DateTime.now();
  }

  void _applyExtractedFieldsToState(Map<String, dynamic> ext) {
    final companies = ref.read(importCompaniesProvider).value ?? [];
    final suppliers = ref.read(suppliersProvider).value ?? [];
    final incoterms = ref.read(incotermsProvider).value ?? [];
    final currencies = ref.read(currenciesProvider).value ?? [];
    final tariffs = ref.read(customsTariffProvider).value ?? [];

    setState(() {
      final poNum = ext['po_number']?.toString() ?? ext['proforma_invoice_number']?.toString();
      if (poNum != null && poNum.isNotEmpty) {
        _piCtrl.text = poNum;
      }
      final dateStr = (ext['order_date'] ?? ext['po_date'] ?? ext['date'])?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        _selectedOrderDate = _parseFlexDate(dateStr);
      }

      // 1. Company Matching (الشركة المستوردة)
      final rawComp = (ext['importer_name'] ?? ext['company_name'] ?? ext['importer'])?.toString().trim().toLowerCase();
      final rawCompTax = ext['importer_tax_id']?.toString().trim();
      if (rawComp != null && rawComp.isNotEmpty) {
        final matchedComp = companies.where((c) {
          final cName = c.importerName.toLowerCase();
          final cTax = c.vatId.trim();
          if (rawCompTax != null && rawCompTax.isNotEmpty && cTax == rawCompTax) return true;
          if (cName.contains(rawComp) || rawComp.contains(cName)) return true;
          final rawWords = rawComp.split(RegExp(r'\s+')).where((w) => w.length > 3);
          final cWords = cName.split(RegExp(r'\s+')).where((w) => w.length > 3);
          return rawWords.any((rw) => cWords.any((cw) => cw.contains(rw) || rw.contains(cw)));
        }).firstOrNull;
        if (matchedComp != null) {
          _selectedCompanyId = matchedComp.companyId;
        }
      }

      // 2. Supplier Matching (المورد الأجنبي)
      final rawSupp = (ext['supplier_name'] ?? ext['supplier'] ?? ext['vendor_name'])?.toString().trim().toLowerCase();
      final rawSuppTax = ext['supplier_tax_id']?.toString().trim();
      final rawSuppEmail = ext['supplier_email']?.toString().trim().toLowerCase();
      if (rawSupp != null && rawSupp.isNotEmpty) {
        final matchedSupp = suppliers.where((s) {
          final sName = s.companyName.toLowerCase();
          final sTax = s.foreignExporterId.trim();
          final sEmail = s.email?.trim().toLowerCase();
          if (rawSuppTax != null && rawSuppTax.isNotEmpty && sTax == rawSuppTax) return true;
          if (rawSuppEmail != null && rawSuppEmail.isNotEmpty && sEmail == rawSuppEmail) return true;
          if (sName.contains(rawSupp) || rawSupp.contains(sName)) return true;
          final rawWords = rawSupp.split(RegExp(r'\s+')).where((w) => w.length > 3 && !['ltd', 'inc', 'corp', 'spa', 'gmbh', 'international', 'co.'].contains(w));
          final sWords = sName.split(RegExp(r'\s+')).where((w) => w.length > 3 && !['ltd', 'inc', 'corp', 'spa', 'gmbh', 'international', 'co.'].contains(w));
          return rawWords.any((rw) => sWords.any((sw) => sw.contains(rw) || rw.contains(sw)));
        }).firstOrNull;
        if (matchedSupp != null) {
          _selectedSupplierId = matchedSupp.supplierId;
        }
      }

      // 3. Incoterm Matching (شروط التعاقد)
      final rawInco = (ext['incoterms'] ?? ext['incoterm'])?.toString().trim().toUpperCase();
      if (rawInco != null && rawInco.isNotEmpty) {
        final matchedInco = incoterms.where((i) {
          final code = i.incotermCode.toUpperCase().trim();
          return code == rawInco || rawInco.contains(code) || (rawInco.contains('EX WORK') && code == 'EXW') || (rawInco.contains('FREE ON BOARD') && code == 'FOB');
        }).firstOrNull;
        if (matchedInco != null) {
          _selectedIncotermId = matchedInco.incotermId;
        }
      }

      // 4. Currency Matching (العملة)
      final rawCurr = (ext['currency'] ?? ext['currency_code'])?.toString().trim().toUpperCase();
      if (rawCurr != null && rawCurr.isNotEmpty) {
        final matchedCurr = currencies.where((c) => c.currencyCode.toUpperCase().trim() == rawCurr).firstOrNull;
        if (matchedCurr != null) {
          _selectedCurrencyId = matchedCurr.currencyId;
          _updateExchangeRateFromCurrency(_selectedCurrencyId, currencies);
        }
      }

      // 5. Country of Origin (بلد المنشأ)
      final rawCty = (ext['country_of_origin'] ?? ext['supplier_country'] ?? ext['country'])?.toString().trim().toUpperCase();
      if (rawCty != null && rawCty.isNotEmpty) {
        final matchedCty = countryOptions.where((c) =>
          c['code'] == rawCty ||
          c['name']!.toUpperCase().contains(rawCty) ||
          (rawCty == 'LT' && (c['code'] == 'LT' || c['name']!.contains('Lithuania') || c['name']!.contains('ليتوانيا'))) ||
          (rawCty == 'CN' && (c['code'] == 'CN' || c['name']!.contains('China') || c['name']!.contains('الصين'))) ||
          (rawCty == 'IT' && (c['code'] == 'IT' || c['name']!.contains('Italy') || c['name']!.contains('إيطاليا')))
        ).firstOrNull;
        if (matchedCty != null) {
          _selectedCountryOfOrigin = matchedCty['name'];
        }
      }

      // 6. Payment Terms (شروط الدفع)
      final rawTerms = (ext['payment_terms'] ?? ext['payment_condition'] ?? ext['terms_of_payment'])?.toString().toUpperCase();
      if (rawTerms != null && rawTerms.isNotEmpty) {
        if (rawTerms.contains('LC') || rawTerms.contains('LETTER OF CREDIT') || rawTerms.contains('اعتماد')) {
          _selectedPaymentTerms = 'Letter of Credit / LC';
        } else if (rawTerms.contains('PREPAYMENT') || rawTerms.contains('AVV.MERCE') || rawTerms.contains('SWIFT') || rawTerms.contains('CASH') || rawTerms.contains('T/T') || rawTerms.contains('سويفت') || rawTerms.contains('مقدم')) {
          _selectedPaymentTerms = 'Cash in Advance / SWIFT';
        } else if (rawTerms.contains('CAD') || rawTerms.contains('COLLECTION') || rawTerms.contains('مستندات')) {
          _selectedPaymentTerms = 'Cash Against Documents / CAD';
        } else if (rawTerms.contains('OPEN ACCOUNT') || rawTerms.contains('حساب مفتوح')) {
          _selectedPaymentTerms = 'Open Account';
        }
      }

      if (ext['items'] is List && (ext['items'] as List).isNotEmpty) {
        final itemList = ext['items'] as List;
        _dialogItems = itemList.map((raw) {
          final i = Map<String, dynamic>.from(raw as Map);
          final qty = (i['quantity'] as num?)?.toDouble() ?? 100.0;
          final price = (i['unit_price'] as num?)?.toDouble() ?? 10.0;
          final desc = i['description']?.toString() ?? 'بند استيرادي رئيسي';
          final code = i['item_code']?.toString() ?? 'ITEM-001';
          final rawHs = i['hs_code']?.toString() ?? ext['hs_code']?.toString();

          String? itemCty = i['country_of_origin']?.toString() ?? i['country']?.toString();
          if (itemCty != null && itemCty.isNotEmpty) {
            final matchedCty = countryOptions.where((c) => c['code'] == itemCty?.toUpperCase() || c['name']!.toUpperCase().contains(itemCty!.toUpperCase())).firstOrNull;
            if (matchedCty != null) itemCty = matchedCty['name'];
          } else {
            itemCty = _selectedCountryOfOrigin;
          }

          int? matchedTariffId;
          String? matchedHsCode = rawHs;
          if (rawHs != null && rawHs.trim().isNotEmpty && tariffs.isNotEmpty) {
            final cleanHs = rawHs.replaceAll(RegExp(r'[^\d]'), '');
            final matched = tariffs.where((t) {
              final tClean = t.hsCode.replaceAll(RegExp(r'[^\d]'), '');
              return tClean == cleanHs || (cleanHs.length >= 4 && (tClean.startsWith(cleanHs) || cleanHs.startsWith(tClean)));
            }).firstOrNull;
            if (matched != null) {
              matchedTariffId = matched.tariffId;
              matchedHsCode = matched.hsCode;
            }
          }

          return POLineItemModel(
            itemCode: code,
            descriptionAr: desc,
            descriptionEn: desc,
            countryOfOrigin: itemCty,
            tariffId: matchedTariffId,
            hsCode: matchedHsCode,
            quantity: qty > 0 ? qty : 100.0,
            unitPrice: price > 0 ? price : 10.0,
            cbmPerUnit: (i['cbm_per_unit'] as num?)?.toDouble() ?? 0.1,
            grossWeightKg: (i['gross_weight_kg'] as num?)?.toDouble() ?? 5.0,
            netWeightKg: (i['net_weight_kg'] as num?)?.toDouble() ?? 4.5,
          );
        }).toList();
      }

      if (ext['packing_list_items'] is List && (ext['packing_list_items'] as List).isNotEmpty) {
        final packingList = ext['packing_list_items'] as List;
        _dialogPackingItems = packingList.map((raw) {
          final p = Map<String, dynamic>.from(raw as Map);
          return PackingListItemModel(
            hsCode: p['hs_code']?.toString() ?? '',
            itemCode: p['item_code']?.toString() ?? 'ITEM-001',
            qtyPcs: (p['qty_pcs'] as num?)?.toDouble() ?? 1.0,
            qtyPkg: (p['qty_pkg'] as num?)?.toDouble() ?? 1.0,
            packageType: p['package_type']?.toString() ?? 'Pallet',
            lengthCm: (p['length_cm'] as num?)?.toDouble() ?? 110.0,
            widthCm: (p['width_cm'] as num?)?.toDouble() ?? 110.0,
            heightCm: (p['height_cm'] as num?)?.toDouble() ?? 106.0,
            grossWeightUnitKg: (p['gross_weight_unit_kg'] as num?)?.toDouble() ?? 646.0,
            netWeightUnitKg: (p['net_weight_unit_kg'] as num?)?.toDouble() ?? 626.0,
            isStackable: p['is_stackable'] as bool? ?? true,
          );
        }).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final po = widget.po;
    final ext = widget.initialExtractedFields;
    final tariffs = ref.read(customsTariffProvider).value ?? [];

    _selectedOrderDate = po?.orderDate ??
        (ext != null ? _parseFlexDate((ext['order_date'] ?? ext['po_date'] ?? ext['date'])?.toString()) : DateTime.now());

    final defaultPiNumber = po?.proformaInvoiceNumber ??
        (ext != null ? (ext['po_number'] ?? ext['proforma_invoice_number'])?.toString() : null) ?? '';
    _piCtrl = TextEditingController(text: defaultPiNumber);
    _rateCtrl = TextEditingController(text: (po?.exchangeRate ?? 1.0).toString());
    _notesCtrl = TextEditingController(text: po?.notes ?? '');
    _selectedStatus = po?.status ?? 'Draft';

    final rawTerms = po?.paymentTerms ?? (ext != null ? ext['payment_terms']?.toString() : null);
    if (rawTerms != null && (rawTerms.contains('LC') || rawTerms.contains('اعتماد') || rawTerms.contains('CREDIT'))) {
      _selectedPaymentTerms = 'Letter of Credit / LC';
    } else if (rawTerms != null && (rawTerms.contains('SWIFT') || rawTerms.contains('Cash') || rawTerms.contains('سويفت') || rawTerms.contains('T/T') || rawTerms.contains('CHK') || rawTerms.contains('DBT'))) {
      _selectedPaymentTerms = 'Cash in Advance / SWIFT';
    } else {
      _selectedPaymentTerms = rawTerms ?? 'Cash in Advance / SWIFT';
    }

    _selectedImportFileId = po?.importFileId;
    _selectedProjectId = po?.projectId;
    _selectedCompanyId = po?.companyId;
    _selectedSupplierId = po?.supplierId;
    _selectedIncotermId = po?.incotermId;
    _selectedCurrencyId = po?.currencyId;
    _selectedCountryOfOrigin = po?.countryOfOrigin;

    if (po != null && po.items.isNotEmpty) {
      _dialogItems = po.items.map((i) => POLineItemModel(
            itemCode: i.itemCode,
            descriptionAr: i.descriptionAr,
            descriptionEn: i.descriptionEn,
            countryOfOrigin: i.countryOfOrigin,
            tariffId: i.tariffId,
            quantity: i.quantity,
            unitOfMeasure: i.unitOfMeasure,
            unitPrice: i.unitPrice,
            cbmPerUnit: i.cbmPerUnit,
            grossWeightKg: i.grossWeightKg,
            netWeightKg: i.netWeightKg,
          )).toList();
    } else if (ext != null && ext['items'] is List && (ext['items'] as List).isNotEmpty) {
      final itemList = ext['items'] as List;
      _dialogItems = itemList.map((raw) {
        final i = Map<String, dynamic>.from(raw as Map);
        final qty = (i['quantity'] as num?)?.toDouble() ?? 100.0;
        final price = (i['unit_price'] as num?)?.toDouble() ?? 10.0;
        final desc = i['description']?.toString() ?? 'بند استيرادي رئيسي';
        final code = i['item_code']?.toString() ?? 'ITEM-001';
        final rawHs = i['hs_code']?.toString() ?? ext['hs_code']?.toString();

        String? itemCty = i['country_of_origin']?.toString() ?? i['country']?.toString();
        if (itemCty != null && itemCty.isNotEmpty) {
          final matchedCty = countryOptions.where((c) => c['code'] == itemCty?.toUpperCase() || c['name']!.toUpperCase().contains(itemCty!.toUpperCase())).firstOrNull;
          if (matchedCty != null) itemCty = matchedCty['code'];
        } else {
          itemCty = _selectedCountryOfOrigin;
        }

        int? matchedTariffId;
        String? matchedHsCode = rawHs;
        if (rawHs != null && rawHs.trim().isNotEmpty && tariffs.isNotEmpty) {
          final cleanHs = rawHs.replaceAll(RegExp(r'[^\d]'), '');
          final matched = tariffs.where((t) {
            final tClean = t.hsCode.replaceAll(RegExp(r'[^\d]'), '');
            return tClean == cleanHs || (cleanHs.length >= 4 && (tClean.startsWith(cleanHs) || cleanHs.startsWith(tClean)));
          }).firstOrNull;
          if (matched != null) {
            matchedTariffId = matched.tariffId;
            matchedHsCode = matched.hsCode;
          }
        }

        return POLineItemModel(
          itemCode: code,
          descriptionAr: desc,
          descriptionEn: desc,
          countryOfOrigin: itemCty,
          tariffId: matchedTariffId,
          hsCode: matchedHsCode,
          quantity: qty > 0 ? qty : 100.0,
          unitPrice: price > 0 ? price : 10.0,
          cbmPerUnit: (i['cbm_per_unit'] as num?)?.toDouble() ?? 0.1,
          grossWeightKg: (i['gross_weight_kg'] as num?)?.toDouble() ?? 5.0,
          netWeightKg: (i['net_weight_kg'] as num?)?.toDouble() ?? 4.5,
        );
      }).toList();
    } else {
      _dialogItems = [
        POLineItemModel(
          descriptionAr: 'بند استيرادي رئيسي 1',
          quantity: 100,
          unitPrice: 10,
          cbmPerUnit: 0.1,
        )
      ];
    }

    if (po != null && po.packingListItems.isNotEmpty) {
      _dialogPackingItems = po.packingListItems.map((p) => PackingListItemModel(
            hsCode: p.hsCode,
            itemCode: p.itemCode,
            qtyPcs: p.qtyPcs,
            qtyPkg: p.qtyPkg,
            packageType: p.packageType,
            lengthCm: p.lengthCm,
            widthCm: p.widthCm,
            heightCm: p.heightCm,
            netWeightUnitKg: p.netWeightUnitKg,
            grossWeightUnitKg: p.grossWeightUnitKg,
            isStackable: p.isStackable,
          )).toList();
    } else if (ext != null && ext['packing_list_items'] is List && (ext['packing_list_items'] as List).isNotEmpty) {
      final packingList = ext['packing_list_items'] as List;
      _dialogPackingItems = packingList.map((raw) {
        final p = Map<String, dynamic>.from(raw as Map);
        return PackingListItemModel(
          hsCode: p['hs_code']?.toString() ?? '',
          itemCode: p['item_code']?.toString() ?? 'ITEM-001',
          qtyPcs: (p['qty_pcs'] as num?)?.toDouble() ?? 1.0,
          qtyPkg: (p['qty_pkg'] as num?)?.toDouble() ?? 1.0,
          packageType: p['package_type']?.toString() ?? 'Pallet',
          lengthCm: (p['length_cm'] as num?)?.toDouble() ?? 110.0,
          widthCm: (p['width_cm'] as num?)?.toDouble() ?? 110.0,
          heightCm: (p['height_cm'] as num?)?.toDouble() ?? 106.0,
          grossWeightUnitKg: (p['gross_weight_unit_kg'] as num?)?.toDouble() ?? 646.0,
          netWeightUnitKg: (p['net_weight_unit_kg'] as num?)?.toDouble() ?? 626.0,
          isStackable: p['is_stackable'] as bool? ?? true,
        );
      }).toList();
    } else {
      _dialogPackingItems = _dialogItems.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        return PackingListItemModel(
          hsCode: item.hsCode ?? '',
          itemCode: item.itemCode ?? 'ITEM-${(idx + 1).toString().padLeft(3, '0')}',
          qtyPcs: item.quantity,
          qtyPkg: (item.quantity > 0 ? (item.quantity / 10).ceilToDouble() : 10.0),
          packageType: 'Carton',
          lengthCm: 50.0,
          widthCm: 40.0,
          heightCm: 30.0,
          netWeightUnitKg: item.netWeightKg > 0 ? item.netWeightKg : 5.0,
          grossWeightUnitKg: item.grossWeightKg > 0 ? item.grossWeightKg : 6.0,
        );
      }).toList();
    }
  }

  @override
  void dispose() {
    _piCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).value ?? [];
    final companies = ref.watch(importCompaniesProvider).value ?? [];
    final suppliers = ref.watch(suppliersProvider).value ?? [];
    final incoterms = ref.watch(incotermsProvider).value ?? [];
    final currencies = ref.watch(currenciesProvider).value ?? [];
    final tariffs = ref.watch(customsTariffProvider).value ?? [];
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    final isLoadingMaster = projects.isEmpty || companies.isEmpty || suppliers.isEmpty || incoterms.isEmpty || currencies.isEmpty;

    final reconciliation = evaluatePOReconciliation(
      invoiceItems: _dialogItems,
      packingItems: _dialogPackingItems,
      tariffs: tariffs,
    );
    final Set<String> mismatchedHsCodes = reconciliation.items
        .where((item) => !item.isMatched || item.isMissingInPacking || item.isMissingInInvoice)
        .map((item) => item.hsCode)
        .toSet();

    final ext = widget.initialExtractedFields;
    if (widget.po == null && ext != null) {
      // 1. Company
      if (_selectedCompanyId == null && companies.isNotEmpty) {
        final rawComp = (ext['importer_name'] ?? ext['company_name'] ?? ext['importer'])?.toString().trim().toLowerCase();
        final rawCompTax = ext['importer_tax_id']?.toString().trim();
        if (rawComp != null && rawComp.isNotEmpty) {
          final matchedComp = companies.where((c) {
            final cName = c.importerName.toLowerCase();
            final cTax = c.vatId.trim();
            if (rawCompTax != null && rawCompTax.isNotEmpty && cTax == rawCompTax) return true;
            if (cName.contains(rawComp) || rawComp.contains(cName)) return true;
            final rawWords = rawComp.split(RegExp(r'\s+')).where((w) => w.length > 3);
            final cWords = cName.split(RegExp(r'\s+')).where((w) => w.length > 3);
            return rawWords.any((rw) => cWords.any((cw) => cw.contains(rw) || rw.contains(cw)));
          }).firstOrNull;
          if (matchedComp != null) {
            _selectedCompanyId = matchedComp.companyId;
          }
        }
      }

      // 2. Supplier
      if (_selectedSupplierId == null && suppliers.isNotEmpty) {
        final rawSupp = (ext['supplier_name'] ?? ext['supplier'] ?? ext['vendor_name'])?.toString().trim().toLowerCase();
        final rawSuppTax = ext['supplier_tax_id']?.toString().trim();
        final rawSuppEmail = ext['supplier_email']?.toString().trim().toLowerCase();
        if (rawSupp != null && rawSupp.isNotEmpty) {
          final matchedSupp = suppliers.where((s) {
            final sName = s.companyName.toLowerCase();
            final sTax = s.foreignExporterId.trim();
            final sEmail = s.email?.trim().toLowerCase();
            if (rawSuppTax != null && rawSuppTax.isNotEmpty && sTax == rawSuppTax) return true;
            if (rawSuppEmail != null && rawSuppEmail.isNotEmpty && sEmail == rawSuppEmail) return true;
            if (sName.contains(rawSupp) || rawSupp.contains(sName)) return true;
            final rawWords = rawSupp.split(RegExp(r'\s+')).where((w) => w.length > 3 && !['ltd', 'inc', 'corp', 'spa', 'gmbh', 'international', 'co.'].contains(w));
            final sWords = sName.split(RegExp(r'\s+')).where((w) => w.length > 3 && !['ltd', 'inc', 'corp', 'spa', 'gmbh', 'international', 'co.'].contains(w));
            return rawWords.any((rw) => sWords.any((sw) => sw.contains(rw) || rw.contains(sw)));
          }).firstOrNull;
          if (matchedSupp != null) {
            _selectedSupplierId = matchedSupp.supplierId;
          }
        }
      }

      // 3. Incoterm
      if (_selectedIncotermId == null && incoterms.isNotEmpty) {
        final rawInco = (ext['incoterms'] ?? ext['incoterm'])?.toString().trim().toUpperCase();
        if (rawInco != null && rawInco.isNotEmpty) {
          final matchedInco = incoterms.where((i) {
            final code = i.incotermCode.toUpperCase().trim();
            return code == rawInco || rawInco.contains(code) || (rawInco.contains('EX WORK') && code == 'EXW') || (rawInco.contains('FREE ON BOARD') && code == 'FOB');
          }).firstOrNull;
          if (matchedInco != null) {
            _selectedIncotermId = matchedInco.incotermId;
          }
        }
      }

      // 4. Currency
      if (_selectedCurrencyId == null && currencies.isNotEmpty) {
        final rawCurr = (ext['currency'] ?? ext['currency_code'])?.toString().trim().toUpperCase();
        if (rawCurr != null && rawCurr.isNotEmpty) {
          final matchedCurr = currencies.where((c) => c.currencyCode.toUpperCase().trim() == rawCurr).firstOrNull;
          if (matchedCurr != null) {
            _selectedCurrencyId = matchedCurr.currencyId;
            _updateExchangeRateFromCurrency(_selectedCurrencyId, currencies);
          }
        }
      }

      // 5. Country of Origin
      if (_selectedCountryOfOrigin == null) {
        final rawCty = (ext['country_of_origin'] ?? ext['supplier_country'] ?? ext['country'])?.toString().trim().toUpperCase();
        if (rawCty != null && rawCty.isNotEmpty) {
          final matchedCty = countryOptions.where((c) =>
            c['code'] == rawCty ||
            c['name']!.toUpperCase().contains(rawCty) ||
            (rawCty == 'LT' && (c['code'] == 'LT' || c['name']!.contains('Lithuania') || c['name']!.contains('ليتوانيا'))) ||
            (rawCty == 'CN' && (c['code'] == 'CN' || c['name']!.contains('China') || c['name']!.contains('الصين'))) ||
            (rawCty == 'IT' && (c['code'] == 'IT' || c['name']!.contains('Italy') || c['name']!.contains('إيطاليا')))
          ).firstOrNull;
          if (matchedCty != null) {
            _selectedCountryOfOrigin = matchedCty['name'];
          }
        }
      }
    }

    if (_selectedProjectId == null && projects.isNotEmpty) {
      _selectedProjectId = projects.first.projectId;
    } else if (_selectedProjectId != null && !projects.any((p) => p.projectId == _selectedProjectId)) {
      _selectedProjectId = projects.isNotEmpty ? projects.first.projectId : null;
    }

    if (_selectedCompanyId == null && companies.isNotEmpty) {
      _selectedCompanyId = companies.first.companyId;
    } else if (_selectedCompanyId != null && !companies.any((c) => c.companyId == _selectedCompanyId)) {
      _selectedCompanyId = companies.isNotEmpty ? companies.first.companyId : null;
    }

    if (_selectedSupplierId == null && suppliers.isNotEmpty) {
      _selectedSupplierId = suppliers.first.supplierId;
    } else if (_selectedSupplierId != null && !suppliers.any((s) => s.supplierId == _selectedSupplierId)) {
      _selectedSupplierId = suppliers.isNotEmpty ? suppliers.first.supplierId : null;
    }

    if (_selectedIncotermId == null && incoterms.isNotEmpty) {
      _selectedIncotermId = incoterms.first.incotermId;
    } else if (_selectedIncotermId != null && !incoterms.any((i) => i.incotermId == _selectedIncotermId)) {
      _selectedIncotermId = incoterms.isNotEmpty ? incoterms.first.incotermId : null;
    }

    if (_selectedCurrencyId == null && currencies.isNotEmpty) {
      _selectedCurrencyId = currencies.first.currencyId;
    } else if (_selectedCurrencyId != null && !currencies.any((c) => c.currencyId == _selectedCurrencyId)) {
      _selectedCurrencyId = currencies.isNotEmpty ? currencies.first.currencyId : null;
    }

    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        titlePadding: EdgeInsets.zero,
        title: Container(
          decoration: const BoxDecoration(
            color: AppTheme.charcoal,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.po == null ? 'Create New Purchase Order (أمر شراء جديد)' : 'Edit Purchase Order (${widget.po!.poNumber})',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SmartUploadButton(
                      module: SmartUploadModule.purchaseOrder,
                      compact: true,
                      label: '🚀 رفع واستخراج المستندات (Invoice + Packing List)',
                      onDataExtracted: (result) {
                        _applyExtractedFieldsToState(result.extractedFields);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تمت تعبئة بيانات أمر الشراء وكشف التعبئة بنجاح!'),
                            backgroundColor: AppTheme.emerald,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              TabBar(
                labelColor: AppTheme.emerald,
                unselectedLabelColor: Colors.white70,
                indicatorColor: AppTheme.emerald,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.list_alt, size: 18),
                    text: 'Commercial Header & Items (${_dialogItems.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    text: 'Packing List (${_dialogPackingItems.length})',
                  ),
                ],
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 850,
          height: 520,
          child: isLoadingMaster
              ? const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري تحميل البيانات المرجعية...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: TabBarView(
                    children: [
                      // Tab 1: Commercial Header & Line Items
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, right: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SearchableDropdownField<int?>(
                              value: _selectedImportFileId,
                              labelText: 'Import File (ملف الشحنة الاستيرادية)',
                              items: [
                                const SearchableDropdownItem<int?>(
                                  value: null,
                                  label: '-- None / غير مرتبط بملف شحنة --',
                                ),
                                ...importFiles.map((f) => SearchableDropdownItem<int?>(
                                      value: f.importFileId,
                                      label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                    )),
                              ],
                              onChanged: (v) => setState(() => _selectedImportFileId = v),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _piCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Proforma Invoice # (رقم الفاتورة المبدئية)',
                                      hintText: 'e.g. PI-2026-991',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedOrderDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _selectedOrderDate = picked;
                                          _updateExchangeRateFromCurrency(_selectedCurrencyId, currencies);
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Invoice Date (تاريخ الفاتورة) *',
                                        prefixIcon: Icon(Icons.calendar_today, color: AppTheme.cobalt),
                                      ),
                                      child: Text(
                                        '${_selectedOrderDate.year}-${_selectedOrderDate.month.toString().padLeft(2, '0')}-${_selectedOrderDate.day.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: _selectedProjectId,
                                    labelText: 'Project *',
                                    items: projects
                                        .map((p) => SearchableDropdownItem<int?>(
                                              value: p.projectId,
                                              label: '${p.projectCode} (${p.projectName})',
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedProjectId = v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SearchableDropdownField<int?>(
                                        value: _selectedCompanyId,
                                        labelText: 'Importing Company (الشركة المستوردة) *',
                                        items: companies
                                            .map((c) => SearchableDropdownItem<int?>(
                                                  value: c.companyId,
                                                  label: '${c.importerName} (${c.vatId})',
                                                ))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) setState(() => _selectedCompanyId = v);
                                        },
                                      ),
                                      const SizedBox(height: 3),
                                      InkWell(
                                        onTap: () => UniversalEntityExtractorDialog.show(
                                          context,
                                          initialTarget: EntityTarget.company,
                                          onSaved: () => ref.read(importCompaniesProvider.notifier).fetchCompanies(),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.domain_add, size: 13, color: AppTheme.cobalt),
                                              SizedBox(width: 4),
                                              Text(
                                                '+ استدعاء AI Extractor & Coding لتكويد شركة مستوردة',
                                                style: TextStyle(fontSize: 10.5, color: AppTheme.cobalt, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SearchableDropdownField<int?>(
                                        value: _selectedSupplierId,
                                        labelText: 'Supplier (المورد الأجنبي) *',
                                        items: suppliers
                                            .map((s) => SearchableDropdownItem<int?>(
                                                  value: s.supplierId,
                                                  label: '[${s.supplierCode}] ${s.companyName} (${s.foreignExporterCountry})',
                                                ))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) setState(() => _selectedSupplierId = v);
                                        },
                                      ),
                                      const SizedBox(height: 3),
                                      InkWell(
                                        onTap: () => UniversalEntityExtractorDialog.show(
                                          context,
                                          initialTarget: EntityTarget.supplier,
                                          onSaved: () => ref.read(suppliersProvider.notifier).fetchSuppliers(),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.auto_awesome, size: 13, color: AppTheme.cobalt),
                                              SizedBox(width: 4),
                                              Text(
                                                '+ استدعاء AI Extractor & Coding لتكويد مورد جديد',
                                                style: TextStyle(fontSize: 10.5, color: AppTheme.cobalt, fontWeight: FontWeight.bold),
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
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: _selectedIncotermId,
                                    labelText: 'Incoterm *',
                                    items: incoterms
                                        .map((i) => SearchableDropdownItem<int?>(
                                              value: i.incotermId,
                                              label: '${i.incotermCode} (${i.incotermName})',
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedIncotermId = v);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: _selectedCurrencyId,
                                    labelText: 'Currency *',
                                    items: currencies
                                        .map((c) => SearchableDropdownItem<int?>(
                                              value: c.currencyId,
                                              label: '${c.currencyCode} (${c.currencyName})',
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _selectedCurrencyId = v;
                                          _updateExchangeRateFromCurrency(v, currencies);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdownField<String?>(
                                    value: _selectedCountryOfOrigin,
                                    labelText: 'Country of Origin (بلد المنشأ العام)',
                                    items: [
                                      const SearchableDropdownItem<String?>(
                                        value: null,
                                        label: '-- غير محدد (Auto / غير محدد) --',
                                      ),
                                      ...countryOptions.map((c) => SearchableDropdownItem<String?>(
                                            value: c['name'],
                                            label: c['name']!,
                                          )),
                                    ],
                                    onChanged: (v) => setState(() => _selectedCountryOfOrigin = v),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<String>(
                                    value: _selectedStatus,
                                    labelText: 'Status',
                                    items: ['Draft', 'Approved', 'In Transit', 'Closed', 'Cancelled']
                                        .map((s) => SearchableDropdownItem<String>(value: s, label: s))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedStatus = v ?? 'Draft'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _rateCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Exchange Rate (سعر الصرف)',
                                      helperText: '⚡ يستدعى آلياً حسب تاريخ الفاتورة والعملة',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<String>(
                                    value: ['Cash in Advance / SWIFT', 'Letter of Credit / LC', 'CAD / Cash Against Documents', 'Open Account / Deferred Payment'].contains(_selectedPaymentTerms)
                                        ? _selectedPaymentTerms
                                        : 'Cash in Advance / SWIFT',
                                    labelText: 'Payment Terms (شروط الدفع) *',
                                    items: const [
                                      SearchableDropdownItem(
                                        value: 'Cash in Advance / SWIFT',
                                        label: 'Cash in Advance / SWIFT (تحويل سويفت مقدم)',
                                      ),
                                      SearchableDropdownItem(
                                        value: 'Letter of Credit / LC',
                                        label: 'Letter of Credit / LC (اعتماد مستندي)',
                                      ),
                                      SearchableDropdownItem(
                                        value: 'CAD / Cash Against Documents',
                                        label: 'CAD / Cash Against Documents (تحصيل مستندي)',
                                      ),
                                      SearchableDropdownItem(
                                        value: 'Open Account / Deferred Payment',
                                        label: 'Open Account / Deferred Payment (حساب مفتوح / آجل)',
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _selectedPaymentTerms = v);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Line Items Header & Add Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'PO Line Items (بنود الفاتورة المبدئية) *',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Item'),
                                  onPressed: () {
                                    setState(() {
                                      _dialogItems.add(
                                        POLineItemModel(
                                          descriptionAr: 'بند جديد ${_dialogItems.length + 1}',
                                          quantity: 1,
                                          unitPrice: 0,
                                          countryOfOrigin: _selectedCountryOfOrigin,
                                        ),
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Dynamic Line Items List
                            ..._dialogItems.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              final itemHs = item.hsCode ?? (item.tariffId != null && tariffs.any((t) => t.tariffId == item.tariffId) ? tariffs.firstWhere((t) => t.tariffId == item.tariffId).hsCode : '');
                              final isMismatched = itemHs.isNotEmpty && mismatchedHsCodes.contains(itemHs);

                              return Card(
                                color: isMismatched ? Colors.red.shade50.withOpacity(0.4) : Colors.grey.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isMismatched ? Colors.red.shade300 : Colors.grey.shade300,
                                    width: isMismatched ? 1.5 : 1.0,
                                  ),
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('#${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              initialValue: item.itemCode,
                                              decoration: const InputDecoration(labelText: 'Item Code (كود البند)', isDense: true),
                                              onChanged: (v) => _dialogItems[idx] = _dialogItems[idx].copyWith(itemCode: v.trim().isEmpty ? null : v.trim()),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: TextFormField(
                                              initialValue: item.descriptionAr,
                                              decoration: const InputDecoration(labelText: 'Arabic Description *', isDense: true),
                                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                              onChanged: (v) => _dialogItems[idx] = _dialogItems[idx].copyWith(descriptionAr: v),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: InkWell(
                                              onTap: () async {
                                                final picked = await _showHsCodeSearchPicker(context, tariffs);
                                                setState(() {
                                                  _dialogItems[idx] = _dialogItems[idx].copyWith(
                                                    tariffId: picked?.tariffId,
                                                    hsCode: picked?.hsCode,
                                                  );
                                                });
                                              },
                                              child: InputDecorator(
                                                decoration: InputDecoration(
                                                  labelText: 'Customs Tariff / HS Code (بحث 🔍)',
                                                  isDense: true,
                                                  suffixIcon: isMismatched ? const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16) : null,
                                                ),
                                                child: Text(
                                                  item.tariffId != null
                                                      ? (tariffs.any((t) => t.tariffId == item.tariffId)
                                                          ? '${tariffs.firstWhere((t) => t.tariffId == item.tariffId).hsCode} - ${tariffs.firstWhere((t) => t.tariffId == item.tariffId).hsDescription}'
                                                          : (item.hsCode ?? 'ID #${item.tariffId}'))
                                                      : (item.hsCode != null && item.hsCode!.isNotEmpty ? item.hsCode! : 'None / General'),
                                                  style: TextStyle(
                                                    fontWeight: (item.tariffId != null || (item.hsCode != null && item.hsCode!.isNotEmpty)) ? FontWeight.bold : FontWeight.normal,
                                                    color: isMismatched ? Colors.red.shade900 : ((item.tariffId != null || (item.hsCode != null && item.hsCode!.isNotEmpty)) ? AppTheme.cobalt : Colors.grey.shade700),
                                                    fontSize: 12,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: SearchableDropdownField<String?>(
                                              value: normalizeCountryName(item.countryOfOrigin ?? _selectedCountryOfOrigin),
                                              labelText: 'بلد المنشأ للبند',
                                              searchHintText: 'ابحث عن بلد المنشأ...',
                                              items: [
                                                const SearchableDropdownItem<String?>(value: null, label: '-- الافتراضي --'),
                                                ...countryOptions.map((c) => SearchableDropdownItem<String?>(
                                                      value: c['name'],
                                                      label: c['name']!,
                                                    )),
                                              ],
                                              onChanged: (v) {
                                                setState(() {
                                                  _dialogItems[idx] = _dialogItems[idx].copyWith(countryOfOrigin: normalizeCountryName(v));
                                                });
                                              },
                                            ),
                                          ),
                                          if (_dialogItems.length > 1)
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.crimson, size: 20),
                                              onPressed: () => setState(() => _dialogItems.removeAt(idx)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: item.quantity.toString(),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(labelText: 'Qty (العدد)', isDense: true),
                                              onChanged: (v) {
                                                final q = double.tryParse(v) ?? 1.0;
                                                setState(() {
                                                  _dialogItems[idx] = _dialogItems[idx].copyWith(quantity: q);
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: item.unitPrice.toString(),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(labelText: 'Unit Price (سعر الوحده)', isDense: true),
                                              onChanged: (v) {
                                                final p = double.tryParse(v) ?? 0.0;
                                                setState(() {
                                                  _dialogItems[idx] = _dialogItems[idx].copyWith(unitPrice: p);
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                           Container(
                                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                             decoration: BoxDecoration(
                                               color: Colors.green.shade50,
                                               borderRadius: BorderRadius.circular(6),
                                               border: Border.all(color: Colors.green.shade300),
                                             ),
                                             child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.center,
                                               children: [
                                                 const Text('Line Total (إجمالي السطر)', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                 Text(
                                                   '${currencies.firstWhere((c) => c.currencyId == _selectedCurrencyId, orElse: () => CurrencyModel(currencyId: 0, currencyCode: "USD", currencyName: "USD", currencySymbol: "\$")).currencyCode} ${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                                                   style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                                                 ),
                                               ],
                                             ),
                                           ),
                                         ],
                                       ),

                                       // Unregistered HS Code Warning Banner per Item with Smart Nafeza Trigger
                                       if (item.tariffId == null || !tariffs.any((t) => t.tariffId == item.tariffId))
                                         Container(
                                           margin: const EdgeInsets.only(top: 8),
                                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                           decoration: BoxDecoration(
                                             color: Colors.amber.shade50,
                                             borderRadius: BorderRadius.circular(8),
                                             border: Border.all(color: Colors.amber.shade400, width: 1.2),
                                           ),
                                           child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                               Row(
                                                 children: [
                                                   Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 18),
                                                   const SizedBox(width: 6),
                                                   Expanded(
                                                     child: Text(
                                                       '⚠️ بند التعريفة الجمركية (${item.hsCode ?? "غير مسجل"}) غير مسجل في جدول التعريفة المعتمد — يرجى تسجيله عبر Smart Nafeza لتطبيق الرسوم الجمركية وضريبة الوارد بدقة.',
                                                       style: TextStyle(
                                                         color: Colors.amber.shade900,
                                                         fontSize: 11,
                                                         fontWeight: FontWeight.bold,
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               const SizedBox(height: 6),
                                               Wrap(
                                                 spacing: 8,
                                                 runSpacing: 4,
                                                 children: [
                                                   ElevatedButton.icon(
                                                     style: ElevatedButton.styleFrom(
                                                       backgroundColor: AppTheme.orange,
                                                       foregroundColor: Colors.white,
                                                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                       visualDensity: VisualDensity.compact,
                                                     ),
                                                     icon: const Icon(Icons.auto_fix_high, size: 14),
                                                     label: const Text('✨ استدعاء Smart Nafeza & Diff Engine لتسجيل البند', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                     onPressed: () => showTariffDialog(context, ref, initialModeIndex: 0),
                                                   ),
                                                   OutlinedButton.icon(
                                                     style: OutlinedButton.styleFrom(
                                                       foregroundColor: AppTheme.cobalt,
                                                       side: const BorderSide(color: AppTheme.cobalt),
                                                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                       visualDensity: VisualDensity.compact,
                                                     ),
                                                     icon: const Icon(Icons.search, size: 14),
                                                     label: const Text('🔍 بحث واختيار من التعريفة', style: TextStyle(fontSize: 11)),
                                                     onPressed: () async {
                                                       final picked = await _showHsCodeSearchPicker(context, tariffs);
                                                       if (picked != null) {
                                                         setState(() {
                                                           _dialogItems[idx] = _dialogItems[idx].copyWith(
                                                             tariffId: picked.tariffId,
                                                             hsCode: picked.hsCode,
                                                           );
                                                         });
                                                       }
                                                     },
                                                   ),
                                                 ],
                                               ),
                                             ],
                                           ),
                                         ),
                                     ],
                                   ),
                                 ),
                               );
                             }),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _notesCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(labelText: 'PO Notes & Instructions'),
                            ),
                          ],
                        ),
                      ),

                      // Tab 2: BP-003 Dynamic Detailed Packing List
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, right: 4),
                        child: SizedBox(
                          height: 480,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Packing List Entries (بيان التعبئة والطرود والأبعاد) *',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                  ),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                                        icon: const Icon(Icons.auto_fix_high, size: 16),
                                        label: const Text('تعبئة تلقائية من الفاتورة', style: TextStyle(fontSize: 12)),
                                        onPressed: () {
                                          if (_dialogItems.isEmpty) return;
                                          setState(() {
                                            _dialogPackingItems.clear();
                                            for (int i = 0; i < _dialogItems.length; i++) {
                                              final item = _dialogItems[i];
                                              String itemHsCode = '';
                                              if (item.hsCode != null && item.hsCode!.isNotEmpty) {
                                                itemHsCode = item.hsCode!;
                                              } else if (item.tariffId != null) {
                                                final matchingTariff = tariffs.cast<CustomsTariffModel?>().firstWhere(
                                                      (t) => t?.tariffId == item.tariffId,
                                                      orElse: () => null,
                                                    );
                                                if (matchingTariff != null && matchingTariff.hsCode.isNotEmpty) {
                                                  itemHsCode = matchingTariff.hsCode;
                                                }
                                              }
                                              _dialogPackingItems.add(
                                                PackingListItemModel(
                                                  hsCode: itemHsCode,
                                                  itemCode: item.itemCode ?? 'ITEM-${(i + 1).toString().padLeft(3, '0')}',
                                                  qtyPcs: item.quantity > 0 ? item.quantity : 100.0,
                                                  qtyPkg: (item.quantity > 0 ? (item.quantity / 10).ceilToDouble() : 10.0),
                                                  packageType: 'Carton',
                                                  lengthCm: 50.0,
                                                  widthCm: 40.0,
                                                  heightCm: 30.0,
                                                  netWeightUnitKg: item.netWeightKg > 0 ? item.netWeightKg : 5.0,
                                                  grossWeightUnitKg: item.grossWeightKg > 0 ? item.grossWeightKg : 6.0,
                                                ),
                                              );
                                            }
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('تمت التعبئة التلقائية لـ ${_dialogPackingItems.length} طرود من بنود الفاتورة المبدئية!'),
                                              backgroundColor: AppTheme.emerald,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange, foregroundColor: Colors.white),
                                        icon: const Icon(Icons.view_in_ar_rounded, size: 16),
                                        label: const Text('محاكاة ورص الحاويات 3D', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        onPressed: () => _showPoVisualLoadPlannerDialog(context, _dialogPackingItems),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.playlist_add, size: 18, color: AppTheme.emerald),
                                        label: const Text('Add Packing Entry', style: TextStyle(color: AppTheme.emerald)),
                                        onPressed: () {
                                          String defaultHs = '';
                                          if (_dialogItems.isNotEmpty) {
                                            final first = _dialogItems.first;
                                            if (first.hsCode != null && first.hsCode!.isNotEmpty) {
                                              defaultHs = first.hsCode!;
                                            } else if (first.tariffId != null) {
                                              final match = tariffs.cast<CustomsTariffModel?>().firstWhere((t) => t?.tariffId == first.tariffId, orElse: () => null);
                                              if (match != null) defaultHs = match.hsCode;
                                            }
                                          }
                                          setState(() {
                                            _dialogPackingItems.add(
                                              PackingListItemModel(
                                                hsCode: defaultHs,
                                                itemCode: 'ITEM-00${_dialogPackingItems.length + 1}',
                                                qtyPcs: 10,
                                                qtyPkg: 1,
                                                packageType: 'Carton',
                                                lengthCm: 50,
                                                widthCm: 40,
                                                heightCm: 30,
                                                netWeightUnitKg: 5,
                                                grossWeightUnitKg: 6,
                                              ),
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Expanded(
                                child: _dialogPackingItems.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'لم يتم إضافة بنود تعبئة بعد',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'انقر فوق "تعبئة تلقائية من الفاتورة" لإنشاء قائمة التعبئة آلياً أو "Add Packing Entry"',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _dialogPackingItems.length,
                                        itemBuilder: (context, idx) {
                                          final p = _dialogPackingItems[idx];
                                          final isMismatched = p.hsCode.isNotEmpty && mismatchedHsCodes.contains(p.hsCode);

                                          return Card(
                                            key: ValueKey('packing_card_${idx}_${p.itemCode}'),
                                            color: isMismatched ? Colors.red.shade50.withOpacity(0.4) : Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(
                                                color: isMismatched ? Colors.red.shade400 : Colors.blue.shade200,
                                                width: isMismatched ? 1.5 : 1.0,
                                              ),
                                            ),
                                            margin: const EdgeInsets.only(bottom: 10),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                       Container(
                                                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                         decoration: BoxDecoration(
                                                           color: isMismatched ? Colors.red.withOpacity(0.15) : AppTheme.cobalt.withOpacity(0.15),
                                                           borderRadius: BorderRadius.circular(4),
                                                         ),
                                                         child: Text(
                                                           'Pkg #${idx + 1}',
                                                           style: TextStyle(
                                                             fontWeight: FontWeight.bold,
                                                             color: isMismatched ? Colors.red.shade900 : AppTheme.cobalt,
                                                             fontSize: 12,
                                                           ),
                                                         ),
                                                       ),
                                                       const SizedBox(width: 8),
                                                       Expanded(
                                                         child: InkWell(
                                                           onTap: () async {
                                                             final picked = await _showHsCodeSearchPicker(context, tariffs);
                                                             if (picked != null) {
                                                               setState(() {
                                                                 _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(hsCode: picked.hsCode);
                                                               });
                                                             }
                                                           },
                                                           child: InputDecorator(
                                                             decoration: InputDecoration(
                                                               labelText: 'HS Code (بحث 🔍) *',
                                                               isDense: true,
                                                               suffixIcon: isMismatched ? const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16) : null,
                                                             ),
                                                             child: Text(
                                                               p.hsCode.isNotEmpty ? p.hsCode : 'اختر بند جمركي',
                                                               style: TextStyle(
                                                                 fontWeight: p.hsCode.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                                                 color: isMismatched ? Colors.red.shade900 : (p.hsCode.isNotEmpty ? AppTheme.cobalt : Colors.grey.shade600),
                                                                 fontSize: 12,
                                                               ),
                                                               overflow: TextOverflow.ellipsis,
                                                             ),
                                                           ),
                                                         ),
                                                       ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.itemCode,
                                                      decoration: const InputDecoration(labelText: 'Item Code *', isDense: true),
                                                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                                      onChanged: (v) {
                                                        _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(itemCode: v.trim());
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: SearchableDropdownField<String>(
                                                      value: p.packageType,
                                                      labelText: 'Package Type',
                                                      items: ['Carton', 'Pallet', 'Bag', 'Wooden Crate', 'Drum', 'Container']
                                                          .map((t) => SearchableDropdownItem(value: t, label: t))
                                                          .toList(),
                                                      onChanged: (v) => setState(() {
                                                        _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(packageType: v ?? 'Carton');
                                                      }),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.crimson, size: 20),
                                                    onPressed: () => setState(() => _dialogPackingItems.removeAt(idx)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 100,
                                                    child: SearchableDropdownField<String>(
                                                      value: p.unit,
                                                      labelText: 'Unit',
                                                      items: const [
                                                        SearchableDropdownItem(value: 'cm', label: 'cm'),
                                                        SearchableDropdownItem(value: 'mm', label: 'mm'),
                                                        SearchableDropdownItem(value: 'm', label: 'm'),
                                                      ],
                                                      onChanged: (v) => setState(() {
                                                        _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(unit: v ?? 'cm');
                                                      }),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.qtyPcs.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: const InputDecoration(labelText: 'Qty PCS', isDense: true),
                                                      onChanged: (v) {
                                                        final q = double.tryParse(v) ?? 1.0;
                                                        _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(qtyPcs: q);
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.qtyPkg.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: const InputDecoration(labelText: 'Qty PKG (طرود)', isDense: true),
                                                      onChanged: (v) {
                                                        final q = double.tryParse(v) ?? 1.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(qtyPkg: q);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.lengthCm.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: InputDecoration(labelText: 'Length (${p.unit})', isDense: true),
                                                      onChanged: (v) {
                                                        final l = double.tryParse(v) ?? 0.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(lengthCm: l);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.widthCm.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: InputDecoration(labelText: 'Width (${p.unit})', isDense: true),
                                                      onChanged: (v) {
                                                        final w = double.tryParse(v) ?? 0.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(widthCm: w);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.heightCm.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: InputDecoration(labelText: 'Height (${p.unit})', isDense: true),
                                                      onChanged: (v) {
                                                        final h = double.tryParse(v) ?? 0.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(heightCm: h);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.netWeightUnitKg.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: const InputDecoration(labelText: 'Net Wt/Unit (kg)', isDense: true),
                                                      onChanged: (v) {
                                                        final nw = double.tryParse(v) ?? 0.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(netWeightUnitKg: nw);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.grossWeightUnitKg.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: const InputDecoration(labelText: 'Gross Wt/Unit (kg)', isDense: true),
                                                      onChanged: (v) {
                                                        final gw = double.tryParse(v) ?? 0.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = p.copyWith(grossWeightUnitKg: gw);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: SearchableDropdownField<bool>(
                                                      value: p.isStackable,
                                                      labelText: 'تعليمات الرص *',
                                                      items: const [
                                                        SearchableDropdownItem(value: true, label: '📦 قابل للرص'),
                                                        SearchableDropdownItem(value: false, label: '🚫 غير قابل للرص'),
                                                      ],
                                                      onChanged: (v) => setState(() {
                                                        _dialogPackingItems[idx] = p.copyWith(isStackable: v ?? true);
                                                      }),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: Colors.blue.shade200),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                        children: [
                                                          Column(
                                                            children: [
                                                              const Text('Total Volume', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                              Text('${p.calculatedCbm.toStringAsFixed(4)} m³', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                                                            ],
                                                          ),
                                                          Column(
                                                            children: [
                                                              const Text('Total Gross Wt', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                              Text('${(p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : (p.qtyPkg * p.grossWeightUnitKg)).toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt)),
                                                            ],
                                                          ),
                                                          Column(
                                                            children: [
                                                              const Text('Air Chargeable', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                              Text('${(p.calculatedCbm * 166.67).toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
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
                      ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            onPressed: (_isSubmitting || isLoadingMaster)
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء استكمال الحقول الإلزامية (الوصف العربي، HS Code، كود البند) بجميع التبويبات.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (_selectedProjectId == null ||
                        _selectedCompanyId == null ||
                        _selectedSupplierId == null ||
                        _selectedIncotermId == null ||
                        _selectedCurrencyId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء التأكد من اختيار كافة الحقول الإلزامية (المشروع، الشركة المستوردة، المورد، الـ Incoterm والعملة).'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (_dialogItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء إضافة بند استيرادي واحد على الأقل في أمر الشراء.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    final tariffs = ref.read(customsTariffProvider).value ?? [];
                    final reconciliation = evaluatePOReconciliation(
                      invoiceItems: _dialogItems,
                      packingItems: _dialogPackingItems,
                      tariffs: tariffs,
                    );

                    String? discrepancyJustification;
                    if (reconciliation.hasDiscrepancy) {
                      discrepancyJustification = await showDialog<String?>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => POReconciliationWarningDialog(report: reconciliation),
                      );

                      // User chose "الرجوع للتعديل" (Back to Edit)
                      if (discrepancyJustification == null || !mounted) {
                        return;
                      }
                    }

                    if (!mounted) return;
                    setState(() => _isSubmitting = true);
                    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 1.0;

                    // Build final notes with justification if provided
                    String? effectiveNotes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
                    if (discrepancyJustification != null && discrepancyJustification.isNotEmpty) {
                      final header = '[مبررات اختلاف الفاتورة والباكينج]: $discrepancyJustification';
                      effectiveNotes = effectiveNotes == null ? header : '$effectiveNotes\n$header';
                    }

                    if (widget.po == null) {
                      final newPO = PurchaseOrderModel(
                        poNumber: '',
                        proformaInvoiceNumber: _piCtrl.text.trim().isEmpty ? null : _piCtrl.text.trim(),
                        countryOfOrigin: _selectedCountryOfOrigin,
                        importFileId: _selectedImportFileId,
                        projectId: _selectedProjectId!,
                        companyId: _selectedCompanyId!,
                        supplierId: _selectedSupplierId!,
                        incotermId: _selectedIncotermId!,
                        currencyId: _selectedCurrencyId!,
                        orderDate: _selectedOrderDate,
                        exchangeRate: rate,
                        paymentTerms: _selectedPaymentTerms,
                        status: _selectedStatus,
                        notes: effectiveNotes,
                        items: _dialogItems,
                        packingListItems: _dialogPackingItems,
                      );
                      final errorMsg = await ref.read(purchaseOrdersProvider.notifier).createPurchaseOrder(newPO);
                      if (errorMsg != null) {
                        setState(() => _isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('خطأ في إدخال أمر الشراء:\n$errorMsg'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('تم إنشاء أمر الشراء بنجاح!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    } else {
                      final oldPO = widget.po!;
                      final List<FieldChangeItem> changes = [];

                      // 1. Header changes
                      final newPi = _piCtrl.text.trim().isEmpty ? null : _piCtrl.text.trim();
                      if (FieldChangeItem.isDifferent(oldPO.proformaInvoiceNumber, newPi)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'رقم الفاتورة المبدئية (PI Number)',
                          oldValue: oldPO.proformaInvoiceNumber,
                          newValue: newPi,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.countryOfOrigin, _selectedCountryOfOrigin)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'بلد المنشأ (Country of Origin)',
                          oldValue: oldPO.countryOfOrigin,
                          newValue: _selectedCountryOfOrigin,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.projectId, _selectedProjectId)) {
                        final oldProj = projects.where((p) => p.projectId == oldPO.projectId).firstOrNull?.projectName ?? '${oldPO.projectId}';
                        final newProj = projects.where((p) => p.projectId == _selectedProjectId).firstOrNull?.projectName ?? '$_selectedProjectId';
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'المشروع الاستيرادي',
                          oldValue: oldProj,
                          newValue: newProj,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.companyId, _selectedCompanyId)) {
                        final oldComp = companies.where((c) => c.companyId == oldPO.companyId).firstOrNull?.importerName ?? '${oldPO.companyId}';
                        final newComp = companies.where((c) => c.companyId == _selectedCompanyId).firstOrNull?.importerName ?? '$_selectedCompanyId';
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'الشركة المستوردة',
                          oldValue: oldComp,
                          newValue: newComp,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.supplierId, _selectedSupplierId)) {
                        final oldSupp = suppliers.where((s) => s.supplierId == oldPO.supplierId).firstOrNull?.companyName ?? '${oldPO.supplierId}';
                        final newSupp = suppliers.where((s) => s.supplierId == _selectedSupplierId).firstOrNull?.companyName ?? '$_selectedSupplierId';
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'المورد الأجنبي',
                          oldValue: oldSupp,
                          newValue: newSupp,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.incotermId, _selectedIncotermId)) {
                        final oldInco = incoterms.where((i) => i.incotermId == oldPO.incotermId).firstOrNull?.incotermCode ?? '${oldPO.incotermId}';
                        final newInco = incoterms.where((i) => i.incotermId == _selectedIncotermId).firstOrNull?.incotermCode ?? '$_selectedIncotermId';
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'شرط الشحن (Incoterm)',
                          oldValue: oldInco,
                          newValue: newInco,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.currencyId, _selectedCurrencyId)) {
                        final oldCurr = currencies.where((c) => c.currencyId == oldPO.currencyId).firstOrNull?.currencyCode ?? '${oldPO.currencyId}';
                        final newCurr = currencies.where((c) => c.currencyId == _selectedCurrencyId).firstOrNull?.currencyCode ?? '$_selectedCurrencyId';
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'عملة أمر الشراء',
                          oldValue: oldCurr,
                          newValue: newCurr,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.exchangeRate, rate)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'سعر الصرف',
                          oldValue: oldPO.exchangeRate,
                          newValue: rate,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.paymentTerms, _selectedPaymentTerms)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'شروط السداد والدفع',
                          oldValue: oldPO.paymentTerms,
                          newValue: _selectedPaymentTerms,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.status, _selectedStatus)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'حالة أمر الشراء',
                          oldValue: oldPO.status,
                          newValue: _selectedStatus,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.notes, effectiveNotes)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'الملاحظات',
                          oldValue: oldPO.notes,
                          newValue: effectiveNotes,
                        ));
                      }

                      // 2. Line Items
                      if (oldPO.items.length != _dialogItems.length) {
                        changes.add(FieldChangeItem(
                          section: 'بنود الفاتورة المبدئية',
                          fieldName: 'عدد بنود الفاتورة',
                          oldValue: '${oldPO.items.length} بند',
                          newValue: '${_dialogItems.length} بند',
                        ));
                      } else {
                        for (int i = 0; i < _dialogItems.length; i++) {
                          final o = oldPO.items[i];
                          final n = _dialogItems[i];
                          if (FieldChangeItem.isDifferent(o.descriptionAr, n.descriptionAr)) {
                            changes.add(FieldChangeItem(
                              section: 'بنود الفاتورة المبدئية',
                              fieldName: 'بند #${i + 1} - الوصف العربي',
                              oldValue: o.descriptionAr,
                              newValue: n.descriptionAr,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.quantity, n.quantity)) {
                            changes.add(FieldChangeItem(
                              section: 'بنود الفاتورة المبدئية',
                              fieldName: 'بند #${i + 1} (${n.itemCode ?? ""}) - الكمية',
                              oldValue: o.quantity,
                              newValue: n.quantity,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.unitPrice, n.unitPrice)) {
                            changes.add(FieldChangeItem(
                              section: 'بنود الفاتورة المبدئية',
                              fieldName: 'بند #${i + 1} (${n.itemCode ?? ""}) - سعر الوحدة',
                              oldValue: o.unitPrice,
                              newValue: n.unitPrice,
                            ));
                          }
                        }
                      }

                      // 3. Packing List Items
                      if (oldPO.packingListItems.length != _dialogPackingItems.length) {
                        changes.add(FieldChangeItem(
                          section: 'قائمة التعبئة (Packing List)',
                          fieldName: 'عدد طرود قائمة التعبئة',
                          oldValue: '${oldPO.packingListItems.length} طرد',
                          newValue: '${_dialogPackingItems.length} طرد',
                        ));
                      } else {
                        for (int i = 0; i < _dialogPackingItems.length; i++) {
                          final o = oldPO.packingListItems[i];
                          final n = _dialogPackingItems[i];
                          if (FieldChangeItem.isDifferent(o.itemCode, n.itemCode)) {
                            changes.add(FieldChangeItem(
                              section: 'قائمة التعبئة (Packing List)',
                              fieldName: 'طرد #${i + 1} - كود البند',
                              oldValue: o.itemCode,
                              newValue: n.itemCode,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.packageType, n.packageType)) {
                            changes.add(FieldChangeItem(
                              section: 'قائمة التعبئة (Packing List)',
                              fieldName: 'طرد #${i + 1} (${n.itemCode}) - نوع الطرد',
                              oldValue: o.packageType,
                              newValue: n.packageType,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.qtyPkg, n.qtyPkg)) {
                            changes.add(FieldChangeItem(
                              section: 'قائمة التعبئة (Packing List)',
                              fieldName: 'طرد #${i + 1} (${n.itemCode}) - عدد الطرود',
                              oldValue: o.qtyPkg,
                              newValue: n.qtyPkg,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.grossWeightUnitKg, n.grossWeightUnitKg)) {
                            changes.add(FieldChangeItem(
                              section: 'قائمة التعبئة (Packing List)',
                              fieldName: 'طرد #${i + 1} (${n.itemCode}) - وزن الطرد (kg)',
                              oldValue: o.grossWeightUnitKg,
                              newValue: n.grossWeightUnitKg,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.isStackable, n.isStackable)) {
                            changes.add(FieldChangeItem(
                              section: 'قائمة التعبئة (Packing List)',
                              fieldName: 'طرد #${i + 1} (${n.itemCode}) - تعليمات الرص',
                              oldValue: o.isStackable ? '📦 قابل للرص' : '🚫 غير قابل للرص',
                              newValue: n.isStackable ? '📦 قابل للرص' : '🚫 غير قابل للرص',
                            ));
                          }
                        }
                      }

                      if (changes.isNotEmpty) {
                        if (!context.mounted) return;
                        final confirmed = await showChangeDiffConfirmationDialog(
                          context,
                          title: 'مراجعة وتأكيد تعديلات أمر الشراء',
                          itemReference: oldPO.poNumber,
                          changes: changes,
                        );
                        if (!confirmed) {
                          if (mounted) setState(() => _isSubmitting = false);
                          return;
                        }
                      }

                      final updateData = {
                        'proforma_invoice_number': _piCtrl.text.trim().isEmpty ? null : _piCtrl.text.trim(),
                        'country_of_origin': _selectedCountryOfOrigin,
                        'import_file_id': _selectedImportFileId,
                        'project_id': _selectedProjectId!,
                        'company_id': _selectedCompanyId!,
                        'supplier_id': _selectedSupplierId!,
                        'incoterm_id': _selectedIncotermId!,
                        'currency_id': _selectedCurrencyId!,
                        'order_date': _selectedOrderDate.toIso8601String(),
                        'exchange_rate': rate,
                        'payment_terms': _selectedPaymentTerms,
                        'status': _selectedStatus,
                        'notes': effectiveNotes,
                        'items': _dialogItems.map((i) => i.toJson()).toList(),
                        'packing_list_items': _dialogPackingItems.map((i) => i.toJson()).toList(),
                      };
                      final errorMsg = await ref.read(purchaseOrdersProvider.notifier).updatePurchaseOrder(widget.po!.poId!, updateData);
                      if (errorMsg != null) {
                        setState(() => _isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('خطأ في تحديث أمر الشراء:\n$errorMsg'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('تم حفظ التعديلات بنجاح!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(widget.po == null ? 'Create PO' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showPoVisualLoadPlannerDialog(BuildContext context, List<PackingListItemModel> packingItems) {
    if (packingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة بنود تعبئة أولاً في قائمة التعبئة لمعاينة رص الحاويات.')),
      );
      return;
    }

    final cargoItems = packingItems.asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final p = entry.value;
      final lCm = p.unit == 'mm' ? p.lengthCm / 10.0 : (p.unit == 'm' ? p.lengthCm * 100.0 : p.lengthCm);
      final wCm = p.unit == 'mm' ? p.widthCm / 10.0 : (p.unit == 'm' ? p.widthCm * 100.0 : p.widthCm);
      final hCm = p.unit == 'mm' ? p.heightCm / 10.0 : (p.unit == 'm' ? p.heightCm * 100.0 : p.heightCm);
      final grossWt = p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : (p.qtyPkg * p.grossWeightUnitKg);

      return CargoItem(
        itemId: '$idx',
        length: lCm > 0 ? lCm : 100.0,
        width: wCm > 0 ? wCm : 80.0,
        height: hCm > 0 ? hCm : 60.0,
        weight: grossWt > 0 ? grossWt : 10.0,
        isStackable: p.isStackable,
        rotate: true,
        packageType: p.packageType,
        description: p.itemCode,
      );
    }).toList();

    final plan = ContainerRequirementEngine.planShipment(cargoItems);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: 1100,
            height: 700,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.view_in_ar_rounded, color: AppTheme.cobalt, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'مخطط ومحاكاة رص الحاويات 3D (Purchase Order Load Planner)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialogCtx)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: plan.length,
                    itemBuilder: (ctx, pIdx) {
                      final res = plan[pIdx];
                      if (res.containerCode == 'FAILED') {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppTheme.crimson, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  res.failureReason ?? 'فشل الرص: تجاوز أبعاد الطرد أو الوزن الأبعاد القياسية المسموح بها داخل الحاوية',
                                  style: const TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "حاوية #${pIdx + 1}: ${res.spec.code} — (${res.placedItems.length} طرد) — استغلال المساحة: ${(res.totalVolume / res.spec.internalVolumeCbm * 100).toStringAsFixed(1)}%",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.cobalt),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 380,
                                child: CustomPaint(
                                  size: const Size(double.infinity, 380),
                                  painter: ContainerLoadPlanPainter(
                                    plan: res,
                                    isTopView: true,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
