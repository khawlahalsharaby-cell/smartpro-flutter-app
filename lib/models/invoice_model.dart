import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus { paid, unpaid, overdue }

class InvoiceItem {
  final String productId;
  final String productName;
  final int qty;
  final double unitPrice;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
  });

  double get total => qty * unitPrice;

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      qty: (map['qty'] ?? 0) as int,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'qty': qty,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final int documentNumber; // رقم المستند التسلسلي المشترك مع المدفوعات
  final String customerId;
  final String customerName;
  final DateTime date;
  final double subtotal;
  final double taxRate; // نسبة الضريبة كعدد عشري، مثلاً 0.15 = 15%
  final double taxAmount;
  final double total;
  final InvoiceStatus status;
  final List<InvoiceItem> items;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.documentNumber,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.status,
    required this.items,
  });

  /// نسبة الضريبة كنص مقروء، مثلاً "15%"
  String get taxRateLabel => '${(taxRate * 100).toStringAsFixed(0)}%';

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceModel(
      id: doc.id,
      invoiceNumber: data['invoiceNumber'] ?? '',
      documentNumber: (data['documentNumber'] ?? 0) as int,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      // قيمة افتراضية 0.15 فقط للفواتير القديمة المحفوظة قبل إضافة هذا الحقل
      taxRate: (data['taxRate'] ?? 0.15).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: InvoiceStatus.values.firstWhere(
            (s) => s.name == data['status'],
        orElse: () => InvoiceStatus.unpaid,
      ),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((i) => InvoiceItem.fromMap(i as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'documentNumber': documentNumber,
      'customerId': customerId,
      'customerName': customerName,
      'date': Timestamp.fromDate(date),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'status': status.name,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}
