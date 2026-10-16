import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_info_model.dart';

/// يخزّن بيانات المنشأة في مستند واحد ثابت بـ Firestore
/// (نفس المنشأة لكل المستخدمين الحاليين في هذا التطبيق الواحد).
class CompanyInfoService {
  // مستند ثابت واحد — لا حاجة لمجموعة كاملة لأن المنشأة واحدة فقط
  final _docRef =
  FirebaseFirestore.instance.collection('settings').doc('company_info');

  /// Stream لحظي يحدّث تلقائياً أي مكان يستخدم بيانات المنشأة
  /// (مثل شاشة الإعدادات نفسها) فور تغييرها.
  Stream<CompanyInfoModel> watchCompanyInfo() {
    return _docRef.snapshots().map((doc) {
      if (!doc.exists) return CompanyInfoModel.empty();
      return CompanyInfoModel.fromFirestore(doc);
    });
  }

  /// جلب لمرة واحدة (يُستخدم داخل InvoicePdfService عند توليد كل فاتورة)
  Future<CompanyInfoModel> getCompanyInfo() async {
    final doc = await _docRef.get();
    if (!doc.exists) return CompanyInfoModel.empty();
    return CompanyInfoModel.fromFirestore(doc);
  }

  Future<void> saveCompanyInfo(CompanyInfoModel info) async {
    await _docRef.set(info.toMap());
  }
}
