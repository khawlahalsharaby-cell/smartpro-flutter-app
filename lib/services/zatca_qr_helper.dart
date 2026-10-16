import 'dart:convert';
import 'dart:typed_data';

/// يبني نص QR متوافق مع معيار ZATCA (هيئة الزكاة والضريبة والجمارك السعودية)
/// للفاتورة الضريبية المبسطة، بصيغة TLV (Tag-Length-Value) ثم Base64.
///
/// الحقول الخمسة المطلوبة من المعيار:
/// 1) اسم البائع
/// 2) الرقم الضريبي
/// 3) تاريخ ووقت الفاتورة (ISO 8601)
/// 4) الإجمالي شامل الضريبة
/// 5) مبلغ الضريبة فقط
class ZatcaQrHelper {
  /// يبني نص Base64 الجاهز لتحويله إلى صورة QR.
  static String buildQrData({
    required String sellerName,
    required String vatNumber,
    required DateTime invoiceDate,
    required double totalWithVat,
    required double vatAmount,
  }) {
    final tlvBytes = <int>[];

    tlvBytes.addAll(_buildTlvField(1, sellerName));
    tlvBytes.addAll(_buildTlvField(2, vatNumber));
    tlvBytes.addAll(_buildTlvField(3, invoiceDate.toUtc().toIso8601String()));
    tlvBytes.addAll(_buildTlvField(4, totalWithVat.toStringAsFixed(2)));
    tlvBytes.addAll(_buildTlvField(5, vatAmount.toStringAsFixed(2)));

    return base64Encode(tlvBytes);
  }

  /// يبني حقل TLV واحد: [Tag (1 byte)] [Length (1 byte)] [Value (UTF-8 bytes)]
  static List<int> _buildTlvField(int tag, String value) {
    final valueBytes = utf8.encode(value);
    final field = <int>[];
    field.add(tag); // Tag: رقم الحقل (1 إلى 5)
    field.add(valueBytes.length); // Length: عدد البايتات
    field.addAll(valueBytes); // Value: المحتوى الفعلي
    return field;
  }

  /// مساعد اختياري: يرجع البايتات الخام (لو احتجتها بمكان آخر غير QR)
  static Uint8List buildRawTlvBytes({
    required String sellerName,
    required String vatNumber,
    required DateTime invoiceDate,
    required double totalWithVat,
    required double vatAmount,
  }) {
    final tlvBytes = <int>[];
    tlvBytes.addAll(_buildTlvField(1, sellerName));
    tlvBytes.addAll(_buildTlvField(2, vatNumber));
    tlvBytes.addAll(_buildTlvField(3, invoiceDate.toUtc().toIso8601String()));
    tlvBytes.addAll(_buildTlvField(4, totalWithVat.toStringAsFixed(2)));
    tlvBytes.addAll(_buildTlvField(5, vatAmount.toStringAsFixed(2)));
    return Uint8List.fromList(tlvBytes);
  }
}
