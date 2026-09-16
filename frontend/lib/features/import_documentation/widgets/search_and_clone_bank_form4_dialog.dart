import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/import_documentation_model.dart';

/// Search and Clone Previous Bank Form 4 Dialog (Screen 16 / UX-CLONE-016)
///
/// Allows users to quickly search previous Bank Form 4 records by code,
/// bank name, import file code, currency, or amount, and select one to clone.
class SearchAndCloneBankForm4Dialog extends StatefulWidget {
  final List<BankingDocumentModel> bankingDocs;
  final ValueChanged<BankingDocumentModel> onSelectDoc;

  const SearchAndCloneBankForm4Dialog({
    super.key,
    required this.bankingDocs,
    required this.onSelectDoc,
  });

  @override
  State<SearchAndCloneBankForm4Dialog> createState() => _SearchAndCloneBankForm4DialogState();
}

class _SearchAndCloneBankForm4DialogState extends State<SearchAndCloneBankForm4Dialog> {
  final TextEditingController _queryController = TextEditingController();
  late List<BankingDocumentModel> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.bankingDocs;
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final lower = q.trim().toLowerCase();
    setState(() {
      if (lower.isEmpty) {
        _filtered = widget.bankingDocs;
      } else {
        _filtered = widget.bankingDocs.where((d) {
          final code = d.bankDocCode.toLowerCase();
          final bank = d.bankName.toLowerCase();
          final file = (d.importFileCode ?? '').toLowerCase();
          final currency = d.currencyCode.toLowerCase();
          final amount = d.amount.toString();
          final notes = (d.notes ?? '').toLowerCase();
          final status = d.status.toLowerCase();
          return code.contains(lower) ||
              bank.contains(lower) ||
              file.contains(lower) ||
              currency.contains(lower) ||
              amount.contains(lower) ||
              notes.contains(lower) ||
              status.contains(lower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkCardBackground : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.wcagCobalt.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.copy_all, color: AppTheme.wcagCobalt, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.searchAndCloneBankForm4DialogTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.bankForm4ClonedResetNotice,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Box
              TextField(
                controller: _queryController,
                onChanged: _filter,
                style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : Colors.black87),
                decoration: InputDecoration(
                  hintText: l.searchBankForm4Hint,
                  hintStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600),
                  suffixIcon: _queryController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _queryController.clear();
                            _filter('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.wcagCobalt, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Documents List
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              l.noBankForm4Found,
                              style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = _filtered[index];
                          final formattedAmount = '${doc.amount.toStringAsFixed(2)} ${doc.currencyCode}';
                          final formattedDate = doc.requestDate ?? doc.issueDate.substring(0, doc.issueDate.length >= 10 ? 10 : doc.issueDate.length);

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Leading Icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.wcagCobalt.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.account_balance, color: AppTheme.wcagCobalt, size: 20),
                                ),
                                const SizedBox(width: 12),

                                // Main Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            doc.bankDocCode,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.wcagCobalt),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: doc.status == 'Received'
                                                  ? Colors.green.withOpacity(0.15)
                                                  : Colors.amber.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              doc.status == 'Received' ? l.endorsedStatusBadge : l.bankProcessingStatusBadge,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: doc.status == 'Received'
                                                    ? (isDark ? const Color(0xFF6EE7B7) : Colors.green.shade800)
                                                    : (isDark ? const Color(0xFFFCD34D) : Colors.amber.shade900),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${doc.bankName}  •  ${doc.importFileCode ?? (doc.importFileId != null ? 'IMP-${doc.importFileId}' : '-')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$formattedAmount  •  $formattedDate',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Select / Clone Action Button
                                ElevatedButton.icon(
                                  key: Key('selectCloneBankForm4Btn_${doc.bankDocId}'),
                                  icon: const Icon(Icons.copy, size: 14),
                                  label: Text(l.searchAndCloneBankForm4Btn, style: const TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.wcagCobalt,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    widget.onSelectDoc(doc);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
