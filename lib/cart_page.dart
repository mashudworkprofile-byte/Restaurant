import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CartPage extends StatefulWidget {
  final List<dynamic> cartItems;
  final Function(dynamic) increaseQuantity;
  final Function(dynamic) decreaseQuantity;
  final double totalPrice;
  final Function(Map<String, dynamic>) onCheckout;

  const CartPage({
    super.key,
    required this.cartItems,
    required this.increaseQuantity,
    required this.decreaseQuantity,
    required this.totalPrice,
    required this.onCheckout,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final noteController = TextEditingController();

  double? deliveryLatitude;
  double? deliveryLongitude;
  bool isGettingLocation = false;

  String orderType = 'pickup';
  double deliveryFee = 0;

  Map<String, Map<String, dynamic>> getCartSummary() {
    final Map<String, Map<String, dynamic>> summary = {};

    for (var item in widget.cartItems) {
      final name = item['name'];

      if (summary.containsKey(name)) {
        summary[name]!['quantity']++;
      } else {
        summary[name] = {
          'item': item,
          'quantity': 1,
        };
      }
    }

    return summary;
  }

  Future<void> getCurrentLocation() async {
    setState(() {
      isGettingLocation = true;
    });

    try {
      bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please turn on your location service.'),
          ),
        );

        setState(() {
          isGettingLocation = false;
        });

        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied.'),
          ),
        );

        setState(() {
          isGettingLocation = false;
        });

        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      deliveryLatitude = position.latitude;
      deliveryLongitude = position.longitude;


      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          addressController.text =
          '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';
        } else {
          addressController.text =
          'Lat: ${position.latitude}, Long: ${position.longitude}';
        }
      } catch (e) {
        addressController.text =
        'Lat: ${position.latitude}, Long: ${position.longitude}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location captured successfully.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location error: $e'),
        ),
      );
    }

    setState(() {
      isGettingLocation = false;
    });
  }

  void checkout() {
    final details = {
      'customer_name': nameController.text,
      'customer_phone': phoneController.text,
      'order_type': orderType,
      'delivery_address': addressController.text,
      'delivery_note': noteController.text,
      'delivery_fee': deliveryFee,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
    };

    widget.onCheckout(details);
  }

  @override
  Widget build(BuildContext context) {
    final summary = getCartSummary();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: summary.isEmpty
          ? const Center(
        child: Text('Cart is empty'),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            ...summary.entries.map((entry) {
              final item = entry.value['item'];
              final quantity = entry.value['quantity'];

              return ListTile(
                title: Text(item['name']),
                subtitle: Text('₦${item['price']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        widget.decreaseQuantity(item);
                        setState(() {});
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$quantity'),
                    IconButton(
                      onPressed: () {
                        widget.increaseQuantity(item);
                        setState(() {});
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              );
            }),

            const Divider(),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                    ),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: orderType,
                    decoration: const InputDecoration(
                      labelText: 'Order Type',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pickup',
                        child: Text('Pickup'),
                      ),
                      DropdownMenuItem(
                        value: 'delivery',
                        child: Text('Delivery'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        orderType = value!;

                        if (orderType == 'delivery') {
                          deliveryFee = 1000;
                        } else {
                          deliveryFee = 0;
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  if (orderType == 'delivery')
                    Column(
                      children: [
                        TextField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Address',
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isGettingLocation
                                ? null
                                : getCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: Text(
                              isGettingLocation
                                  ? 'Getting Location...'
                                  : 'Use My Current Location',
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (orderType == 'delivery')
                    const SizedBox(height: 10),

                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Note / Extra Information',
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Total: ₦${(widget.totalPrice + deliveryFee).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: checkout,
                      child: const Text('CHECKOUT'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}