import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final _collection = FirebaseFirestore.instance.collection('products');

  // ── Stream لحظي لكل المنتجات ──────────────────
  Stream<List<ProductModel>> getProducts() {
    return _collection.orderBy('name').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList());
  }

  Future<void> addProduct(ProductModel product) async {
    await _collection.add(product.toMap());
  }

  Future<void> updateProduct(String id, ProductModel product) async {
    await _collection.doc(id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _collection.doc(id).delete();
  }
}