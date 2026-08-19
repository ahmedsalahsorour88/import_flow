import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/master_data_export_service.dart';
import '../models/partner_model.dart';
import 'partner_statement_of_account_dialog.dart';

class PartnerDetailsDialog extends StatelessWidget {
  final PartnerModel partner;
  final VoidCallback? onEdit;

  const PartnerDetailsDialog({
    super.key,
    required this.partner,
    this.onEdit,
  });

  static Future<void> show(
    BuildContext context,
    PartnerModel partner, {
    VoidCallback? onEdit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PartnerDetailsDialog(partner: partner, onEdit: onEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = partner.isActive;
    final categories = partner.categoriesList;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 780,
        constraints: const BoxConstraints(maxHeight: 800),
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
                      color: AppTheme.cobalt.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                partner.partnerCode,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                partner.partnerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: categories.map((c) => _buildCategoryChip(c)).toList(),
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
                    // Section 1: Professional Identifiers & Licenses
                    _buildSectionHeader(Icons.verified_outlined, 'الرخص المهنية والأكواد والبيانات القانونية'),
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
                          Row(
                            children: [
                              if (partner.swiftCode != null && partner.swiftCode!.isNotEmpty) ...[
                                Expanded(
                                  child: _buildCopyableInfoField(
                                    context: context,
                                    label: 'كود السويفت البنكي (SWIFT Code)',
                                    value: partner.swiftCode!,
                                    icon: Icons.flash_on_rounded,
                                    highlightColor: AppTheme.cobalt,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (partner.scacCode != null && partner.scacCode!.isNotEmpty) ...[
                                Expanded(
                                  child: _buildCopyableInfoField(
                                    context: context,
                                    label: 'كود الخط الملاحي (SCAC Code)',
                                    value: partner.scacCode!,
                                    icon: Icons.directions_boat_outlined,
                                    highlightColor: AppTheme.cobalt,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (partner.clearanceLicenseNumber != null && partner.clearanceLicenseNumber!.isNotEmpty)
                                Expanded(
                                  child: _buildCopyableInfoField(
                                    context: context,
                                    label: 'رقم ترخيص التخليص الجمركي',
                                    value: partner.clearanceLicenseNumber!,
                                    icon: Icons.card_membership_rounded,
                                    highlightColor: AppTheme.orange,
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCopyableInfoField(
                                  context: context,
                                  label: 'السجل التجاري (Commercial Register)',
                                  value: partner.commercialRegister ?? '-',
                                  icon: Icons.account_balance_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCopyableInfoField(
                                  context: context,
                                  label: 'البطاقة الضريبية (Tax ID)',
                                  value: partner.taxId ?? '-',
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 2: Credit Terms & Financial Conditions
                    _buildSectionHeader(Icons.payments_outlined, 'شروط السداد والائتمان المالي'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildSimpleInfoField(
                                  label: 'نوع وشروط السداد (Payment Terms)',
                                  value: partner.paymentType,
                                  icon: Icons.credit_score_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSimpleInfoField(
                                  label: 'الحد الائتماني (Credit Limit)',
                                  value: '${partner.creditLimit.toStringAsFixed(2)} EGP',
                                  icon: Icons.monetization_on_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSimpleInfoField(
                                  label: 'التقييم (Rating)',
                                  value: '⭐ ${partner.rating.toStringAsFixed(1)} / 5.0',
                                  icon: Icons.star_rate_rounded,
                                ),
                              ),
                            ],
                          ),
                          if (partner.bankCode != null || partner.branchName != null) ...[
                            const Divider(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSimpleInfoField(
                                    label: 'كود البنك',
                                    value: partner.bankCode ?? '-',
                                    icon: Icons.account_balance,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSimpleInfoField(
                                    label: 'اسم الفرع',
                                    value: partner.branchName ?? '-',
                                    icon: Icons.storefront_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 3: Contact & Address
                    _buildSectionHeader(Icons.contact_phone_outlined, 'بيانات التواصل والعنوان الرسمي'),
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
                          Row(
                            children: [
                              Expanded(
                                child: _buildCopyableInfoField(
                                  context: context,
                                  label: 'مسؤول الاتصال (Contact Person)',
                                  value: partner.contactPerson ?? '-',
                                  icon: Icons.person_outline_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCopyableInfoField(
                                  context: context,
                                  label: 'الدولة (Country)',
                                  value: partner.country,
                                  icon: Icons.public,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCopyableInfoField(
                                  context: context,
                                  label: 'الهاتف / الموبايل',
                                  value: partner.phone ?? partner.mobile ?? '-',
                                  icon: Icons.phone_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCopyableInfoField(
                                  context: context,
                                  label: 'البريد الإلكتروني (Email)',
                                  value: partner.email ?? '-',
                                  icon: Icons.email_outlined,
                                ),
                              ),
                            ],
                          ),
                          if (partner.address != null && partner.address!.isNotEmpty) ...[
                            const Divider(height: 14),
                            _buildCopyableInfoField(
                              context: context,
                              label: 'العنوان الكامل',
                              value: partner.address!,
                              icon: Icons.location_on_outlined,
                            ),
                          ],
                          if (partner.website != null && partner.website!.isNotEmpty) ...[
                            const Divider(height: 14),
                            _buildCopyableInfoField(
                              context: context,
                              label: 'الموقع الإلكتروني',
                              value: partner.website!,
                              icon: Icons.language_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (partner.notes != null && partner.notes!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildSectionHeader(Icons.notes_rounded, 'ملاحظات إضافية'),
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
                          partner.notes!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Action Toolbar (طباعة - حفظ PDF - تنزيل إكسل - واتس - إيميل - كشف حساب) ────
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
                  // Left Action Buttons
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
                          await MasterDataExportService.printOrSavePartnerPdf(partner);
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
                          final path = await MasterDataExportService.exportPartnerToExcel(context, partner);
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

                      // 5. Statement of Account Shortcut
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.cobalt,
                          side: const BorderSide(color: AppTheme.cobalt),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        icon: const Icon(Icons.receipt_long_rounded, size: 16),
                        label: const Text('كشف حساب 📑', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          PartnerStatementOfAccountDialog.show(context, partner);
                        },
                      ),
                    ],
                  ),

                  // Right Action Buttons: Edit & Close
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

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cobalt.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        category,
        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCopyableInfoField({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    Color? highlightColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: highlightColor ?? Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: highlightColor ?? AppTheme.charcoal,
                      ),
                    ),
                  ),
                  if (value != '-' && value != 'غير مسجل')
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

  Widget _buildSimpleInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWhatsAppPreviewModal(BuildContext context) {
    final text = MasterDataExportService.generatePartnerWhatsAppText(partner);
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
    final subject = MasterDataExportService.generatePartnerEmailSubject(partner);
    final body = MasterDataExportService.generatePartnerEmailBody(partner);

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
