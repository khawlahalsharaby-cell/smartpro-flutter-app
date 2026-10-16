import 'package:flutter/material.dart';
import '../../widgets/app_sidebar.dart';
import '../../core/app_colors.dart';

import '../dashboard/dashboard_page.dart';
import '../customers/customers_page.dart';
import '../products/products_page.dart';
import '../invoices/invoices_page.dart';
import '../statement/statement_page.dart';
import '../settings/company_settings_page.dart';
import '../reports/reports_page.dart';

// callback لتمرير ThemeMode للأب (main.dart)
typedef ThemeModeCallback = void Function(ThemeMode mode);

class MainShell extends StatefulWidget {
  final ThemeMode themeMode;
  final ThemeModeCallback onThemeModeChanged;

  const MainShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppPage _currentPage = AppPage.dashboard;

  Widget _buildPage() {
    switch (_currentPage) {
      case AppPage.dashboard:
        return const DashboardPage();
      case AppPage.customers:
        return const CustomersPage();
      case AppPage.products:
        return const ProductsPage();
      case AppPage.invoices:
        return const InvoicesPage();
      case AppPage.statement:
        return const StatementPage();
      case AppPage.companySettings:
        return const CompanySettingsPage();
      case AppPage.reports:
        return const ReportsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar:
          isDesktop
              ? null
              : AppBar(
                title: Text(_pageTitle(_currentPage)),
                actions: [_themeToggleButton()],
              ),
      drawer:
          isDesktop
              ? null
              : Drawer(
                child: AppSidebar(
                  currentPage: _currentPage,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  isDrawer: true,
                ),
              ),
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              currentPage: _currentPage,
              onPageChanged: (page) => setState(() => _currentPage = page),
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildTopBar(context),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(_currentPage),
                      child: _buildPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _pageTitle(_currentPage),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          _themeToggleButton(),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeToggleButton() {
    final isDark = widget.themeMode == ThemeMode.dark;
    return IconButton(
      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
      tooltip: isDark ? 'وضع نهاري' : 'وضع ليلي',
      onPressed: () {
        widget.onThemeModeChanged(isDark ? ThemeMode.light : ThemeMode.dark);
      },
    );
  }

  String _pageTitle(AppPage page) {
    const titles = {
      AppPage.dashboard: 'لوحة التحكم',
      AppPage.customers: 'العملاء',
      AppPage.products: 'المنتجات',
      AppPage.invoices: 'الفواتير',
      AppPage.statement: 'كشف الحساب',
      AppPage.companySettings: 'إعدادات المنشأة',
      AppPage.reports: 'التقارير',
    };
    return titles[page] ?? '';
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
