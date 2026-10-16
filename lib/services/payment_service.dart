import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import 'document_counter_service.dart';

class PaymentService {
  final _collection = FirebaseFirestore.instance.collection('payments');
  final _counterService = DocumentCounterService();

  // كل المدفوعات (للوحة التحكم أو تقارير عامة)
  Stream<List<PaymentModel>> getAllPayments() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList());
  }

  // مدفوعات عميل معين فقط
  Stream<List<PaymentModel>> getPaymentsForCustomer(String customerId) {
    return _collection
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList());
  }

  /// يحفظ الدفعة بعد توليد رقم مستند تسلسلي آمن من العداد المركزي —
  /// نفس العداد الذي تستخدمه InvoiceService، لضمان تسلسل أرقام مستندات
  /// واحد مستمر بين الفواتير وسندات القبض معاً (كما في كشف الحساب المرجعي).
  /// payment.documentNumber يُتجاوَل هنا عمداً ويُستبدل بالقيمة الحقيقية.
  Future<String> addPayment(PaymentModel payment) async {
    final documentNumber = await _counterService.getNextDocumentNumber();

    final paymentWithDocNumber = PaymentModel(
      id: payment.id,
      documentNumber: documentNumber,
      customerId: payment.customerId,
      customerName: payment.customerName,
      amount: payment.amount,
      date: payment.date,
      method: payment.method,
      note: payment.note,
      invoiceId: payment.invoiceId,
    );

    final doc = await _collection.add(paymentWithDocNumber.toMap());
    return doc.id;
  }

  Future<void> deletePayment(String id) async {
    await _collection.doc(id).delete();
  }
}
