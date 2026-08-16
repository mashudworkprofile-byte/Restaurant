import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final supabase = Supabase.instance.client;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  Future<void> showAddFoodDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();

    String selectedCategory = 'Rice';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Food Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Food Name'),
                    ),

                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),

                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),

                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                    ),

                    const SizedBox(height: 10),

                    DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Rice', child: Text('Rice')),
                        DropdownMenuItem(value: 'Drink', child: Text('Drink')),
                        DropdownMenuItem(value: 'Soup', child: Text('Soup')),
                        DropdownMenuItem(
                          value: 'Protein',
                          child: Text('Protein'),
                        ),
                        DropdownMenuItem(
                          value: 'Dessert',
                          child: Text('Dessert'),
                        ),
                        DropdownMenuItem(
                          value: 'Swallow',
                          child: Text('Swallow'),
                        ),
                        DropdownMenuItem(
                          value: 'Fast Food',
                          child: Text('Fast Food'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await supabase.from('menu_items').insert({
                      'name': nameController.text,
                      'description': descriptionController.text,
                      'price': double.parse(priceController.text),
                      'category': selectedCategory,
                      'image_url': imageController.text,
                    });

                    loadOrders();

                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<dynamic> orders = [];
  List<dynamic> riders = [];

  @override
  void initState() {
    super.initState();

    loadOrders();
    loadRiders();

    supabase.from('orders').stream(primaryKey: ['id']).listen((_) {
      loadOrders();
    });
  }

  Future<void> loadOrders() async {
    final data = await supabase
        .from('orders')
        .select('''
        *,
        order_items (
          quantity,
          price,
          menu_items (
            name
          )
        )
      ''')
        .order('id', ascending: false);

    setState(() {
      orders = data;
    });
  }

  Future<void> loadRiders() async {
    try {
      final data = await supabase
          .from('delivery_riders')
          .select()
          .order('name', ascending: true);

      print('RIDERS DATA: $data');

      setState(() {
        riders = data;
      });
    } catch (e) {
      print('RIDERS ERROR: $e');
    }
  }

  Future<void> openMap(dynamic order) async {
    final lat = order['delivery_latitude'];
    final lng = order['delivery_longitude'];

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No delivery location saved.')),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> callCustomer(dynamic order) async {
    final phone = order['customer_phone'];

    if (phone == null || phone.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer phone number not available.')),
      );
      return;
    }

    final url = Uri.parse('tel:$phone');

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> updateStatus(int orderId, String status) async {
    await supabase.from('orders').update({'status': status}).eq('id', orderId);
  }

  Future<void> assignRider(dynamic order, dynamic rider) async {
    await supabase
        .from('orders')
        .update({
          'rider_id': rider['id'],
          'rider_name': rider['name'],
          'rider_phone': rider['phone'],
          'status': 'Rider Assigned',
        })
        .eq('id', order['id']);

    await loadOrders();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${rider['name']} assigned to Order #${order['id']}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Admin'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: showAddFoodDialog),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order['id']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text('Table ${order['table_number']}'),

                        Text('₦${order['total_amount']}'),

                        Text('Status: ${order['status']}'),

                        if (order['rider_name'] != null)
                          Text('Rider: ${order['rider_name']}'),

                        if (order['rider_phone'] != null)
                          Text('Rider Phone: ${order['rider_phone']}'),

                        if (order['order_type'] == 'delivery')
                          Text(
                            'Address: ${order['delivery_address'] ?? 'No address'}',
                          ),

                        const SizedBox(height: 10),

                        if (order['order_type'] == 'delivery')
                          riders.isEmpty
                              ? const Text(
                                  'No riders found',
                                  style: TextStyle(color: Colors.red),
                                )
                              : DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: 'Assign Rider',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: riders.map<DropdownMenuItem<int>>((
                                    rider,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: rider['id'],
                                      child: Text(
                                        '${rider['name']} - ${rider['phone']}',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (riderId) {
                                    if (riderId != null) {
                                      final selectedRider = riders.firstWhere(
                                        (rider) => rider['id'] == riderId,
                                      );

                                      assignRider(order, selectedRider);
                                    }
                                  },
                                ),

                        const SizedBox(height: 10),

                        if (order['order_type'] == 'delivery')
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    openMap(order);
                                  },
                                  icon: const Icon(Icons.location_on),
                                  label: const Text('Navigate'),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    callCustomer(order);
                                  },
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Call'),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 10),

                        const Text(
                          'Items Ordered:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        ...(order['order_items'] as List).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${item['menu_items']['name']} x${item['quantity']}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                updateStatus(order['id'], 'Picked Up');
                              },
                              child: const Text('Picked Up'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                updateStatus(order['id'], 'On The Way');
                              },
                              child: const Text('On The Way'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                updateStatus(order['id'], 'Delivered');
                              },
                              child: const Text('Delivered'),
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
