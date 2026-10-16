import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<ProductModel>>.value(
      value: ProductService().getProducts(),
      initialData: const [],
      catchError: (_, __) => const [],
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatefulWidget {
  const _ProductsView();

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ProductService _service = ProductService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    // ── البيانات اللحظية من Firestore ──────────────
    final allProducts = context.watch<List<ProductModel>>();
    final products = allProducts
        .where((p) => p.name.contains(_searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context),
            const SizedBox(height: 24),
            Expanded(
              child: allProducts.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : (isDesktop
                  ? _buildTable(context, products, isDark)
                  : _buildCardsList(context, products, isDark)),
            ),
          ],
        ),
      ),
    );
  }

  // ── الشريط العلوي ────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showAddProductDialog(context),
          icon: const Icon(Icons.add_box_rounded, size: 18),
          label: const Text('إضافة منتج'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  // ── جدول Desktop ─────────────────────────────────
  Widget _buildTable(BuildContext context, List<ProductModel> products, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                _headerCell(context, 'المنتج',  flex: 3),
                _headerCell(context, 'السعر',   flex: 2),
                _headerCell(context, 'الكمية',  flex: 2),
                _headerCell(context, 'الوحدة',  flex: 1),
                _headerCell(context, 'الإجراءات', flex: 2),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              itemBuilder: (_, i) => _buildTableRow(context, products[i], isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, ProductModel p, bool isDark) {
    final isLow = p.stock < 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: isLow
          ? AppColors.error.withOpacity(isDark ? 0.06 : 0.04)
          : Colors.transparent,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      size: 16, color: AppColors.accent),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(p.name,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${p.price.toStringAsFixed(0)} ر.س',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            flex: 2,
            child: _StockBadge(stock: p.stock),
          ),
          Expanded(
            flex: 1,
            child: Text(p.unit, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  color: AppColors.primary,
                  onPressed: () => _showEditProductDialog(context, p),
                  tooltip: 'تعديل',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  color: AppColors.error,
                  onPressed: () => _confirmDelete(context, p),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── بطاقات الموبايل ───────────────────────────────
  Widget _buildCardsList(BuildContext context, List<ProductModel> products, bool isDark) {
    if (products.isEmpty) return _buildEmptyState(context);

    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildMobileCard(context, products[i], isDark),
    );
  }

  Widget _buildMobileCard(BuildContext context, ProductModel p, bool isDark) {
    final isLow = p.stock < 5;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showEditProductDialog(context, p),
      onLongPress: () => _confirmDelete(context, p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLow
                ? AppColors.error.withOpacity(0.4)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isLow ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_rounded,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${p.price.toStringAsFixed(0)} ر.س / ${p.unit}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            _StockBadge(stock: p.stock),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.primary.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text('لا توجد منتجات',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ── حذف منتج ─────────────────────────────────────
  void _confirmDelete(BuildContext context, ProductModel p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف "${p.name}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await _service.deleteProduct(p.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف "${p.name}"'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // ── إضافة منتج جديد ──────────────────────────────
  void _showAddProductDialog(BuildContext context) {
    final formKey   = GlobalKey<FormState>();
    final nameCtrl  = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final unitCtrl  = TextEditingController(text: 'قطعة');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إضافة منتج جديد', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج',
                      prefixIcon: Icon(Icons.inventory_2_rounded),
                    ),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'السعر'),
                          validator: (v) =>
                          (double.tryParse(v ?? '') == null) ? 'رقم غير صحيح' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'الكمية'),
                          validator: (v) =>
                          (int.tryParse(v ?? '') == null) ? 'رقم غير صحيح' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(labelText: 'وحدة القياس'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => isSaving = true);

                            final newProduct = ProductModel(
                              id: '', // Firestore يولّده تلقائياً
                              name: nameCtrl.text.trim(),
                              price: double.parse(priceCtrl.text),
                              stock: int.parse(stockCtrl.text),
                              unit: unitCtrl.text.trim().isEmpty
                                  ? 'قطعة'
                                  : unitCtrl.text.trim(),
                            );

                            await _service.addProduct(newProduct);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          child: isSaving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('حفظ'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── تعديل منتج موجود ──────────────────────────────
  void _showEditProductDialog(BuildContext context, ProductModel product) {
    final formKey   = GlobalKey<FormState>();
    final nameCtrl  = TextEditingController(text: product.name);
    final priceCtrl = TextEditingController(text: product.price.toString());
    final stockCtrl = TextEditingController(text: product.stock.toString());
    final unitCtrl  = TextEditingController(text: product.unit);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تعديل منتج', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج',
                      prefixIcon: Icon(Icons.inventory_2_rounded),
                    ),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'السعر'),
                          validator: (v) =>
                          (double.tryParse(v ?? '') == null) ? 'رقم غير صحيح' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'الكمية'),
                          validator: (v) =>
                          (int.tryParse(v ?? '') == null) ? 'رقم غير صحيح' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(labelText: 'وحدة القياس'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => isSaving = true);

                            final updated = ProductModel(
                              id: product.id,
                              name: nameCtrl.text.trim(),
                              price: double.parse(priceCtrl.text),
                              stock: int.parse(stockCtrl.text),
                              unit: unitCtrl.text.trim().isEmpty
                                  ? 'قطعة'
                                  : unitCtrl.text.trim(),
                            );

                            await _service.updateProduct(product.id, updated);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          child: isSaving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('حفظ'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    final isLow      = stock < 5;
    final isVeryLow  = stock <= 2;
    final color = isVeryLow
        ? AppColors.error
        : isLow
        ? AppColors.warning
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLow)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.warning_rounded, size: 13, color: color),
            ),
          Text(
            '$stock',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}