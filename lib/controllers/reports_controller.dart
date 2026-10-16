import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../services/customer_service.dart';
import '../services/invoice_service.dart';

class ReportsController extends GetxController {
  InvoiceService? _invoiceServiceInstance;
  CustomerService? _customerServiceInstance;

  InvoiceService get _invoiceService =>
      _invoiceServiceInstance ??= InvoiceService();
  CustomerService get _customerService =>
      _customerServiceInstance ??= CustomerService();

  final RxInt totalInvoices = 0.obs;
  final RxDouble totalSales = 0.0.obs;
  final RxInt uniqueCustomers = 0.obs;
  final RxInt paidInvoices = 0.obs;
  final RxInt unpaidInvoices = 0.obs;
  final RxInt overdueInvoices = 0.obs;
  final RxList<double> monthlySales = List<double>.filled(12, 0.0).obs;
  final RxList<int> customerTrend = List<int>.filled(12, 0).obs;
  final RxList<String> chartMonths = <String>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasData = false.obs;

  final RxList<CustomerModel> _customers = <CustomerModel>[].obs;
  final RxList<InvoiceModel> _invoices = <InvoiceModel>[].obs;

  StreamSubscription<List<InvoiceModel>>? _invoiceSub;
  StreamSubscription<List<CustomerModel>>? _customerSub;

  @override
  void onInit() {
    super.onInit();
    chartMonths.value = _buildMonthLabels();

    _invoiceSub = _invoiceService.getInvoices().listen((invoices) {
      _invoices.value = invoices;
      _syncData();
    });

    _customerSub = _customerService.getCustomers().listen((customers) {
      _customers.value = customers;
      _syncData();
    });
  }

  void updateFromData({
    required List<InvoiceModel> invoices,
    required List<CustomerModel> customers,
  }) {
    _invoices.value = invoices;
    _customers.value = customers;
    _syncData();
  }

  void _syncData() {
    final invoices = _invoices.toList();
    final customers = _customers.toList();

    totalInvoices.value = invoices.length;
    totalSales.value = invoices.fold<double>(
      0.0,
      (sum, invoice) => sum + invoice.total,
    );
    uniqueCustomers.value =
        customers.isNotEmpty
            ? customers.map((customer) => customer.id).toSet().length
            : invoices.map((invoice) => invoice.customerId).toSet().length;
    paidInvoices.value =
        invoices
            .where((invoice) => invoice.status == InvoiceStatus.paid)
            .length;
    unpaidInvoices.value =
        invoices
            .where((invoice) => invoice.status == InvoiceStatus.unpaid)
            .length;
    overdueInvoices.value =
        invoices
            .where((invoice) => invoice.status == InvoiceStatus.overdue)
            .length;
    monthlySales.value = _buildMonthlySales(invoices);
    customerTrend.value = _buildCustomerTrend(invoices);
    chartMonths.value = _buildMonthLabels();
    hasData.value = invoices.isNotEmpty;
    isLoading.value = false;
  }

  String formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
      decimalDigits: 0,
    ).format(value);
  }

  double get salesGrowth {
    if (monthlySales.length < 2) return 0.0;
    final current = monthlySales.last;
    final previous = monthlySales[monthlySales.length - 2];
    if (previous == 0) return current == 0 ? 0 : 100;
    return ((current - previous) / previous) * 100;
  }

  double get customerGrowth {
    if (customerTrend.length < 2) return 0.0;
    final current = customerTrend.last.toDouble();
    final previous = customerTrend[customerTrend.length - 2].toDouble();
    if (previous == 0) return current == 0 ? 0 : 100;
    return ((current - previous) / previous) * 100;
  }

  List<double> _buildMonthlySales(List<InvoiceModel> invoices) {
    final now = DateTime.now();
    final totals = List<double>.filled(12, 0.0);

    for (final invoice in invoices) {
      final monthOffset =
          (now.year - invoice.date.year) * 12 +
          (now.month - invoice.date.month);
      if (monthOffset >= 0 && monthOffset < 12) {
        totals[11 - monthOffset] += invoice.total / 1000;
      }
    }

    return totals;
  }

  List<int> _buildCustomerTrend(List<InvoiceModel> invoices) {
    final now = DateTime.now();
    final trend = List<Set<String>>.generate(12, (_) => <String>{});

    for (final invoice in invoices) {
      final monthOffset =
          (now.year - invoice.date.year) * 12 +
          (now.month - invoice.date.month);
      if (monthOffset >= 0 && monthOffset < 12) {
        trend[11 - monthOffset].add(invoice.customerId);
      }
    }

    return trend.map((set) => set.length).toList();
  }

  List<String> _buildMonthLabels() {
    const monthNames = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final now = DateTime.now();
    final startMonth = now.month - 12;
    return List.generate(12, (index) {
      final monthIndex = (startMonth + index) % 12;
      return monthNames[monthIndex < 0 ? monthIndex + 12 : monthIndex];
    });
  }

  @override
  void onClose() {
    _invoiceSub?.cancel();
    _customerSub?.cancel();
    super.onClose();
  }
}
