import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class OrderTrackingPage extends StatefulWidget {
  final int orderId;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingPage> createState() =>
      _OrderTrackingPageState();
}

class _OrderTrackingPageState
    extends State<OrderTrackingPage> {
  String status = "Pending";

  @override
  void initState() {
    super.initState();

    loadOrder();

    supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.orderId)
        .listen((data) {
      if (data.isNotEmpty) {
        setState(() {
          status = data.first['status'];
        });
      }
    });
  }

  Future<void> loadOrder() async {
    final order = await supabase
        .from('orders')
        .select()
        .eq('id', widget.orderId)
        .single();

    setState(() {
      status = order['status'];
    });
  }

  Future<void> cancelOrder() async {
    await supabase
        .from('orders')
        .update({
      'status': 'Cancelled',
    })
        .eq('id', widget.orderId);

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
  Color getStatusColor() {
    switch (status) {
      case 'Rider Assigned':
        return Colors.purple;

      case 'Picked Up':
        return Colors.deepOrange;

      case 'On The Way':
        return Colors.blue;

      case 'Delivered':
        return Colors.green;

      case 'Cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Order"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Order #${widget.orderId}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Current Status',
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: getStatusColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              status == 'Delivered'
                   ? 'Your order has been delivered. Thank you!'
                  : 'Waiting for delivery update...',
              textAlign: TextAlign.center,
            ),

             const SizedBox(height: 20),

            if (status == 'Pending')
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: cancelOrder,
                child: const Text(
                  'CANCEL ORDER',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}