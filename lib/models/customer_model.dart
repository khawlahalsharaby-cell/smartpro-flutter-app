import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String address;

  // ── حقول محاسبية مطلوبة لكشف الحساب الرسمي ──────────
  final String accountNumber; // رقم الحساب، مثل "1231"
  final String analyticalAccount; // الحساب التحليلي، مثل "1121 - شركة سنابل الترف"
  final String salesRep; // المندوب المسؤول عن هذا العميل

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.accountNumber,
    required this.analyticalAccount,
    required this.salesRep,
  });

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      analyticalAccount: data['analyticalAccount'] ?? '',
      salesRep: data['salesRep'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'accountNumber': accountNumber,
      'analyticalAccount': analyticalAccount,
      'salesRep': salesRep,
    };
  }
}
