import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/customer_model.dart';
import '../../models/payment_model.dart';
import '../../services/statement_service.dart';
import '../../services/payment_service.dart';
import '../../services/statement_pdf_service.dart';

class StatementPage extends StatefulWidget {
  const StatementPage({super.key});

  @override
  State<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends State<StatementPage> {
  final StatementService _service = StatementService();
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Column(
          children: [
            _buildTopBar(context),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<CustomerStatementSummary>>(
                stream: _service.getAllCustomerSummaries(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                  }
                  final all = snapshot.data ?? [];
                  final filtered = all
                      .where((s) => s.customer.name.contains(_searchQuery))
                      .toList();

                  if (filtered.isEmpty) return _buildEmptyState(context);

                  return isDesktop
                      ? _buildTable(context, filtered)
                      : _buildCardsList(context, filtered);
                },
              ),
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
              hintText: 'ابحث باسم العميل...',
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
      ],
    );
  }

  Widget _buildTable(
      BuildContext context, List<CustomerStatementSummary> summaries) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                _headerCell(context, 'إجمالي الفواتير', flex: 2),
                _headerCell(context, 'المدفوع', flex: 2),
                _headerCell(context, 'الرصيد المتبقي', flex: 2),
                _headerCell(context, '', flex: 1),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: summaries.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              itemBuilder: (_, i) => _buildTableRow(context, summaries[i]),
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
      BuildContext context, CustomerStatementSummary summary) {
    return InkWell(
      onTap: () => _openCustomerStatement(context, summary),
      child: Container(
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
                      summary.customer.name.isNotEmpty
                          ? summary.customer.name[0]
                          : '؟',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(summary.customer.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text('${summary.totalInvoiced.toStringAsFixed(0)} ر.س',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Expanded(
              flex: 2,
              child: Text('${summary.totalPaid.toStringAsFixed(0)} ر.س',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.success)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${summary.balance.toStringAsFixed(0)} ر.س',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: summary.balance > 0
                        ? AppColors.error
                        : AppColors.success),
              ),
            ),
            Expanded(
              flex: 1,
              child: Icon(Icons.chevron_left_rounded,
                  color: AppColors.textSecondary.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsList(
      BuildContext context, List<CustomerStatementSummary> summaries) {
    return ListView.separated(
      itemCount: summaries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildMobileCard(context, summaries[i]),
    );
  }

  Widget _buildMobileCard(
      BuildContext context, CustomerStatementSummary summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openCustomerStatement(context, summary),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    summary.customer.name.isNotEmpty
                        ? summary.customer.name[0]
                        : '؟',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(summary.customer.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Icon(Icons.chevron_left_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.5)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat(context, 'الفواتير',
                    '${summary.totalInvoiced.toStringAsFixed(0)} ر.س', null),
                _miniStat(context, 'المدفوع',
                    '${summary.totalPaid.toStringAsFixed(0)} ر.س',
                    AppColors.success),
                _miniStat(
                  context,
                  'المتبقي',
                  '${summary.balance.toStringAsFixed(0)} ر.س',
                  summary.balance > 0 ? AppColors.error : AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(
      BuildContext context, String label, String value, Color? color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
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

  void _openCustomerStatement(
      BuildContext context, CustomerStatementSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerStatementDetail(summary: summary),
    );
  }
}

// ════════════════════════════════════════════════════
// تفاصيل كشف حساب عميل واحد — مع زر تصدير PDF بالأعلى
// ════════════════════════════════════════════════════
class _CustomerStatementDetail extends StatefulWidget {
  final CustomerStatementSummary summary;
  const _CustomerStatementDetail({required this.summary});

  @override
  State<_CustomerStatementDetail> createState() =>
      _CustomerStatementDetailState();
}

class _CustomerStatementDetailState extends State<_CustomerStatementDetail> {
  final StatementService _statementService = StatementService();
  bool _isExportingPdf = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customer = widget.summary.customer;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text('كشف حساب — ${customer.name}',
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExportingPdf
                        ? null
                        : () => _exportPdf(context, customer),
                    icon: _isExportingPdf
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: Text(_isExportingPdf ? 'جاري التصدير...' : 'تصدير PDF'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddPaymentSheet(context),
                    icon: const Icon(Icons.add_circle_rounded, size: 18),
                    label: const Text('إضافة دفعة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBalanceSummary(context),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<StatementEntry>>(
                stream: _statementService.getCustomerStatement(customer.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final entries = snapshot.data ?? [];
                  if (entries.isEmpty) {
                    return const Center(
                      child: Text('لا توجد حركات في كشف الحساب'),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _buildEntryRow(context, entries[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, CustomerModel customer) async {
    setState(() => _isExportingPdf = true);

    try {
      final entries =
      await _statementService.getCustomerStatement(customer.id).first;

      await StatementPdfService.printStatement(
        customer: customer,
        entries: entries,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر إنشاء ملف PDF: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Widget _buildBalanceSummary(BuildContext context) {
    return StreamBuilder<List<StatementEntry>>(
      stream: _statementService.getCustomerStatement(widget.summary.customer.id),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        final totalDebit = entries.fold<double>(0, (s, e) => s + e.debit);
        final totalCredit = entries.fold<double>(0, (s, e) => s + e.credit);
        final balance = totalDebit - totalCredit;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(context, 'إجمالي عليه',
                  '${totalDebit.toStringAsFixed(0)} ر.س', AppColors.error),
              _summaryItem(context, 'إجمالي مدفوع',
                  '${totalCredit.toStringAsFixed(0)} ر.س', AppColors.success),
              _summaryItem(
                context,
                'الرصيد',
                '${balance.toStringAsFixed(0)} ر.س',
                balance > 0 ? AppColors.error : AppColors.success,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryItem(
      BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildEntryRow(BuildContext context, StatementEntry entry) {
    final isInvoice = entry.type == StatementEntryType.invoice;
    final amount = isInvoice ? entry.debit : entry.credit;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: (isInvoice ? AppColors.error : AppColors.success)
            .withValues(alpha: 0.12),
        child: Icon(
          isInvoice ? Icons.receipt_long_rounded : Icons.payments_rounded,
          size: 18,
          color: isInvoice ? AppColors.error : AppColors.success,
        ),
      ),
      title: Text(entry.label,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')} · مستند #${entry.documentNumber}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '${isInvoice ? '-' : '+'}${amount.toStringAsFixed(0)} ر.س',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isInvoice ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }

  void _showAddPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPaymentForm(customer: widget.summary.customer),
    );
  }
}

// ════════════════════════════════════════════════════
// نموذج إضافة دفعة جديدة
// ════════════════════════════════════════════════════
class _AddPaymentForm extends StatefulWidget {
  final CustomerModel customer;
  const _AddPaymentForm({required this.customer});

  @override
  State<_AddPaymentForm> createState() => _AddPaymentFormState();
}

class _AddPaymentFormState extends State<_AddPaymentForm> {
  final PaymentService _service = PaymentService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text('إضافة دفعة — ${widget.customer.name}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                prefixIcon: Icon(Icons.payments_rounded),
                suffixText: 'ر.س',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              value: _method,
              decoration: const InputDecoration(
                labelText: 'طريقة الدفع',
                prefixIcon: Icon(Icons.credit_card_rounded),
              ),
              items: const [
                DropdownMenuItem(
                    value: PaymentMethod.cash, child: Text('نقدي')),
                DropdownMenuItem(
                    value: PaymentMethod.bankTransfer,
                    child: Text('تحويل بنكي')),
                DropdownMenuItem(
                    value: PaymentMethod.card, child: Text('بطاقة')),
                DropdownMenuItem(
                    value: PaymentMethod.other, child: Text('أخرى')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _method = v);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Text('حفظ الدفعة', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('أدخل مبلغاً صحيحاً'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payment = PaymentModel(
      id: '',
      documentNumber: 0,
      customerId: widget.customer.id,
      customerName: widget.customer.name,
      amount: amount,
      date: DateTime.now(),
      method: _method,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    await _service.addPayment(payment);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ الدفعة ✅'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
