import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

/// Report Preview — screen 05 kebab: "Download Report" / "Download Critical
/// Report". Mirrors #page-report-preview / openReportPreview() in
/// vanix_screens_preview.html: farm name, report-type label, generated-on
/// date, a Summary stat row (full report adds Critical Alerts + Pending
/// Approvals; critical report shows only Critical Alerts + an italic note),
/// and a sticky Download button that toasts "Report downloaded".
class ReportPreviewScreen extends StatelessWidget {
  final AppState appState;
  final FarmModel farm;
  final bool critical;
  const ReportPreviewScreen({super.key, required this.appState, required this.farm, required this.critical});

  @override
  Widget build(BuildContext context) {
    final lang = appState.languageCode;
    final isDark = appState.isDark;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final levelKey = farmTempLevelKey(farm.temp);
    final levelColor = switch (levelKey) {
      'tempVeryHigh' => VanixColors.danger,
      'tempHigh' => VanixColors.warningInk,
      'tempNormal' => VanixColors.greenInk,
      _ => VanixColors.textHint,
    };
    final now = DateTime(2026, 7, 22, 9, 41);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final generatedOn = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return Scaffold(
      backgroundColor: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 12))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(FS.t(lang, 'reportPreviewTitle'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor)),
                  ),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, size: 20, color: textColor),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: VanixColors.border),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(farm.nm(lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                          const SizedBox(height: 4),
                          Text(
                            FS.t(lang, critical ? 'criticalReport' : 'fullReport'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.danger),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: 4, bottom: 14),
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(text: '${FS.t(lang, 'reportGeneratedOn')} ', style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                                TextSpan(text: generatedOn, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                              ]),
                            ),
                          ),
                          Container(height: 1, color: VanixColors.divider),
                          const SizedBox(height: 14),
                          Text(
                            FS.t(lang, 'reportSummaryWord').toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Color(0xFF999999)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _stat(FS.t(lang, 'statTotalCattle'), '${farm.cattle}', const Color(0xFF111111)),
                              _stat(FS.t(lang, levelKey), appState.fmtTemp(farm.temp), levelColor),
                              if (critical)
                                _stat(FS.t(lang, 'rowCriticalAlerts'), '3', VanixColors.danger)
                              else ...[
                                _stat(FS.t(lang, 'rowCriticalAlerts'), '14', VanixColors.danger),
                                _stat(FS.t(lang, 'rowPendingApprovals'), '2', const Color(0xFF111111)),
                              ],
                            ],
                          ),
                          if (critical)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 14),
                              child: Text(
                                FS.t(lang, 'reportCriticalOnlyNote'),
                                style: const TextStyle(fontSize: 12, color: VanixColors.danger, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sticky footer — Download button pinned to the bottom, content
            // scrolls independently above it (mirrors #report-preview-download
            // moving out of the scrollable doc in vanix_screens_preview.html).
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VanixColors.greenInk,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(FS.t(lang, 'reportDownloaded')), duration: const Duration(seconds: 1)),
                    );
                  },
                  child: Text(FS.t(lang, 'downloadWord'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF7F5F0), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF888888), letterSpacing: 0.4)),
        ],
      ),
    );
  }
}
