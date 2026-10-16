import 'package:cloud_firestore/cloud_firestore.dart';

/// يولّد رقم مستند تسلسلي فريد، مشترك بين الفواتير والمدفوعات معاً
/// (بنفس منطق الصورة المرجعية حيث فواتير المبيعات وسندات القبض تتشارك
/// تسلسل أرقام واحد مستمر، مثل 1168213, 1168214...).
///
/// يستخدم عداد مركزي محفوظ في مستند واحد ثابت بـ Firestore، ويزيده بأمان
/// عبر معاملة (Transaction) لتجنب تكرار الرقم عند عمليات حفظ متزامنة.
class DocumentCounterService {
  final _counterDocRef =
  FirebaseFirestore.instance.collection('counters').doc('documents');

  /// الرقم الابتدائي لو لم يُستخدم العداد من قبل — اختياري، يمكن تغييره
  /// ليطابق آخر رقم مستخدم في نظام سابق (مثل 1168200 لمطابقة الصورة المرجعية).
  static const int _startingNumber = 1168200;

  Future<int> getNextDocumentNumber() async {
    return FirebaseFirestore.instance.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(_counterDocRef);

      int currentValue;
      if (!snapshot.exists) {
        currentValue = _startingNumber;
      } else {
        currentValue = (snapshot.data()?['lastNumber'] ?? _startingNumber) as int;
      }

      final nextValue = currentValue + 1;
      transaction.set(_counterDocRef, {'lastNumber': nextValue});
      return nextValue;
    });
  }
}
