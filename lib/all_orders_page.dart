import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

final supabase = Supabase.instance.client;

class AllOrdersPage extends StatefulWidget {
  const AllOrdersPage({super.key});

  @override
  State<AllOrdersPage> createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage> {
  List<dynamic> orders = [];

  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();

    loadOrders();

    supabase
        .channel('new-orders')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'orders',
      callback: (payload) async {
        await playNotification();
        loadOrders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🔔 New Order Received')),
          );
        }
      },
    )
        .subscribe();
  }

  Future<void> loadOrders() async {
    final data = await supabase
        .from('orders')
        .select()
        .order('created_at', ascending: false);

    setState(() {
      orders = data;
    });
  }

  Future<void> playNotification() async {
    await player.play(AssetSource('sounds/order_notification.mp3'));
  }

  Future<void> openMap(dynamic order) async {
    final lat = order['delivery_latitude'];
    final lng = order['delivery_longitude'];

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No delivery location saved for this order.'),
        ),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () async {
              await playNotification();
            },
          ),
        ],
      ),
      body: orders.isEmpty
          ? const Center(child: Text('No Orders Found'))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('Order #${order['id']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${order['status']}'),
                  Text('Type: ${order['order_type'] ?? 'N/A'}'),
                  Text('Customer: ${order['customer_name'] ?? 'N/A'}'),
                  Text('Phone: ${order['customer_phone'] ?? 'N/A'}'),
                  Text('Address: ${order['delivery_address'] ?? 'N/A'}'),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('₦${order['total_amount']}'),
                  IconButton(
                    icon: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      openMap(order);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}