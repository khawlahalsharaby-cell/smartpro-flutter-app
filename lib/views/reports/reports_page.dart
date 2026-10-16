import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

import '../../controllers/reports_controller.dart';
import '../../core/app_colors.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final ReportsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ReportsController());
  }

  @override
  void dispose() {
    Get.delete<ReportsController>();
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
          child: Obx(() {
            if (_controller.isLoading.value) {
              return SizedBox(
                height: 380,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (!_controller.hasData.value) {
              return _buildEmptyState(context);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildSummaryCards(context, isDesktop),
                const SizedBox(height: 24),
                isDesktop
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(flex: 3, child: _buildSalesChart(context)),
                        const SizedBox(width: 20),
                        Flexible(
                          flex: 2,
                          child: _buildStatusAndGrowthPanel(context),
                        ),
                      ],
                    )
                    : Column(
                      children: [
                        _buildSalesChart(context),
                        const SizedBox(height: 20),
                        _buildStatusAndGrowthPanel(context),
                      ],
                    ),
                const SizedBox(height: 24),
                _buildCustomerGrowthChart(context),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('التقارير', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        Text(
          'عرض مفصل لأداء المبيعات والعملاء خلال الأشهر الماضية.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, bool isDesktop) {
    final cards = [
      {
        'title': 'إجمالي المبيعات',
        'value': _controller.formatCurrency(_controller.totalSales.value),
        'subtitle': 'إجمالي الإيرادات من الفواتير',
        'color': AppColors.primary,
      },
      {
        'title': 'عدد الفواتير',
        'value': _controller.totalInvoices.value.toString(),
        'subtitle': 'الفواتير المسجلة',
        'color': AppColors.accent,
      },
      {
        'title': 'عدد العملاء',
        'value': _controller.uniqueCustomers.value.toString(),
        'subtitle': 'عملاء فريدون نشطون',
        'color': AppColors.success,
      },
      {
        'title': 'نمو العملاء',
        'value': '${_controller.customerGrowth.toStringAsFixed(0)}%',
        'subtitle': 'مقارنة بالشهر الماضي',
        'color': AppColors.warning,
      },
    ];

    return Wrap(
      runSpacing: 16,
      spacing: 16,
      children:
          cards.map((card) {
            return SizedBox(
              width: isDesktop ? 320 : double.infinity,
              child: _ReportsStatCard(
                title: card['title'] as String,
                value: card['value'] as String,
                subtitle: card['subtitle'] as String,
                color: card['color'] as Color,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSalesChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _ReportsChartCard(
      title: 'مبيعات الشهرية',
      description: 'آخر 12 شهر بالآلاف',
      child: SizedBox(
        height: 260,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine:
                  (_) => FlLine(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
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
                  getTitlesWidget: (value, _) {
                    return Text(
                      '${value.toInt()}k',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= _controller.chartMonths.length) {
                      return const SizedBox();
                    }
                    if (index % 3 != 0) return const SizedBox();
                    return Text(
                      _controller.chartMonths[index],
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots:
                    _controller.monthlySales
                        .asMap()
                        .entries
                        .map(
                          (entry) => FlSpot(entry.key.toDouble(), entry.value),
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
    );
  }

  Widget _buildStatusAndGrowthPanel(BuildContext context) {
    return Column(
      children: [
        _ReportsChartCard(
          title: 'حالة الفواتير',
          description: 'عدد الفواتير حسب الحالة الحالية',
          child: SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final labels = ['مدفوعة', 'معلقة', 'متأخرة'];
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length)
                          return const SizedBox();
                        return Text(
                          labels[index],
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBarGroup(
                    0,
                    _controller.paidInvoices.value.toDouble(),
                    AppColors.success,
                  ),
                  _buildBarGroup(
                    1,
                    _controller.unpaidInvoices.value.toDouble(),
                    AppColors.warning,
                  ),
                  _buildBarGroup(
                    2,
                    _controller.overdueInvoices.value.toDouble(),
                    AppColors.error,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _ReportsChartCard(
          title: 'نمو العملاء',
          description: 'عدد العملاء الجدد حسب الفواتير',
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
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
                      getTitlesWidget: (value, _) {
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 ||
                            index >= _controller.chartMonths.length)
                          return const SizedBox();
                        if (index % 3 != 0) return const SizedBox();
                        return Text(
                          _controller.chartMonths[index],
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots:
                        _controller.customerTrend
                            .asMap()
                            .entries
                            .map(
                              (entry) => FlSpot(
                                entry.key.toDouble(),
                                entry.value.toDouble(),
                              ),
                            )
                            .toList(),
                    isCurved: true,
                    color: AppColors.warning,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  Widget _buildCustomerGrowthChart(BuildContext context) {
    return _ReportsChartCard(
      title: 'عرض نمو العملاء',
      description: 'مقارنة العملاء الفريدين عبر 12 شهر',
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine:
                  (_) => FlLine(color: AppColors.borderLight, strokeWidth: 1),
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
                  getTitlesWidget: (value, _) {
                    return Text(
                      value.toInt().toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= _controller.chartMonths.length)
                      return const SizedBox();
                    if (index % 3 != 0) return const SizedBox();
                    return Text(
                      _controller.chartMonths[index],
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots:
                    _controller.customerTrend
                        .asMap()
                        .entries
                        .map(
                          (entry) => FlSpot(
                            entry.key.toDouble(),
                            entry.value.toDouble(),
                          ),
                        )
                        .toList(),
                isCurved: true,
                color: AppColors.success,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withOpacity(0.2),
                      AppColors.success.withOpacity(0.0),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 72,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 18),
            Text(
              'لا توجد بيانات للتقارير بعد',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'أضف فواتير أو عملاء لتظهر التقارير التحليلية هنا.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _ReportsStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
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
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ReportsChartCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _ReportsChartCard({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
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
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
