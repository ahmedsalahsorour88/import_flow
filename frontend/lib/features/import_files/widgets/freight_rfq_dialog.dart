import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/freight_rfq_generator_service.dart';
import '../../external_service_providers/models/partner_model.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../models/import_file_model.dart';

class FreightRfqDialog extends ConsumerStatefulWidget {
  final int importFileId;
  final String importFileCode;
  final String? customFileNumber;

  const FreightRfqDialog({
    super.key,
    required this.importFileId,
    required this.importFileCode,
    this.customFileNumber,
  });

  static Future<void> show(
    BuildContext context, {
    required int importFileId,
    required String importFileCode,
    String? customFileNumber,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FreightRfqDialog(
        importFileId: importFileId,
        importFileCode: importFileCode,
        customFileNumber: customFileNumber,
      ),
    );
  }

  @override
  ConsumerState<FreightRfqDialog> createState() => _FreightRfqDialogState();
}

class _FreightRfqDialogState extends ConsumerState<FreightRfqDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _recipientController = TextEditingController();
  
  bool _isLoading = true;
  String? _errorMessage;
  FreightRfqDataModel? _rfqData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRfqData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _fetchRfqData([String? recipient]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = Dio();
      final fileParam = widget.customFileNumber?.isNotEmpty == true 
          ? widget.customFileNumber! 
          : widget.importFileId.toString();
      final url = '${ApiConstants.baseUrl}/import-files/$fileParam/freight-rfq';
      final response = await dio.get(
        url,
        queryParameters: {
          if (recipient != null && recipient.trim().isNotEmpty) 'recipient_name': recipient.trim(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _rfqData = FreightRfqDataModel.fromJson(response.data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'فشل جلب بيانات طلب الأسعار من الخادم.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء الاتصال: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(allPartnersProvider);
    final partnersList = (partnersAsync.asData?.value ?? [])
        .where((p) => p.partnerType.contains('Shipping Line') || p.partnerType.contains('Freight Forwarder'))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 1000,
        height: 750,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header Bar
            _buildDialogHeader(),

            // Recipient & Options Filter Bar
            _buildRecipientBar(partnersList),

            // Content Area / Loading
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppTheme.cobalt),
                            SizedBox(height: 16),
                            Text('جاري تجميع تفاصيل الشحنة وتوليد نماذج الأسعار...', style: TextStyle(color: AppTheme.charcoal)),
                          ],
                        ),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: AppTheme.crimson, size: 48),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('إعادة المحاولة'),
                                  onPressed: () => _fetchRfqData(_recipientController.text),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _buildMainContent(),
            ),

            // Footer Actions Bar
            _buildDialogFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    final titleCode = widget.customFileNumber ?? widget.importFileCode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.charcoal,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined, color: AppTheme.cobalt, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'طلب أسعار نولون الشحن الدولي (Freight RFQ Generator)',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ملف الشحنة: $titleCode | توليد رسائل الإيميل والواتساب ومستند الـ PDF الرسمي آلياً',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientBar(List<PartnerModel> partners) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cloudWhite,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_pin_outlined, color: AppTheme.cobalt, size: 20),
          const SizedBox(width: 8),
          const Text('المرسل إليه:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                // Quick dropdown for registered shipping lines
                if (partners.isNotEmpty) ...[
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'اختر خط ملاحي / وكيل...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      items: partners.map((p) => DropdownMenuItem(value: p.partnerName, child: Text(p.partnerName, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _recipientController.text = val;
                          _fetchRfqData(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Free text recipient name
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _recipientController,
                    decoration: InputDecoration(
                      hintText: 'أو اكتب اسم الشخص / الوكيل (مثال: Marian, Raafat, Asma)...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, size: 18, color: AppTheme.cobalt),
                        tooltip: 'تحديث النص',
                        onPressed: () => _fetchRfqData(_recipientController.text),
                      ),
                    ),
                    onSubmitted: (val) => _fetchRfqData(val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('تحديث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cobalt,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onPressed: () => _fetchRfqData(_recipientController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final rfq = _rfqData!;
    return Column(
      children: [
        // Tab Header
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.cobalt,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: AppTheme.cobalt,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.email_outlined), text: 'نموذج الإيميل الرسمي (Email Draft)'),
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'رسالة الواتساب (WhatsApp Template)'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'ملخص مواصفات الشحنة (Shipment Specs)'),
            ],
          ),
        ),
        const Divider(height: 1),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEmailTab(rfq),
              _buildWhatsAppTab(rfq),
              _buildSpecsTab(rfq),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailTab(FreightRfqDataModel rfq) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF9FAFB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject Line Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Text('Subject: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                Expanded(
                  child: SelectableText(
                    rfq.emailSubject,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.cobalt),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: AppTheme.cobalt),
                  tooltip: 'نسخ عنوان الإيميل',
                  onPressed: () => FreightRfqGeneratorService.copyToClipboard(context, rfq.emailSubject, 'عنوان الإيميل'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Email Body Box
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  rfq.emailBodyTemplate,
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 13, height: 1.5, color: Color(0xFF1E293B)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppTab(FreightRfqDataModel rfq) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF0FDF4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WhatsApp Bubble Preview
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  rfq.whatsappTextTemplate,
                  style: const TextStyle(fontSize: 13.5, height: 1.6, color: Color(0xFF0F172A)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info & Quick Action Panel
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 20),
                          SizedBox(width: 8),
                          Text('مميزات رسالة الواتساب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('• منسقة بالرموز والمحاذاة التامة.', style: TextStyle(fontSize: 12)),
                      const Text('• تشمل الحجم الإجمالي والأوزان وعنوان التحميل.', style: TextStyle(fontSize: 12)),
                      const Text('• توضح فترة السماح المطلوبة (21 Days FT).', style: TextStyle(fontSize: 12)),
                      const Text('• جاهزة للمشاركة الفورية مع مندوبي ووكلاء الشحن.', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('نسخ رسالة الواتساب بالكامل'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => FreightRfqGeneratorService.copyToClipboard(context, rfq.whatsappTextTemplate, 'رسالة الواتساب'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsTab(FreightRfqDataModel rfq) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grid of Metrics
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildSpecCard('📦 اسم البضاعة', rfq.commodity, AppTheme.cobalt),
                _buildSpecCard('🌐 شرط الشحن', rfq.incotermCode, AppTheme.orange),
                _buildSpecCard('🚢 المعدات المقترحة', rfq.recommendedContainers, AppTheme.charcoal),
                _buildSpecCard('📐 الحجم الإجمالي (CBM)', '${rfq.totalCbm.toStringAsFixed(2)} m³', AppTheme.emerald),
                _buildSpecCard('⚖️ الوزن القائم (Gross)', '${rfq.grossWeightKg.toStringAsFixed(1)} kg', AppTheme.cobalt),
                _buildSpecCard('⚖️ الوزن الصافي (Net)', '${rfq.netWeightKg.toStringAsFixed(1)} kg', Colors.purple),
                _buildSpecCard('📍 ميناء الشحن (POL)', rfq.portOfLoading, AppTheme.charcoal),
                _buildSpecCard('🏁 ميناء الوصول (POD)', rfq.portOfDischarge, AppTheme.crimson),
                _buildSpecCard('📅 تاريخ الجاهزية', rfq.cargoReadyDate, AppTheme.cobalt),
                _buildSpecCard('⏳ فترة السماح المطلوبة', '${rfq.targetFreeDays} يوماً (FT)', AppTheme.emerald),
              ],
            ),
            const SizedBox(height: 16),

            // Pickup Address Card
            if (rfq.incotermCode.toUpperCase() == 'EXW') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFFD97706), size: 20),
                        SizedBox(width: 8),
                        Text('عنوان الاستلام والتحميل (Pickup Location for EXW):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('المورد: ${rfq.supplierName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(rfq.pickupAddress, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Packaging Breakdown Card
            if (rfq.packagesBreakdown.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.format_list_bulleted, color: AppTheme.cobalt, size: 20),
                        SizedBox(width: 8),
                        Text('تفاصيل الطرود وأبعاد البالتات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(rfq.packagesBreakdown, style: const TextStyle(fontSize: 12, height: 1.5)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecCard(String label, String value, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDialogFooter() {
    final rfq = _rfqData;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          if (rfq != null) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('طباعة / حفظ مستند PDF الرسمي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.charcoal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                final pdfBytes = await FreightRfqGeneratorService.generateFreightRfqPdf(
                  rfq: rfq,
                  recipientName: _recipientController.text,
                );
                if (mounted) {
                  await FreightRfqGeneratorService.printOrSavePdf(
                    context,
                    pdfBytes,
                    rfq.customFileNumber ?? rfq.importFileCode,
                  );
                }
              },
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('نسخ نص الإيميل بالكامل'),
              onPressed: () => FreightRfqGeneratorService.copyToClipboard(context, rfq.emailBodyTemplate, 'نص الإيميل'),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
