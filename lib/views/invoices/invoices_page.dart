import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../models/invoice_model.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../services/invoice_service.dart';
import '../../services/invoice_pdf_service.dart';
import '../../services/document_counter_service.dart';

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<InvoiceModel>>.value(
      value: InvoiceService().getInvoices(),
      initialData: const [],
      catchError: (_, __) => const [],
      child: const _InvoicesView(),
    );
  }
}

class _InvoicesView extends StatefulWidget {
  const _InvoicesView();

  @override
  State<_InvoicesView> createState() => _InvoicesViewState();
}

class _InvoicesViewState extends State<_InvoicesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  InvoiceStatus? _filterStatus;
  final InvoiceService _service = InvoiceService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InvoiceModel> get _filtered {
    final all = context.watch<List<InvoiceModel>>();
    return all.where((inv) {
      final matchSearch = inv.invoiceNumber.contains(_searchQuery) ||
          inv.customerName.contains(_searchQuery);
      final matchStatus =
          _filterStatus == null || inv.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invoices = _filtered;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Column(
          children: [
            _buildTopBar(context),
            const SizedBox(height: 16),
            _buildStatusFilters(context),
            const SizedBox(height: 20),
            Expanded(
              child: isDesktop
                  ? _buildTable(context, invoices, isDark)
                  : _buildCardsList(context, invoices, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ابحث برقم الفاتورة أو اسم العميل...',
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
          onPressed: () => _showNewInvoiceSheet(context),
          icon: const Icon(Icons.add_circle_rounded, size: 18),
          label: const Text('فاتورة جديدة'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilters(BuildContext context) {
    final filters = [
      {'label': 'الكل', 'value': null},
      {'label': 'مدفوعة', 'value': InvoiceStatus.paid},
      {'label': 'غير مدفوعة', 'value': InvoiceStatus.unpaid},
      {'label': 'متأخرة', 'value': InvoiceStatus.overdue},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _filterStatus == f['value'];
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(f['label'] as String),
              selected: isSelected,
              onSelected: (_) =>
                  setState(() => _filterStatus = f['value'] as InvoiceStatus?),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTable(
      BuildContext context, List<InvoiceModel> invoices, bool isDark) {
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
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.06),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                _headerCell(context, 'رقم الفاتورة', flex: 2),
                _headerCell(context, 'العميل', flex: 2),
                _headerCell(context, 'التاريخ', flex: 2),
                _headerCell(context, 'الإجمالي', flex: 2),
                _headerCell(context, 'الحالة', flex: 1),
                _headerCell(context, 'الإجراءات', flex: 3),
              ],
            ),
          ),
          Expanded(
            child: invoices.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
              itemCount: invoices.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
              itemBuilder: (_, i) =>
                  _buildTableRow(context, invoices[i], isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700, color: AppColors.primary)),
    );
  }

  Widget _buildTableRow(
      BuildContext context, InvoiceModel inv, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(inv.invoiceNumber,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(inv.customerName,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${inv.date.year}-${inv.date.month.toString().padLeft(2, '0')}-${inv.date.day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${inv.total.toStringAsFixed(0)} ر.س',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(flex: 1, child: _StatusBadge(status: inv.status)),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  color: AppColors.info,
                  tooltip: 'معاينة',
                  onPressed: () => _previewInvoice(context, inv),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  color: AppColors.error,
                  tooltip: 'طباعة PDF',
                  onPressed: () => _printInvoicePdf(context, inv),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  color: AppColors.success,
                  tooltip: 'تحديد كمدفوعة',
                  onPressed: inv.status == InvoiceStatus.paid
                      ? null
                      : () => _markAsPaid(context, inv),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  color: AppColors.error,
                  tooltip: 'حذف',
                  onPressed: () => _confirmDelete(context, inv),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList(
      BuildContext context, List<InvoiceModel> invoices, bool isDark) {
    if (invoices.isEmpty) return _buildEmptyState(context);

    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildMobileCard(context, invoices[i], isDark),
    );
  }

  Widget _buildMobileCard(
      BuildContext context, InvoiceModel inv, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.invoiceNumber,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(inv.customerName,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              _StatusBadge(status: inv.status),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${inv.date.year}-${inv.date.month.toString().padLeft(2, '0')}-${inv.date.day.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text('${inv.total.toStringAsFixed(0)} ر.س',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _previewInvoice(context, inv),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('معاينة'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _printInvoicePdf(context, inv),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('PDF'),
                ),
              ),
            ],
          ),
          if (inv.status != InvoiceStatus.paid) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markAsPaid(context, inv),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('تحديد مدفوعة'),
                style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('لا توجد فواتير',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _markAsPaid(BuildContext context, InvoiceModel inv) async {
    await _service.updateStatus(inv.id, InvoiceStatus.paid);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديد ${inv.invoiceNumber} كمدفوعة ✅'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// يفتح معاينة الطباعة لملف PDF الفاتورة.
  Future<void> _printInvoicePdf(BuildContext context, InvoiceModel inv) async {
    try {
      await InvoicePdfService.printInvoice(inv);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر إنشاء ملف PDF: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, InvoiceModel inv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الفاتورة ${inv.invoiceNumber} نهائياً؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await _service.deleteInvoice(inv.id);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _previewInvoice(BuildContext context, InvoiceModel inv) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(inv.invoiceNumber,
                      style: Theme.of(context).textTheme.titleLarge),
                  _StatusBadge(status: inv.status),
                ],
              ),
              const Divider(height: 28),
              _previewRow(context, 'العميل', inv.customerName),
              _previewRow(context, 'التاريخ',
                  '${inv.date.year}-${inv.date.month.toString().padLeft(2, '0')}-${inv.date.day.toString().padLeft(2, '0')}'),
              const SizedBox(height: 16),
              Text('المنتجات:',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...inv.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.productName),
                    Text(
                        '${item.qty} × ${item.unitPrice.toStringAsFixed(0)} = ${item.total.toStringAsFixed(0)} ر.س'),
                  ],
                ),
              )),
              const Divider(height: 24),
              _previewRow(context, 'المجموع',
                  '${inv.subtotal.toStringAsFixed(0)} ر.س'),
              _previewRow(context, 'الضريبة ${inv.taxRateLabel}',
                  '${inv.taxAmount.toStringAsFixed(0)} ر.س'),
              _previewRow(context, 'الإجمالي',
                  '${inv.total.toStringAsFixed(0)} ر.س',
                  bold: true),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _printInvoicePdf(context, inv);
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('طباعة PDF'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewRow(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w500,
                  color: bold ? AppColors.primary : null)),
        ],
      ),
    );
  }

  void _showNewInvoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewInvoiceForm(),
    );
  }
}

// ════════════════════════════════════════════════════
// نموذج إنشاء فاتورة جديدة
// ════════════════════════════════════════════════════
class _NewInvoiceForm extends StatefulWidget {
  const _NewInvoiceForm();

  @override
  State<_NewInvoiceForm> createState() => _NewInvoiceFormState();
}

class _NewInvoiceFormState extends State<_NewInvoiceForm> {
  final InvoiceService _service = InvoiceService();
  CustomerModel? _selectedCustomer;
  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  final List<_InvoiceLineItem> _lineItems = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // حقل نسبة الضريبة — افتراضي 15%
  final TextEditingController _taxRateController =
  TextEditingController(text: '15');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final custSnap = await FirebaseFirestore.instance
        .collection('customers')
        .orderBy('name')
        .get();
    final prodSnap = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('name')
        .get();

    setState(() {
      _customers =
          custSnap.docs.map((d) => CustomerModel.fromFirestore(d)).toList();
      _products =
          prodSnap.docs.map((d) => ProductModel.fromFirestore(d)).toList();
      _isLoading = false;
    });
  }

  double get _subtotal =>
      _lineItems.fold(0, (s, i) => s + i.product.price * i.qty);

  /// نسبة الضريبة كعدد عشري (مثلاً 15 بالحقل تتحول لـ 0.15)
  /// تتعامل بأمان مع أي إدخال غير صحيح أو فاضي بافتراض 15%
  double get _taxRate {
    final parsed = double.tryParse(_taxRateController.text);
    if (parsed == null) return 0.15;
    return parsed / 100;
  }

  double get _tax => _subtotal * _taxRate;
  double get _total => _subtotal + _tax;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('فاتورة جديدة',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  // اختيار العميل
                  DropdownButtonFormField<CustomerModel>(
                    value: _selectedCustomer,
                    decoration: const InputDecoration(
                      labelText: 'اختر العميل',
                      prefixIcon:
                      Icon(Icons.person_rounded),
                    ),
                    items: _customers
                        .map((c) => DropdownMenuItem(
                        value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCustomer = v),
                  ),
                  const SizedBox(height: 24),

                  // المنتجات
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المنتجات',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium),
                      TextButton.icon(
                        onPressed: _products.isEmpty
                            ? null
                            : _addLineItem,
                        icon: const Icon(Icons.add_rounded,
                            size: 18),
                        label: const Text('إضافة منتج'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_lineItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.borderLight,
                            style: BorderStyle.solid),
                      ),
                      child: const Center(
                        child: Text('اضغط "إضافة منتج" لإضافة أصناف للفاتورة'),
                      ),
                    )
                  else
                    ..._lineItems.asMap().entries.map(
                          (entry) => _buildLineItemRow(
                          context, entry.key, entry.value),
                    ),

                  const SizedBox(height: 20),

                  // حقل نسبة الضريبة (قابل للتعديل)
                  TextField(
                    controller: _taxRateController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'نسبة الضريبة',
                      prefixIcon: Icon(Icons.percent_rounded),
                      suffixText: '%',
                      helperText: 'القيمة الافتراضية 15% — يمكن تعديلها',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // الإجماليات
                  if (_lineItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                        AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _totalRow(context, 'المجموع',
                              '${_subtotal.toStringAsFixed(0)} ر.س'),
                          _totalRow(
                              context,
                              'الضريبة (${(_taxRate * 100).toStringAsFixed(0)}%)',
                              '${_tax.toStringAsFixed(0)} ر.س'),
                          const Divider(),
                          _totalRow(
                            context,
                            'الإجمالي',
                            '${_total.toStringAsFixed(0)} ر.س',
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                (_isSaving || _selectedCustomer == null || _lineItems.isEmpty)
                    ? null
                    : _saveInvoice,
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Text('حفظ الفاتورة',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemRow(
      BuildContext context, int index, _InvoiceLineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<ProductModel>(
              value: item.product,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'المنتج',
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _products
                  .map((p) =>
                  DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (p) {
                if (p != null) {
                  setState(() => _lineItems[index].product = p);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: item.qty.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الكمية',
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (v) {
                final qty = int.tryParse(v) ?? 1;
                setState(() => _lineItems[index].qty = qty);
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(item.product.price * item.qty).toStringAsFixed(0)} ر.س',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_rounded,
                color: AppColors.error, size: 20),
            onPressed: () =>
                setState(() => _lineItems.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: bold ? AppColors.primary : null)),
        ],
      ),
    );
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(_InvoiceLineItem(product: _products.first, qty: 1));
    });
  }

  Future<void> _saveInvoice() async {
    setState(() => _isSaving = true);

    final invoiceNumber = await _service.generateInvoiceNumber();

    final invoice = InvoiceModel(
      id: '',
      documentNumber: await DocumentCounterService().getNextDocumentNumber(),
      invoiceNumber: invoiceNumber,
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      date: DateTime.now(),
      subtotal: _subtotal,
      taxRate: _taxRate,
      taxAmount: _tax,
      total: _total,
      status: InvoiceStatus.unpaid,
      items: _lineItems
          .map((line) => InvoiceItem(
        productId: line.product.id,
        productName: line.product.name,
        qty: line.qty,
        unitPrice: line.product.price,
      ))
          .toList(),
    );

    await _service.addInvoice(invoice);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ الفاتورة $invoiceNumber ✅'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// Helper class
class _InvoiceLineItem {
  ProductModel product;
  int qty;

  _InvoiceLineItem({required this.product, required this.qty});
}

// ════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;

    switch (status) {
      case InvoiceStatus.paid:
        color = AppColors.success;
        label = 'مدفوعة';
        break;
      case InvoiceStatus.unpaid:
        color = AppColors.warning;
        label = 'غير مدفوعة';
        break;
      case InvoiceStatus.overdue:
        color = AppColors.error;
        label = 'متأخرة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
