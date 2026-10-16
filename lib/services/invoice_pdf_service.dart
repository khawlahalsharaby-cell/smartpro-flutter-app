import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../models/company_info_model.dart';
import '../models/invoice_model.dart';
import 'company_info_service.dart';
import 'zatca_qr_helper.dart';

/// يبني PDF فاتورة بنفس التخطيط الحرفي للنموذج المرجعي (Due Date / Payment /
/// Bill No / Bill Date / Phone / Address / Tax ID / Customer Name، وجدول
/// منتجات بأعمدة: الإجمالي، الضريبة، نسبة الضريبة، الخصم، السعر الخاضع للضريبة،
/// الكمية، السعر، الوحدة، اسم المنتج، م)، لكن بألوان هوية التطبيق (AppColors)
/// بدل الألوان الأصلية. بيانات المنشأة تُجلب ديناميكياً من CompanyInfoService
/// (التي يُدخلها صاحب المتجر بنفسه عبر شاشة الإعدادات) بدلاً من قيم ثابتة بالكود.
/// أي حقل غير مدعوم بالموديل الحالي (كالخصم) يُترك فاضياً مع الحفاظ على شكل العمود.
class InvoicePdfService {
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF3B82F6);
  static const PdfColor _grayDark = PdfColor.fromInt(0xFF111827);
  static const PdfColor _grayMedium = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _grayLightBg = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFF9CA3AF);
  static const PdfColor _white = PdfColors.white;

  static Future<Uint8List> _generateQrImageBytes(String qrData) async {
    final qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xFF111827),
      emptyColor: const Color(0xFFFFFFFF),
    );
    final imageData = await qrPainter.toImageData(300);
    return imageData!.buffer.asUint8List();
  }

  static Future<Uint8List> generatePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();

    // جلب بيانات المنشأة الحقيقية التي أدخلها صاحب المتجر عبر شاشة الإعدادات.
    // لو لم تُدخل بعد، يرجع CompanyInfoModel.empty() وتظهر الحقول فاضية بالـ PDF
    // بدل قيم وهمية مكتوبة بالكود.
    final companyInfo = await CompanyInfoService().getCompanyInfo();

    final qrData = ZatcaQrHelper.buildQrData(
      sellerName: companyInfo.name,
      vatNumber: companyInfo.taxNumber,
      invoiceDate: invoice.date,
      totalWithVat: invoice.total,
      vatAmount: invoice.taxAmount,
    );
    final qrImageBytes = await _generateQrImageBytes(qrData);
    final qrImage = pw.MemoryImage(qrImageBytes);

    final arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
    final arabicFontBold = await PdfGoogleFonts.notoSansArabicBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildCompanyInfoBox(companyInfo),
              pw.SizedBox(height: 14),
              _buildTitleBar(),
              pw.SizedBox(height: 10),
              _buildTopInfoTable(invoice, companyInfo),
              pw.SizedBox(height: 18),
              _buildItemsTable(invoice),
              // فراغ كبير يطابق المساحة البيضاء الواسعة في النموذج المرجعي
              pw.SizedBox(height: 140),
              _buildFooterRow(invoice, qrImage),
              pw.SizedBox(height: 20),
              _buildAmountInWordsBanner(invoice),
              pw.SizedBox(height: 60),
              _buildLegalFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printInvoice(InvoiceModel invoice) async {
    final bytes = await generatePdf(invoice);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${invoice.invoiceNumber}.pdf',
    );
  }

  static Future<void> shareInvoice(InvoiceModel invoice) async {
    final bytes = await generatePdf(invoice);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${invoice.invoiceNumber}.pdf',
    );
  }

  // ════════════════════════════════════════════════════
  // 1) صندوق بيانات المنشأة العلوي (مطابق لشكل الصورة: إطار واحد، C.R و VAT NO)
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
              pw.Text(
                'C.R :- ${companyInfo.commercialRegistration}',
                style: const pw.TextStyle(fontSize: 8, color: _grayMedium),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'VAT NO:- ${companyInfo.taxNumber}',
                style: const pw.TextStyle(fontSize: 8, color: _grayMedium),
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
  // 2) شريط عنوان "فاتورة ضريبية مبسطة" (مطابق لعنوان الصورة في الوسط)
  // ════════════════════════════════════════════════════
  static pw.Widget _buildTitleBar() {
    return pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'فاتورة ضريبية مبسطة',
        style: pw.TextStyle(
            fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _white),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // 3) جدول المعلومات العلوي — نفس خانات الصورة بالضبط:
  // Due Date | Payment | Bill No | Bill Date
  // Phone No | Address | Tax ID | Customer Name
  // (الحقول غير الموجودة بالموديل — مثل Due Date الفعلي وPhone — تُترك فاضية)
  // ════════════════════════════════════════════════════
  static pw.Widget _buildTopInfoTable(
      InvoiceModel invoice, CompanyInfoModel companyInfo) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.3),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            _infoCell(_formatDate(invoice.date), 'تاريخ الاستحقاق'),
            _infoCell('نقدي', 'طريقة الدفع'),
            _infoCell('\u200E${invoice.invoiceNumber}\u200E', 'رقم الفاتورة'),
            _infoCell(_formatDateTime(invoice.date), 'تاريخ الفاتورة'),
          ],
        ),
        pw.TableRow(
          children: [
            _infoCell('', 'رقم التواصل'),
            _infoCell(companyInfo.address, 'العنوان'),
            _infoCell(companyInfo.taxNumber, 'الرقم الضريبي'),
            _infoCell(invoice.customerName, 'اسم العميل'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _infoCell(String value, String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
                fontSize: 7, fontWeight: pw.FontWeight.bold, color: _grayMedium),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
                fontSize: 8, fontWeight: pw.FontWeight.bold, color: _grayDark),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // 4) جدول المنتجات — نفس أعمدة الصورة بالضبط:
  // الإجمالي | الضريبة | نسبة الضريبة | الخصم | السعر الخاضع للضريبة |
  // الكمية | السعر | الوحدة | اسم المنتج | م
  // الخصم والوحدة (Package) غير موجودين بالموديل — يُتركان فاضيين
  // ════════════════════════════════════════════════════
  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    const headers = [
      'الإجمالي',
      'الضريبة',
      'نسبة الضريبة',
      'الخصم',
      'السعر الخاضع للضريبة',
      'الكمية',
      'السعر',
      'الوحدة',
      'اسم المنتج',
      'م',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(1.1),
        2: pw.FlexColumnWidth(0.9),
        3: pw.FlexColumnWidth(0.8),
        4: pw.FlexColumnWidth(1.5),
        5: pw.FlexColumnWidth(0.8),
        6: pw.FlexColumnWidth(1),
        7: pw.FlexColumnWidth(0.8),
        8: pw.FlexColumnWidth(2.2),
        9: pw.FlexColumnWidth(0.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primaryColor),
          children: headers.map((h) => _tableHeaderCell(h)).toList(),
        ),
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final itemTax = item.total * invoice.taxRate;

          return pw.TableRow(
            children: [
              _tableCell('${item.total.toStringAsFixed(2)}', bold: true),
              _tableCell(itemTax.toStringAsFixed(2)),
              _tableCell(invoice.taxRateLabel),
              _tableCell(''), // الخصم: غير موجود بالموديل الحالي
              _tableCell(item.total.toStringAsFixed(2)),
              _tableCell('${item.qty}'),
              _tableCell(item.unitPrice.toStringAsFixed(2)),
              _tableCell(''), // الوحدة/Package: غير موجود بالموديل الحالي
              _tableCell(item.productName, bold: true, alignRight: true),
              _tableCell('${index + 1}'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
            fontSize: 7, fontWeight: pw.FontWeight.bold, color: _white),
      ),
    );
  }

  static pw.Widget _tableCell(String text,
      {bool bold = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: bold ? _grayDark : _grayMedium,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // 5) التذييل: QR (يسار) + جدول ملخص الحساب (يمين) — مطابق لتوزيع الصورة
  // ════════════════════════════════════════════════════
  static pw.Widget _buildFooterRow(InvoiceModel invoice, pw.MemoryImage qrImage) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _borderColor, width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Image(qrImage, width: 90, height: 90),
        ),
        pw.SizedBox(
          width: 260,
          child: pw.Table(
            border: pw.TableBorder.all(color: _borderColor, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1.4),
            },
            children: [
              _summaryRow(invoice.subtotal.toStringAsFixed(2),
                  'المجموع (غير شامل الضريبة)'),
              _summaryRow('0.00', 'مجموع الخصومات'),
              _summaryRow(
                  invoice.subtotal.toStringAsFixed(2), 'الإجمالي الخاضع للضريبة'),
              _summaryRow(
                  invoice.taxAmount.toStringAsFixed(2), 'مجموع ضريبة القيمة المضافة'),
              _summaryRow(
                invoice.total.toStringAsFixed(2),
                'إجمالي المبلغ المستحق',
                highlight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _summaryRow(String value, String label,
      {bool highlight = false}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: highlight ? _grayLightBg : _white),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: highlight ? 10 : 8.5,
              fontWeight: pw.FontWeight.bold,
              color: highlight ? _primaryColor : _grayDark,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: pw.Text(
            label,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: highlight ? 9 : 8,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: highlight ? _grayDark : _grayMedium,
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  // 6) شريط "المبلغ كتابةً" بعرض كامل الصفحة (مطابق لأسفل الصورة المرجعية)
  // ════════════════════════════════════════════════════
  static pw.Widget _buildAmountInWordsBanner(InvoiceModel invoice) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: pw.BoxDecoration(
        color: _grayLightBg,
        border: pw.Border.all(color: _borderColor, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'المبلغ كتابة: ${_amountToArabicWords(invoice.total)}',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: _grayDark,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // 7) تذييل قانوني نصي بسيط
  // ════════════════════════════════════════════════════
  static pw.Widget _buildLegalFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _signatureBox('توقيع البائع'),
            _signatureBox('توقيع المستلم'),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 0.4)),
          ),
          child: pw.Text(
            'تم إصدار هذه الفاتورة إلكترونياً وهي معتمدة وفقاً لأنظمة هيئة الزكاة والضريبة والجمارك.',
            style: const pw.TextStyle(fontSize: 6.5, color: _grayMedium),
          ),
        ),
      ],
    );
  }

  static pw.Widget _signatureBox(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 150,
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _grayDark, width: 0.6)),
          ),
          padding: const pw.EdgeInsets.only(top: 3),
          child: pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7.5, color: _grayMedium),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  // تحويل المبلغ إلى كلمات عربية (ريال + هللة)
  // ════════════════════════════════════════════════════
  static const List<String> _ones = [
    '', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية',
    'تسعة', 'عشرة', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر',
    'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر'
  ];

  static const List<String> _tens = [
    '', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون',
    'تسعون'
  ];

  static String _convertHundreds(int number) {
    if (number == 0) return '';
    if (number < 20) return _ones[number];
    if (number < 100) {
      final tensPart = _tens[number ~/ 10];
      final onesPart = number % 10;
      return onesPart == 0 ? tensPart : '${_ones[onesPart]} و$tensPart';
    }
    final hundredsDigit = number ~/ 100;
    final remainder = number % 100;
    final hundredsWord = hundredsDigit == 1
        ? 'مئة'
        : hundredsDigit == 2
        ? 'مئتان'
        : '${_ones[hundredsDigit]} مئة';
    if (remainder == 0) return hundredsWord;
    return '$hundredsWord و${_convertHundreds(remainder)}';
  }

  static String _numberToArabicWords(int number) {
    if (number == 0) return 'صفر';

    final millions = number ~/ 1000000;
    final thousands = (number % 1000000) ~/ 1000;
    final hundreds = number % 1000;

    final parts = <String>[];

    if (millions > 0) {
      parts.add(millions == 1 ? 'مليون' : '${_convertHundreds(millions)} مليون');
    }
    if (thousands > 0) {
      parts.add(thousands == 1 ? 'ألف' : '${_convertHundreds(thousands)} ألف');
    }
    if (hundreds > 0) {
      parts.add(_convertHundreds(hundreds));
    }

    return parts.join(' و');
  }

  static String _amountToArabicWords(double amount) {
    final riyals = amount.floor();
    final halalas = ((amount - riyals) * 100).round();

    final riyalsWords = _numberToArabicWords(riyals);
    final riyalsLabel = riyals == 1 ? 'ريال سعودي' : 'ريالاً سعودياً';

    if (halalas == 0) {
      return '$riyalsWords $riyalsLabel فقط لا غير';
    }

    final halalasWords = _numberToArabicWords(halalas);
    const halalasLabel = 'هللة';

    return '$riyalsWords $riyalsLabel و$halalasWords $halalasLabel فقط لا غير';
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
