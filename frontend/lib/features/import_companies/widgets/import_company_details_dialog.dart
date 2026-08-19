import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/master_data_export_service.dart';
import '../models/import_company_model.dart';

class ImportCompanyDetailsDialog extends StatelessWidget {
  final ImportCompanyModel company;
  final VoidCallback? onEdit;

  const ImportCompanyDetailsDialog({
    super.key,
    required this.company,
    this.onEdit,
  });

  static Future<void> show(
    BuildContext context,
    ImportCompanyModel company, {
    VoidCallback? onEdit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ImportCompanyDetailsDialog(company: company, onEdit: onEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = company.isActive;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 760),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header Banner ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                company.importerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isActive ? AppTheme.emerald : AppTheme.crimson).withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isActive ? AppTheme.emerald : AppTheme.crimson,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: isActive ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'بطاقة بيانات الشركة المستوردة والتراخيص الرقابية (Egyptian Importer Profile)',
                          style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'إغلاق',
                  ),
                ],
              ),
            ),

            // ── Scrollable Body ────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Official Identifiers & Registrations
                    _buildSectionHeader(Icons.verified_user_rounded, 'بيانات القيد والتراخيص الرسمية'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            context: context,
                            icon: Icons.badge_outlined,
                            label: 'رقم البطاقة الاستيرادية (Importer Card ID)',
                            value: company.importerId,
                            expiryDate: company.importerIdExpiry,
                            daysRemaining: company.daysUntilImporterIdExpiry,
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            context: context,
                            icon: Icons.receipt_long_outlined,
                            label: 'رقم التسجيل الضريبي (VAT / Tax ID)',
                            value: company.vatId,
                            expiryDate: company.vatIdExpiry,
                            daysRemaining: company.daysUntilVatExpiry,
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            context: context,
                            icon: Icons.account_balance_outlined,
                            label: 'رقم السجل التجاري (Commercial Reg #)',
                            value: company.registrationNumber,
                            expiryDate: company.registrationExpiry,
                            daysRemaining: company.daysUntilRegExpiry,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 2: Address & Contact Details
                    _buildSectionHeader(Icons.location_on_outlined, 'بيانات الموقع والتواصل'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildSimpleInfoRow(context, Icons.public, 'الدولة (Country)', company.country.isNotEmpty ? company.country : 'جمهورية مصر العربية'),
                          const Divider(height: 14),
                          _buildSimpleInfoRow(context, Icons.home_outlined, 'العنوان (Address)', company.address),
                          const Divider(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSimpleInfoRow(context, Icons.phone_outlined, 'الهاتف (Phone)', company.phone ?? '-'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSimpleInfoRow(context, Icons.email_outlined, 'البريد الإلكتروني (Email)', company.email ?? '-'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (company.notes != null && company.notes!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildSectionHeader(Icons.notes_rounded, 'ملاحظات إدارية ورقمية'),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          company.notes!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Action Toolbar (طباعة - حفظ PDF - تنزيل إكسل - واتس - إيميل) ────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Left Buttons: Print, PDF, Excel
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // 1. Print / Save PDF
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.charcoal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('طباعة / حفظ PDF 🖨️', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await MasterDataExportService.printOrSaveImporterPdf(company);
                        },
                      ),

                      // 2. Export Excel
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E7E34),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.table_view_rounded, size: 16),
                        label: const Text('تنزيل EXCEL 📊', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final path = await MasterDataExportService.exportImporterToExcel(context, company);
                          if (context.mounted && path != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ تم حفظ ملف الإكسل بنجاح: $path'),
                                backgroundColor: AppTheme.emerald,
                              ),
                            );
                          }
                        },
                      ),

                      // 3. WhatsApp Share
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('نسخة واتس 💬', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showWhatsAppPreviewModal(context),
                      ),

                      // 4. Email Share
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cobalt,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.mail_outline_rounded, size: 16),
                        label: const Text('إيميل ✉️', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showEmailPreviewModal(context),
                      ),
                    ],
                  ),

                  // Right Buttons: Edit & Close
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.charcoal,
                            side: const BorderSide(color: AppTheme.charcoal),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('تعديل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.pop(context);
                            onEdit!();
                          },
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إغلاق', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.cobalt),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required DateTime expiryDate,
    required int daysRemaining,
  }) {
    final isExpired = daysRemaining <= 0;
    final isWarning = daysRemaining > 0 && daysRemaining <= 30;

    Color badgeBg = AppTheme.emerald.withOpacity(0.12);
    Color badgeColor = AppTheme.emerald;
    String statusText = 'سارٍ ($daysRemaining يوم)';

    if (isExpired) {
      badgeBg = AppTheme.crimson.withOpacity(0.12);
      badgeColor = AppTheme.crimson;
      statusText = 'منتهي الصلاحية';
    } else if (isWarning) {
      badgeBg = AppTheme.orange.withOpacity(0.15);
      badgeColor = AppTheme.orange;
      statusText = 'ينتهي قريباً ($daysRemaining يوم)';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Row(
                children: [
                  SelectableText(
                    value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم نسخ $value إلى الحافظة'), duration: const Duration(seconds: 1)),
                      );
                    },
                    child: const Icon(Icons.copy, size: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('الانتهاء: ${expiryDate.toIso8601String().split('T')[0]}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 1),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      value,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                    ),
                  ),
                  if (value != '-')
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم نسخ $value إلى الحافظة'), duration: const Duration(seconds: 1)),
                        );
                      },
                      child: const Icon(Icons.copy, size: 13, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWhatsAppPreviewModal(BuildContext context) {
    final text = MasterDataExportService.generateImporterWhatsAppText(company);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
            SizedBox(width: 8),
            Text('نص مشاركة الواتساب (WhatsApp Summary)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: SelectableText(
                  text,
                  style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            icon: const Icon(Icons.copy, color: Colors.white, size: 16),
            label: const Text('نسخ نص الواتس 📋', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ تم نسخ نص الواتساب للحافظة بنجاح!'), backgroundColor: AppTheme.emerald),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEmailPreviewModal(BuildContext context) {
    final subject = MasterDataExportService.generateImporterEmailSubject(company);
    final body = MasterDataExportService.generateImporterEmailBody(company);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mail_outline_rounded, color: AppTheme.cobalt),
            SizedBox(width: 8),
            Text('نموذج البريد الإلكتروني (Email Template)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الموضوع: $subject', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  body,
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
            icon: const Icon(Icons.copy, color: Colors.white, size: 16),
            label: const Text('نسخ نص الإيميل والموضوع 📋', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'الموضوع: $subject\n\n$body'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ تم نسخ نص وموضوع الإيميل للحافظة بنجاح!'), backgroundColor: AppTheme.emerald),
              );
            },
          ),
        ],
      ),
    );
  }
}
