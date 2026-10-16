import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { cash, bankTransfer, card, other }

class PaymentModel {
  final String id;
  final int documentNumber; // رقم المستند التسلسلي المشترك مع الفواتير
  final String customerId;
  final String customerName;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
  final String? note;
  final String? invoiceId; // اختياري: لو الدفعة مرتبطة بفاتورة معينة

  PaymentModel({
    required this.id,
    required this.documentNumber,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.method,
    this.note,
    this.invoiceId,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      documentNumber: (data['documentNumber'] ?? 0) as int,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      method: PaymentMethod.values.firstWhere(
            (m) => m.name == data['method'],
        orElse: () => PaymentMethod.cash,
      ),
      note: data['note'],
      invoiceId: data['invoiceId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentNumber': documentNumber,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'method': method.name,
      'note': note,
      'invoiceId': invoiceId,
    };
  }
}
