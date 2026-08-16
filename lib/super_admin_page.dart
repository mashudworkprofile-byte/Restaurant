import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_management_page.dart';
import 'admin_management_page.dart';
import 'sales_report_page.dart';
import 'all_orders_page.dart';
final supabase = Supabase.instance.client;

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {

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
                      decoration: const InputDecoration(
                        labelText: 'Food Name',
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: const [

                        DropdownMenuItem(
                          value: 'Rice',
                          child: Text('Rice'),
                        ),

                        DropdownMenuItem(
                          value: 'Drink',
                          child: Text('Drink'),
                        ),

                        DropdownMenuItem(
                          value: 'Soup',
                          child: Text('Soup'),
                        ),

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

                    await supabase
                        .from('menu_items')
                        .insert({
                      'name': nameController.text,
                      'description': descriptionController.text,
                      'price': double.parse(
                        priceController.text,
                      ),
                      'category': selectedCategory,
                      'image_url': imageController.text,
                    });

                    if (!mounted) return;

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Food added successfully',
                        ),
                      ),
                    );
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Super Admin Dashboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: showAddFoodDialog,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.restaurant_menu,
                ),
                title: const Text(
                  'Manage Menu',
                ),
                subtitle: const Text(
                  'Add, Edit and Delete Foods',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MenuManagementPage(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.people,
                ),
                title: const Text(
                  'Manage Admins',
                ),
                subtitle: const Text(
                  'Create and Delete Admin Users',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const AdminManagementPage(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Sales Reports'),
                subtitle: const Text(
                  'View Daily and Monthly Sales',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const SalesReportPage(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.receipt_long,
                ),
                title: const Text(
                  'All Orders',
                ),
                subtitle: const Text(
                  'Monitor Restaurant Orders',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const AllOrdersPage(),
                    ),
                  );
                },

              ),
            ),

          ],
        ),
      ),
    );
  }
}