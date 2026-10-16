import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';
import 'document_counter_service.dart';

class InvoiceService {
  final _collection = FirebaseFirestore.instance.collection('invoices');
  final _counterService = DocumentCounterService();

  Stream<List<InvoiceModel>> getInvoices() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => InvoiceModel.fromFirestore(doc)).toList());
  }

  /// يحفظ الفاتورة بعد توليد رقم مستند تسلسلي آمن لها من العداد المركزي.
  /// invoice.documentNumber يُتجاوَل هنا عمداً ويُستبدل بالقيمة الحقيقية
  /// المولّدة، حتى لا يحتاج المستدعي تمرير رقم صحيح بنفسه.
  Future<String> addInvoice(InvoiceModel invoice) async {
    final documentNumber = await _counterService.getNextDocumentNumber();

    final invoiceWithDocNumber = InvoiceModel(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      documentNumber: documentNumber,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      date: invoice.date,
      subtotal: invoice.subtotal,
      taxRate: invoice.taxRate,
      taxAmount: invoice.taxAmount,
      total: invoice.total,
      status: invoice.status,
      items: invoice.items,
    );

    final doc = await _collection.add(invoiceWithDocNumber.toMap());
    return doc.id;
  }

  Future<void> updateStatus(String id, InvoiceStatus status) async {
    await _collection.doc(id).update({'status': status.name});
  }

  Future<void> deleteInvoice(String id) async {
    await _collection.doc(id).delete();
  }

  /// يولّد رقم فاتورة تسلسلي آمن (INV-0001, INV-0002...) عبر معاملة Firestore،
  /// بدل الاعتماد على عدد الوثائق الحالي (الذي كان يتسبب بتكرار الأرقام
  /// بعد الحذف أو عند الحفظ المتزامن لأكثر من فاتورة في نفس اللحظة).
  Future<String> generateInvoiceNumber() async {
    final counterRef =
    FirebaseFirestore.instance.collection('counters').doc('invoices');

    return FirebaseFirestore.instance.runTransaction<String>((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int currentValue = 0;
      if (snapshot.exists) {
        currentValue = (snapshot.data()?['lastNumber'] ?? 0) as int;
      }

      final nextValue = currentValue + 1;
      transaction.set(counterRef, {'lastNumber': nextValue});

      return 'INV-${nextValue.toString().padLeft(4, '0')}';
    });
  }
}
