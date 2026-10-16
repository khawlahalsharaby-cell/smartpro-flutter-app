import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/company_info_model.dart';
import '../../services/company_info_service.dart';

/// صفحة إعدادات المنشأة — يدخل صاحب المتجر بياناته الرسمية هنا مرة واحدة،
/// وتُستخدم تلقائياً بعد ذلك في كل الفواتير المُولّدة عبر InvoicePdfService.
class CompanySettingsPage extends StatefulWidget {
  const CompanySettingsPage({super.key});

  @override
  State<CompanySettingsPage> createState() => _CompanySettingsPageState();
}

class _CompanySettingsPageState extends State<CompanySettingsPage> {
  final CompanyInfoService _service = CompanyInfoService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _crCtrl = TextEditingController();
  final _vatCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // حالة التحميل: true أثناء جلب البيانات الحالية من Firestore لأول مرة
  bool _isLoading = true;
  // حالة الحفظ: true أثناء إرسال البيانات المعدّلة لـ Firestore
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentInfo();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _crCtrl.dispose();
    _vatCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  /// يجلب بيانات المنشأة الحالية (إن وُجدت) ويعبّئ الحقول بها.
  /// يتعامل مع الحالة الفارغة تلقائياً عبر CompanyInfoModel.empty().
  Future<void> _loadCurrentInfo() async {
    final info = await _service.getCompanyInfo();
    _nameCtrl.text = info.name;
    _crCtrl.text = info.commercialRegistration;
    _vatCtrl.text = info.taxNumber;
    _addressCtrl.text = info.address;
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 28 : 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(context),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم التجاري للمنشأة',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _crCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'رقم السجل التجاري',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vatCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الرقم الضريبي (VAT Number)',
                      prefixIcon: Icon(Icons.receipt_long_rounded),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'العنوان الوطني',
                      prefixIcon: Icon(Icons.location_on_rounded),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
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
                          : const Text('حفظ البيانات',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.store_rounded,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إعدادات المنشأة', style: Theme.of(context).textTheme.titleLarge),
              Text(
                'تُستخدم هذه البيانات تلقائياً في كل الفواتير',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// تحقق بسيط: الحقل لا يجوز أن يكون فاضياً.
  String? _requiredValidator(String? value) {
    return (value == null || value.trim().isEmpty) ? 'هذا الحقل مطلوب' : null;
  }

  /// يتحقق من الحقول، ثم يحفظ البيانات في Firestore ويعرض رسالة نجاح.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final info = CompanyInfoModel(
      name: _nameCtrl.text.trim(),
      commercialRegistration: _crCtrl.text.trim(),
      taxNumber: _vatCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: '', // غير مطلوب بهذا الإصدار من الشاشة حسب المواصفات الحالية
    );

    await _service.saveCompanyInfo(info);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ بيانات المنشأة بنجاح ✅'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
