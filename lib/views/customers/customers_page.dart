import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final CustomerService _service = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<CustomerModel>>(
                stream: _service.getCustomers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                  }
                  final all = snapshot.data ?? [];
                  final filtered = all.where((c) =>
                  c.name.contains(_searchQuery) ||
                      c.phone.contains(_searchQuery) ||
                      c.address.contains(_searchQuery) ||
                      c.accountNumber.contains(_searchQuery)).toList();

                  if (filtered.isEmpty) return _buildEmptyState(context);

                  return isDesktop
                      ? _buildTable(context, filtered, isDark)
                      : _buildCardsList(context, filtered, isDark);
                },
              ),
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
              hintText: 'ابحث باسم العميل أو الهاتف أو رقم الحساب...',
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
          onPressed: () => _showCustomerForm(context),
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('إضافة عميل'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  // ── جدول Desktop ─────────────────────────────────
  Widget _buildTable(
      BuildContext context, List<CustomerModel> customers, bool isDark) {
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
                _headerCell(context, 'العميل', flex: 3),
                _headerCell(context, 'رقم الحساب', flex: 2),
                _headerCell(context, 'المندوب', flex: 2),
                _headerCell(context, 'الهاتف', flex: 2),
                _headerCell(context, 'الإجراءات', flex: 2),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: customers.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              itemBuilder: (_, i) => _buildTableRow(context, customers[i]),
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

  Widget _buildTableRow(BuildContext context, CustomerModel c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    c.name.isNotEmpty ? c.name[0] : '؟',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(c.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(c.accountNumber,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            flex: 2,
            child: Text(c.salesRep,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(c.phone, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            flex: 2,
            child: _ActionButtons(
              onEdit: () => _showCustomerForm(context, existing: c),
              onDelete: () => _confirmDelete(context, c),
            ),
          ),
        ],
      ),
    );
  }

  // ── بطاقات الموبايل ───────────────────────────────
  Widget _buildCardsList(
      BuildContext context, List<CustomerModel> customers, bool isDark) {
    return ListView.separated(
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildMobileCard(context, customers[i], isDark),
    );
  }

  Widget _buildMobileCard(
      BuildContext context, CustomerModel c, bool isDark) {
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
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(c.name.isNotEmpty ? c.name[0] : '؟',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(c.phone,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _infoChip(Icons.tag_rounded, 'حساب: ${c.accountNumber}'),
              _infoChip(Icons.account_tree_rounded,
                  'تحليلي: ${c.analyticalAccount}'),
              _infoChip(Icons.badge_rounded, 'مندوب: ${c.salesRep}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(c.address,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ActionButtons(
            fullWidth: true,
            onEdit: () => _showCustomerForm(context, existing: c),
            onDelete: () => _confirmDelete(context, c),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 64, color: AppColors.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('لا يوجد عملاء بعد',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CustomerModel c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف "${c.name}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await _service.deleteCustomer(c.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف "${c.name}" ✅'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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

  void _showCustomerForm(BuildContext context, {CustomerModel? existing}) {
    showDialog(
      context: context,
      builder: (_) => _CustomerFormDialog(
        service: _service,
        existing: existing,
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// نموذج إضافة/تعديل عميل — يشمل الحقول المحاسبية الجديدة
// ════════════════════════════════════════════════════
class _CustomerFormDialog extends StatefulWidget {
  final CustomerService service;
  final CustomerModel? existing;

  const _CustomerFormDialog({required this.service, this.existing});

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _analyticalAccountCtrl;
  late final TextEditingController _salesRepCtrl;

  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.existing?.address ?? '');
    _accountNumberCtrl =
        TextEditingController(text: widget.existing?.accountNumber ?? '');
    _analyticalAccountCtrl =
        TextEditingController(text: widget.existing?.analyticalAccount ?? '');
    _salesRepCtrl = TextEditingController(text: widget.existing?.salesRep ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _accountNumberCtrl.dispose();
    _analyticalAccountCtrl.dispose();
    _salesRepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEditing ? 'تعديل عميل' : 'إضافة عميل جديد',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 20),
                Text(
                  'البيانات المحاسبية',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _accountNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رقم الحساب',
                    prefixIcon: Icon(Icons.tag_rounded),
                    hintText: 'مثال: 1231',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _analyticalAccountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الحساب التحليلي',
                    prefixIcon: Icon(Icons.account_tree_rounded),
                    hintText: 'مثال: 1121 - شركة سنابل الترف',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _salesRepCtrl,
                  decoration: const InputDecoration(
                    labelText: 'المندوب',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
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
    );
  }

  String? _requiredValidator(String? value) {
    return (value == null || value.trim().isEmpty) ? 'هذا الحقل مطلوب' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final customer = CustomerModel(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      accountNumber: _accountNumberCtrl.text.trim(),
      analyticalAccount: _analyticalAccountCtrl.text.trim(),
      salesRep: _salesRepCtrl.text.trim(),
    );

    if (_isEditing) {
      await widget.service.updateCustomer(customer);
    } else {
      await widget.service.addCustomer(customer);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'تم تحديث العميل ✅' : 'تم إضافة العميل ✅'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// ════════════════════════════════════════════════════
// أزرار الإجراءات (بدون زر كشف حساب — موجود بصفحته الخاصة)
// ════════════════════════════════════════════════════
class _ActionButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool fullWidth;

  const _ActionButtons({
    required this.onEdit,
    required this.onDelete,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final editBtn = IconButton(
      onPressed: onEdit,
      icon: const Icon(Icons.edit_rounded, size: 18),
      color: AppColors.primary,
      tooltip: 'تعديل',
    );

    final deleteBtn = IconButton(
      onPressed: onDelete,
      icon: const Icon(Icons.delete_rounded, size: 18),
      color: AppColors.error,
      tooltip: 'حذف',
    );

    if (fullWidth) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [editBtn, deleteBtn],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [editBtn, deleteBtn],
    );
  }
}
