import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final supabase = Supabase.instance.client;

class RiderPage extends StatefulWidget {
  final int riderId;
  final String riderName;

  const RiderPage({
    super.key,
    required this.riderId,
    required this.riderName,
  });

  @override
  State<RiderPage> createState() => _RiderPageState();
}

class _RiderPageState extends State<RiderPage> {
  List<dynamic> deliveries = [];

  @override
  void initState() {
    super.initState();

    loadDeliveries();

    supabase.from('orders').stream(primaryKey: ['id']).listen((_) {
      loadDeliveries();
    });
  }

  Future<void> loadDeliveries() async {
    final data = await supabase
        .from('orders')
        .select()
        .eq('rider_id', widget.riderId)
        .order('id', ascending: false);

    if (!mounted) return;

    setState(() {
      deliveries = data;
    });
  }

  Future<void> openMap(dynamic order) async {
    final lat = order['delivery_latitude'];
    final lng = order['delivery_longitude'];

    if (lat == null || lng == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer location is not available'),
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

  Future<void> updateStatus(
      int orderId,
      String status,
      ) async {
    await supabase
        .from('orders')
        .update({
      'status': status,
    })
        .eq('id', orderId);

    await loadDeliveries();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order updated to $status'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Deliveries'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green,
            child: Text(
              'Rider: ${widget.riderName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: deliveries.isEmpty
                ? const Center(
              child: Text(
                'No assigned deliveries',
              ),
            )
                : ListView.builder(
              itemCount: deliveries.length,
              itemBuilder: (context, index) {
                final order = deliveries[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order['id']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Customer: ${order['customer_name'] ?? 'N/A'}',
                        ),

                        Text(
                          'Phone: ${order['customer_phone'] ?? 'N/A'}',
                        ),

                        Text(
                          'Address: ${order['delivery_address'] ?? 'N/A'}',
                        ),

                        Text(
                          'Status: ${order['status'] ?? 'Pending'}',
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                openMap(order);
                              },
                              icon: const Icon(
                                Icons.location_on,
                              ),
                              label: const Text(
                                'Navigate',
                              ),
                            ),

                            ElevatedButton(
                              onPressed: () {
                                updateStatus(
                                  order['id'],
                                  'Picked Up',
                                );
                              },
                              child: const Text(
                                'Picked Up',
                              ),
                            ),

                            ElevatedButton(
                              onPressed: () {
                                updateStatus(
                                  order['id'],
                                  'On The Way',
                                );
                              },
                              child: const Text(
                                'On The Way',
                              ),
                            ),

                            ElevatedButton(
                              onPressed: () {
                                updateStatus(
                                  order['id'],
                                  'Delivered',
                                );
                              },
                              child: const Text(
                                'Delivered',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}