import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';

/// يمثل ملخص الحساب لعميل واحد: إجمالي الفواتير، إجمالي المدفوع، والرصيد المتبقي
class CustomerStatementSummary {
  final CustomerModel customer;
  final double totalInvoiced;
  final double totalPaid;
  double get balance => totalInvoiced - totalPaid;

  CustomerStatementSummary({
    required this.customer,
    required this.totalInvoiced,
    required this.totalPaid,
  });
}

/// عنصر واحد في سجل كشف الحساب (فاتورة أو دفعة) — لعرضه بترتيب زمني موحّد
enum StatementEntryType { invoice, payment }

class StatementEntry {
  final StatementEntryType type;
  final int documentNumber; // رقم المستند التسلسلي الموحّد (من الفاتورة أو الدفعة)
  final DateTime date;
  final String label; // مثلاً "فاتورة INV-0001" أو "دفعة نقدية"
  final double debit; // فاتورة جديدة = مديونية على العميل
  final double credit; // دفعة = تخفيف المديونية
  final String refId; // id الفاتورة أو الدفعة

  StatementEntry({
    required this.type,
    required this.documentNumber,
    required this.date,
    required this.label,
    required this.debit,
    required this.credit,
    required this.refId,
  });
}

class StatementService {
  final _customersCollection =
  FirebaseFirestore.instance.collection('customers');
  final _invoicesCollection =
  FirebaseFirestore.instance.collection('invoices');
  final _paymentsCollection =
  FirebaseFirestore.instance.collection('payments');

  /// يرجع ملخص الأرصدة لكل العملاء — يُستخدم في قائمة StatementPage الرئيسية
  Stream<List<CustomerStatementSummary>> getAllCustomerSummaries() {
    // ندمج 3 streams: العملاء + الفواتير + المدفوعات
    return _customersCollection.snapshots().asyncMap((custSnap) async {
      final customers =
      custSnap.docs.map((d) => CustomerModel.fromFirestore(d)).toList();

      final invoicesSnap = await _invoicesCollection.get();
      final paymentsSnap = await _paymentsCollection.get();

      final invoices =
      invoicesSnap.docs.map((d) => InvoiceModel.fromFirestore(d)).toList();
      final payments =
      paymentsSnap.docs.map((d) => PaymentModel.fromFirestore(d)).toList();

      return customers.map((customer) {
        final customerInvoices =
        invoices.where((inv) => inv.customerId == customer.id);
        final customerPayments =
        payments.where((p) => p.customerId == customer.id);

        final totalInvoiced =
        customerInvoices.fold<double>(0, (s, inv) => s + inv.total);
        final totalPaid =
        customerPayments.fold<double>(0, (s, p) => s + p.amount);

        return CustomerStatementSummary(
          customer: customer,
          totalInvoiced: totalInvoiced,
          totalPaid: totalPaid,
        );
      }).toList()
        ..sort((a, b) => b.balance.compareTo(a.balance)); // الأعلى مديونية أولاً
    });
  }

  /// يرجع السجل التفصيلي (فواتير + مدفوعات) لعميل واحد، مرتب بالتاريخ
  Stream<List<StatementEntry>> getCustomerStatement(String customerId) {
    return _invoicesCollection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .asyncMap((invSnap) async {
      final paymentsSnap = await _paymentsCollection
          .where('customerId', isEqualTo: customerId)
          .get();

      final invoices =
      invSnap.docs.map((d) => InvoiceModel.fromFirestore(d)).toList();
      final payments =
      paymentsSnap.docs.map((d) => PaymentModel.fromFirestore(d)).toList();

      final entries = <StatementEntry>[];

      for (final inv in invoices) {
        entries.add(StatementEntry(
          type: StatementEntryType.invoice,
          documentNumber: inv.documentNumber,
          date: inv.date,
          label: 'فاتورة مبيعات فاتورة رقم \u200E${inv.invoiceNumber}\u200E',
          debit: inv.total,
          credit: 0,
          refId: inv.id,
        ));
      }

      for (final p in payments) {
        entries.add(StatementEntry(
          type: StatementEntryType.payment,
          documentNumber: p.documentNumber,
          date: p.date,
          label: _paymentLabel(p),
          debit: 0,
          credit: p.amount,
          refId: p.id,
        ));
      }

      // ترتيب بالتاريخ أولاً، وبرقم المستند كحسم للتعادل (نفس اليوم)
      entries.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        return dateCompare != 0
            ? dateCompare
            : a.documentNumber.compareTo(b.documentNumber);
      });
      return entries;
    });
  }

  String _paymentLabel(PaymentModel p) {
    switch (p.method) {
      case PaymentMethod.cash:
        return 'سند قبض نقدي';
      case PaymentMethod.bankTransfer:
        return 'سند قبض - تحويل بنكي';
      case PaymentMethod.card:
        return 'سند قبض - بطاقة';
      case PaymentMethod.other:
        return p.note?.isNotEmpty == true ? 'سند قبض - ${p.note}' : 'سند قبض';
    }
  }
}
