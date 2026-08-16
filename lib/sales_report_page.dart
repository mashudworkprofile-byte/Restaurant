import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() =>
      _SalesReportPageState();
}

class _SalesReportPageState
    extends State<SalesReportPage> {

  double totalSales = 0;
  double todaySales = 0;
  double monthlySales = 0;

  int totalOrders = 0;
  int todayOrders = 0;
  int monthlyOrders = 0;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  double selectedMonthSales = 0;
  int selectedMonthOrders = 0;

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    loadSalesData();
  }

  Future<void> loadSalesData() async {

    final orders = await supabase
        .from('orders')
        .select();

    double sales = 0;
    double todayTotal = 0;
    double monthTotal = 0;

    double selectedTotal = 0;

    int todayCount = 0;
    int monthCount = 0;
    int selectedCount = 0;

    final now = DateTime.now();

    for (var order in orders) {

      final amount =
      (order['total_amount'] ?? 0)
          .toDouble();

      sales += amount;

      if (order['created_at'] != null) {

        final orderDate =
        DateTime.parse(
          order['created_at'],
        );

        if (orderDate.year == now.year &&
            orderDate.month == now.month &&
            orderDate.day == now.day) {

          todayTotal += amount;
          todayCount++;
        }

        if (orderDate.year == now.year &&
            orderDate.month == now.month) {

          monthTotal += amount;
          monthCount++;
        }
        if (orderDate.year == selectedYear &&
            orderDate.month == selectedMonth) {

          selectedTotal += amount;
          selectedCount++;
        }
      }
    }

    setState(() {
      totalSales = sales;
      totalOrders = orders.length;

      todaySales = todayTotal;
      monthlySales = monthTotal;

      todayOrders = todayCount;
      monthlyOrders = monthCount;

      selectedMonthSales = selectedTotal;
      selectedMonthOrders = selectedCount;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Reports',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            DropdownButton<int>(
              value: selectedMonth,
              isExpanded: true,
              items: List.generate(
                12,
                    (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text(
                    months[index],
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value!;
                });

                loadSalesData();
              },
            ),

            const SizedBox(height: 15),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_month,
                ),
                title: Text(
                  '${months[selectedMonth - 1]} Report',
                ),
                subtitle: Text(
                  'Sales: ₦${selectedMonthSales.toStringAsFixed(2)}\nOrders: $selectedMonthOrders',
                ),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.money),
                title: const Text(
                  'Total Sales',
                ),
                subtitle: Text(
                  '₦${totalSales.toStringAsFixed(2)}',
                ),
              ),
            ),  
            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt),
                title: const Text(
                  'Total Orders',
                ),
                subtitle: Text(
                  totalOrders.toString(),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.today),
                title: const Text(
                  'Today Sales',
                ),
                subtitle: Text(
                  '₦${todaySales.toStringAsFixed(2)}',
                ),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text(
                  'Today Orders',
                ),
                subtitle: Text(
                  todayOrders.toString(),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text(
                  'Monthly Sales',
                ),
                subtitle: Text(
                  '₦${monthlySales.toStringAsFixed(2)}',
                ),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text(
                  'Monthly Orders',
                ),
                subtitle: Text(
                  monthlyOrders.toString(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}