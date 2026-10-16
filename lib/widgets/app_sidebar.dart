import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

// ── مفاتيح التنقل ──────────────────────────────────
enum AppPage {
  dashboard,
  customers,
  products,
  invoices,
  statement,
  companySettings,
  reports,
}

class AppSidebar extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onPageChanged;
  final bool isDrawer; // true = داخل Drawer للموبايل

  const AppSidebar({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 240,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          left: BorderSide(  // RTL — الحد على اليسار
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildLogo(context, isDark),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                _navItem(context, AppPage.dashboard, Icons.dashboard_rounded,     'لوحة التحكم'),
                _navItem(context, AppPage.customers,  Icons.people_alt_rounded,    'العملاء'),
                _navItem(context, AppPage.products,   Icons.inventory_2_rounded,   'المنتجات'),
                _navItem(context, AppPage.invoices,   Icons.receipt_long_rounded,  'الفواتير'),
                _navItem(context, AppPage.statement,  Icons.account_balance_wallet_rounded, 'كشف الحساب'),
                _navItem(context, AppPage.companySettings, Icons.store_rounded, 'إعدادات المنشأة'),
                _navItem(context, AppPage.reports,    Icons.bar_chart_rounded,     'التقارير'),
              ],
            ),
          ),
          _buildFooter(context, isDark),
        ],
      ),
    );
  }

  // ── الشعار ─────────────────────────────────────────
  Widget _buildLogo(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Text(
            'SmartPro',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.textPrimaryDk : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── عنصر التنقل ────────────────────────────────────
  Widget _navItem(
      BuildContext context,
      AppPage page,
      IconData icon,
      String label,
      ) {
    final isActive = currentPage == page;
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            onPageChanged(page);
            if (isDrawer) Navigator.of(context).pop(); // أغلق الـ Drawer
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isActive
                  ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.10)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? AppColors.textSecondaryDk : AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isActive
                        ? AppColors.primary
                        : (isDark ? AppColors.textSecondaryDk : AppColors.textSecondary),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── الفوتر (اسم المستخدم + تسجيل خروج) ────────────
  Widget _buildFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            child: const Icon(Icons.person_rounded, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'المستخدم',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDk : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 18),
            color: AppColors.textSecondary,
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              // سنربطه بـ AuthService لاحقاً
            },
          ),
        ],
      ),
    );
  }
}
