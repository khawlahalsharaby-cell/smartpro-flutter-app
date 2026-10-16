import 'package:cloud_firestore/cloud_firestore.dart';

/// بيانات المنشأة التي يُدخلها صاحب المتجر مرة واحدة، وتُستخدم تلقائياً
/// في كل الفواتير وكشوف الحساب.
class CompanyInfoModel {
  final String name;
  final String commercialRegistration;
  final String taxNumber;
  final String address;
  final String phone;

  const CompanyInfoModel({
    required this.name,
    required this.commercialRegistration,
    required this.taxNumber,
    required this.address,
    required this.phone,
  });

  /// قيم فاضية افتراضية — تُستخدم فقط لو لم يُدخل المستخدم بياناته بعد
  factory CompanyInfoModel.empty() {
    return const CompanyInfoModel(
      name: '',
      commercialRegistration: '',
      taxNumber: '',
      address: '',
      phone: '',
    );
  }

  factory CompanyInfoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return CompanyInfoModel.empty();
    return CompanyInfoModel(
      name: data['name'] ?? '',
      commercialRegistration: data['commercialRegistration'] ?? '',
      taxNumber: data['taxNumber'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'commercialRegistration': commercialRegistration,
      'taxNumber': taxNumber,
      'address': address,
      'phone': phone,
    };
  }

  /// هل أدخل المستخدم بياناته الأساسية بعد؟ (يُستخدم لإظهار تنبيه إن لم يفعل)
  bool get isComplete =>
      name.trim().isNotEmpty &&
          commercialRegistration.trim().isNotEmpty &&
          taxNumber.trim().isNotEmpty;
}
