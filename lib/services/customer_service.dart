import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerService {
  final _collection = FirebaseFirestore.instance.collection('customers');

  Stream<List<CustomerModel>> getCustomers() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => CustomerModel.fromFirestore(doc)).toList());
  }

  Future<String> addCustomer(CustomerModel customer) async {
    final doc = await _collection.add(customer.toMap());
    return doc.id;
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    await _collection.doc(customer.id).update(customer.toMap());
  }

  Future<void> deleteCustomer(String id) async {
    await _collection.doc(id).delete();
  }
}
