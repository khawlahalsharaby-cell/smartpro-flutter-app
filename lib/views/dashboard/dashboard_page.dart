import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

import '../../controllers/dashboard_controller.dart';
import '../../core/app_colors.dart';
import '../../models/invoice_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _touchedIndex = -1;
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(DashboardController());
  }

  @override
  void dispose() {
    Get.delete<DashboardController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              Obx(() => _buildStatsGrid(context, isDesktop)),
              const SizedBox(height: 24),
              Obx(
                () =>
                    isDesktop
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildSalesChart(context)),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: _buildDonutChart(context)),
                          ],
                        )
                        : Column(
                          children: [
                            _buildSalesChart(context),
                            const SizedBox(height: 20),
                            _buildDonutChart(context),
                          ],
                        ),
              ),
              const SizedBox(height: 24),
              Obx(() => _buildRecentInvoices(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً بك 👋',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'إليك ملخص أعمالك اليوم',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, bool isDesktop) {
    final stats = [
      {
        'title': 'إجمالي المبيعات',
        'value': _controller.formatCurrency(_controller.totalSales.value),
        'subtitle': 'مجموع القيم المدخلة من الفواتير',
        'icon': Icons.trending_up_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF3730A3), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'title': 'عدد الفواتير',
        'value': _controller.totalInvoices.value.toString(),
        'subtitle': 'إجمالي الفواتير المسجلة',
        'icon': Icons.receipt_long_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'title': 'عدد العملاء',
        'value': _controller.uniqueCustomerCount.value.toString(),
        'subtitle': 'عملاء فريدون في قاعدة البيانات',
        'icon': Icons.people_alt_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'title': 'الفواتير المدفوعة',
        'value': _controller.paidInvoices.value.toString(),
        'subtitle': 'تمت تسوية دفعاتها',
        'icon': Icons.check_circle_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop ? 1.6 : 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _StatCard(stat: stats[i]),
    );
  }

  Widget _buildSalesChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthlySales = _controller.monthlySales;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المبيعات الشهرية',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'آخر ١٢ شهر بالآلاف',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (_) => FlLine(
                        color:
                            isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                        strokeWidth: 1,
                      ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget:
                          (v, _) => Text(
                            '${v.toInt()}k',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark
                                      ? AppColors.textSecondaryDk
                                      : AppColors.textSecondary,
                            ),
                          ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= _controller.chartMonths.length)
                          return const SizedBox();
                        if (i % 3 != 0) return const SizedBox();
                        return Text(
                          _controller.chartMonths[i],
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark
                                    ? AppColors.textSecondaryDk
                                    : AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots:
                        monthlySales
                            .asMap()
                            .entries
                            .map(
                              (entry) =>
                                  FlSpot(entry.key.toDouble(), entry.value),
                            )
                            .toList(),
                    isCurved: true,
                    gradient: AppColors.primaryGradient,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total =
        _controller.paidInvoices.value +
        _controller.unpaidInvoices.value +
        _controller.overdueInvoices.value;
    final sections = [
      {
        'label': 'مدفوعة',
        'value':
            total == 0 ? 0.0 : (_controller.paidInvoices.value / total) * 100,
        'color': AppColors.success,
      },
      {
        'label': 'معلقة',
        'value':
            total == 0 ? 0.0 : (_controller.unpaidInvoices.value / total) * 100,
        'color': AppColors.warning,
      },
      {
        'label': 'متأخرة',
        'value':
            total == 0
                ? 0.0
                : (_controller.overdueInvoices.value / total) * 100,
        'color': AppColors.error,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('حالة الفواتير', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'توزيع الفواتير حسب الحالة',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                pieTouchData: PieTouchData(
                  touchCallback: (_, res) {
                    setState(() {
                      _touchedIndex =
                          res?.touchedSection?.touchedSectionIndex ?? -1;
                    });
                  },
                ),
                sections:
                    sections.asMap().entries.map((entry) {
                      final isTouched = entry.key == _touchedIndex;
                      final section = entry.value;
                      return PieChartSectionData(
                        color: section['color'] as Color,
                        value: section['value'] as double,
                        title: '${(section['value'] as double).toInt()}٪',
                        radius: isTouched ? 55 : 45,
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: section['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    section['label'] as String,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${(section['value'] as double).toInt()}٪',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'آخر الفواتير',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('عرض الكل')),
            ],
          ),
          const SizedBox(height: 16),
          if (_controller.recentInvoices.isEmpty)
            Text(
              'لا توجد فواتير حتى الآن',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ..._controller.recentInvoices.map(
              (invoice) =>
                  _InvoiceRow(invoice: invoice, controller: _controller),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Map<String, dynamic> stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: stat['gradient'] as LinearGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (stat['gradient'] as LinearGradient).colors.first
                .withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(stat['icon'] as IconData, color: Colors.white70, size: 22),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    stat['value'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['title'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    stat['subtitle'] as String,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final InvoiceModel invoice;
  final DashboardController controller;
  const _InvoiceRow({required this.invoice, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor =
        invoice.status == InvoiceStatus.paid
            ? AppColors.success
            : invoice.status == InvoiceStatus.overdue
            ? AppColors.error
            : AppColors.warning;
    final statusLabel =
        invoice.status == InvoiceStatus.paid
            ? 'مدفوعة'
            : invoice.status == InvoiceStatus.overdue
            ? 'متأخرة'
            : 'معلقة';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  invoice.customerName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            controller.formatCurrency(invoice.total),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
