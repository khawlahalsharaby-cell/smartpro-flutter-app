import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/company_info_model.dart';
import '../models/customer_model.dart';
import 'company_info_service.dart';
import 'statement_service.dart';

/// يبني PDF كشف حساب رسمي لعميل واحد: بيانات المنشأة، بيانات العميل
/// المحاسبية (رقم الحساب، الحساب التحليلي، المندوب)، وجدول حركات
/// (رقم المستند، التاريخ، البيان، مدين، دائن، رصيد متراكم).
///
/// كل البيانات تُجلب ديناميكياً: بيانات المنشأة من CompanyInfoService،
/// وحركات العميل من StatementEntry (المبنية أصلاً من InvoiceModel و
/// PaymentModel الحقيقيين بـ Firestore). لا توجد قيم مكتوبة يدوياً بالكود.
class StatementPdfService {
  // ── نفس ألوان هوية التطبيق المستخدمة في InvoicePdfService ──
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF3B82F6);
  static const PdfColor _grayDark = PdfColor.fromInt(0xFF111827);
  static const PdfColor _grayMedium = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _grayLightBg = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFF9CA3AF);
  static const PdfColor _white = PdfColors.white;

  /// يبني مستند كشف الحساب الكامل ويرجعه كبايتات.
  /// [customer]: العميل المطلوب كشف حسابه (يحتوي البيانات المحاسبية).
  /// [entries]: السجل الزمني الكامل لحركاته (فواتير ومدفوعات)، مرتبة بالتاريخ.
  /// [periodFrom] / [periodTo]: نطاق التاريخ المعروض بأعلى المستند (اختياري).
  static Future<Uint8List> generatePdf({
    required CustomerModel customer,
    required List<StatementEntry> entries,
    DateTime? periodFrom,
    DateTime? periodTo,
  }) async {
    final pdf = pw.Document();

    final companyInfo = await CompanyInfoService().getCompanyInfo();

    final arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
    final arabicFontBold = await PdfGoogleFonts.notoSansArabicBold();

    // نحسب الرصيد المتراكم سطراً بسطر، تماماً كما يظهر بالنموذج المرجعي
    final rowsWithBalance = _buildRunningBalance(entries);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
        margin: const pw.EdgeInsets.all(24),
        header: (context) {
          // الترويسة تتكرر تلقائياً بأعلى كل صفحة عند تعدد الصفحات
          if (context.pageNumber == 1) return pw.SizedBox();
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: _buildCompanyInfoBox(companyInfo),
          );
        },
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7.5, color: _grayMedium),
          ),
        ),
        build: (context) {
          return [
            _buildCompanyInfoBox(companyInfo),
            pw.SizedBox(height: 10),
            _buildTitleBar(),
            pw.SizedBox(height: 10),
            _buildPeriodRow(periodFrom, periodTo),
            pw.SizedBox(height: 8),
            _buildCustomerInfoTable(customer),
            pw.SizedBox(height: 14),
            _buildEntriesTable(rowsWithBalance),
            pw.SizedBox(height: 16),
            _buildFinalBalanceBanner(rowsWithBalance),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printStatement({
    required CustomerModel customer,
    required List<StatementEntry> entries,
    DateTime? periodFrom,
    DateTime? periodTo,
  }) async {
    final bytes = await generatePdf(
      customer: customer,
      entries: entries,
      periodFrom: periodFrom,
      periodTo: periodTo,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'كشف_حساب_${customer.name}.pdf',
    );
  }

  static Future<void> shareStatement({
    required CustomerModel customer,
    required List<StatementEntry> entries,
    DateTime? periodFrom,
    DateTime? periodTo,
  }) async {
    final bytes = await generatePdf(
      customer: customer,
      entries: entries,
      periodFrom: periodFrom,
      periodTo: periodTo,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'كشف_حساب_${customer.name}.pdf',
    );
  }

  // ════════════════════════════════════════════════════
  // حساب الرصيد المتراكم — كل صف يحمل رصيده بعد الحركة، كما بالصورة المرجعية
  // ════════════════════════════════════════════════════
  static List<_StatementRow> _buildRunningBalance(
      List<StatementEntry> entries) {
    double runningBalance = 0;
    final rows = <_StatementRow>[];

    for (final e in entries) {
      runningBalance += e.debit - e.credit;
      rows.add(_StatementRow(entry: e, balanceAfter: runningBalance));
    }

    return rows;
  }

  // ════════════════════════════════════════════════════
  // صندوق بيانات المنشأة العلوي — نفس تصميم InvoicePdfService بالضبط
  // ════════════════════════════════════════════════════
  static pw.Widget _buildCompanyInfoBox(CompanyInfoModel companyInfo) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 0.6),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(
                  'C.R :- ${companyInfo.commercialRegistration}',
                  style: const pw.TextStyle(fontSize: 8, color: _grayMedium),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(
                  'VAT NO:- ${companyInfo.taxNumber}',
                  style: const pw.TextStyle(fontSize: 8, color: _grayMedium),
                ),
              ),
            ],
          ),
          pw.Text(
            companyInfo.name,
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, color: _grayDark),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // شريط عنوان "كشف حساب / Account Statement"
  // ════════════════════════════════════════════════════
  static pw.Widget _buildTitleBar() {
    return pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'كشف حساب',
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold, color: _white),
          ),
          pw.Text(
            'Account Statement',
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: _white),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // صف الفترة الزمنية المعروضة (إن وُجدت)
  // ════════════════════════════════════════════════════
  static pw.Widget _buildPeriodRow(DateTime? from, DateTime? to) {
    if (from == null && to == null) return pw.SizedBox();
    final fromText = from != null ? _formatDate(from) : '';
    final toText = to != null ? _formatDate(to) : 'تاريخ اليوم';

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'الفترة من $fromText إلى $toText',
        style: pw.TextStyle(
            fontSize: 9, fontWeight: pw.FontWeight.bold, color: _grayDark),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // جدول بيانات العميل المحاسبية — اسم الحساب، رقم الحساب، الحساب
  // التحليلي، المندوب (كل القيم من CustomerModel الفعلي)
  // ════════════════════════════════════════════════════
  static pw.Widget _buildCustomerInfoTable(CustomerModel customer) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1.6),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1.6),
      },
      children: [
        pw.TableRow(
          children: [
            _infoCell('اسم الحساب', customer.name, highlight: true),
            _infoCell('رقم الحساب', customer.accountNumber),
            _infoCell('الحساب التحليلي', customer.analyticalAccount),
            _infoCell('المندوب', customer.salesRep),
          ],
        ),
      ],
    );
  }

  static pw.Widget _infoCell(String label, String value,
      {bool highlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              color: highlight ? _primaryColor : _grayLightBg,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: highlight ? _white : _grayMedium,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
                fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _grayDark),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // جدول الحركات — رقم المستند | التاريخ | البيان | مدين | دائن | رصيد
  // (مطابق لترتيب أعمدة الصورة المرجعية، بحدود pw.Table حقيقية)
  // ════════════════════════════════════════════════════
  static pw.Widget _buildEntriesTable(List<_StatementRow> rows) {
    const headers = ['الرصيد', 'دائن', 'مدين', 'البيان', 'رقم المستند', 'التاريخ'];

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(3),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primaryColor),
          children: headers.map((h) => _tableHeaderCell(h)).toList(),
        ),
        // صف الرصيد الافتتاحي (دائماً صفر لأننا نحسب من بداية السجل المتوفر)
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _grayLightBg),
          children: [
            _tableCell('0.00', bold: true),
            _tableCell('0.00'),
            _tableCell('0.00'),
            _tableCell('الرصيد الافتتاحي', alignRight: true, bold: true),
            _tableCell(''),
            _tableCell(''),
          ],
        ),
        ...rows.map((row) {
          final e = row.entry;
          final isInvoice = e.type == StatementEntryType.invoice;
          return pw.TableRow(
            children: [
              _tableCell(row.balanceAfter.toStringAsFixed(2), bold: true),
              _tableCell(e.credit == 0 ? '.00' : e.credit.toStringAsFixed(2)),
              _tableCell(e.debit == 0 ? '.00' : e.debit.toStringAsFixed(2)),
              _tableCell(e.label, alignRight: true, bold: true),
              _tableCell(e.documentNumber > 0 ? '${e.documentNumber}' : '-'),
              _tableCell(_formatDate(e.date)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
            fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _white),
      ),
    );
  }

  static pw.Widget _tableCell(String text,
      {bool bold = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: bold ? _grayDark : _grayMedium,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // شريط الرصيد النهائي بعرض كامل الصفحة
  // ════════════════════════════════════════════════════
  static pw.Widget _buildFinalBalanceBanner(List<_StatementRow> rows) {
    final finalBalance = rows.isEmpty ? 0.0 : rows.last.balanceAfter;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _grayLightBg,
        border: pw.Border.all(color: _primaryColor, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'الرصيد النهائي المستحق',
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold, color: _grayDark),
          ),
          pw.Text(
            '${finalBalance.toStringAsFixed(2)} ر.س',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: finalBalance > 0 ? _primaryColor : _grayDark,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// يربط كل StatementEntry برصيده المتراكم بعد تنفيذ الحركة — كائن داخلي
/// يُستخدم فقط لعرض الجدول، ولا يُحفظ بأي مكان.
class _StatementRow {
  final StatementEntry entry;
  final double balanceAfter;

  _StatementRow({required this.entry, required this.balanceAfter});
}
