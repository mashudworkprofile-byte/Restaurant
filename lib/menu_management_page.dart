import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() =>
      _MenuManagementPageState();
}

class _MenuManagementPageState
    extends State<MenuManagementPage> {

  List<dynamic> menuItems = [];

  @override
  void initState() {
    super.initState();
    loadMenuItems();
  }

  Future<void> loadMenuItems() async {
    final data = await supabase
        .from('menu_items')
        .select()
        .order('id');

    setState(() {
      menuItems = data;
    });
  }
  Future<void> showEditFoodDialog(
      dynamic item,
      ) async {

    final nameController =
    TextEditingController(
      text: item['name'],
    );

    final descriptionController =
    TextEditingController(
      text: item['description'],
    );

    final priceController =
    TextEditingController(
      text: item['price'].toString(),
    );

    final imageController =
    TextEditingController(
      text: item['image_url'],
    );

    String selectedCategory =
    item['category'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              title: const Text(
                'Edit Food',
              ),
              content:
              SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [

                    TextField(
                      controller:
                      nameController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Food Name',
                      ),
                    ),

                    TextField(
                      controller:
                      descriptionController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Description',
                      ),
                    ),

                    TextField(
                      controller:
                      priceController,
                      keyboardType:
                      TextInputType.number,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Price',
                      ),
                    ),

                    TextField(
                      controller:
                      imageController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Image URL',
                      ),
                    ),

                    DropdownButton<String>(
                      value:
                      selectedCategory,
                      isExpanded: true,
                      items: const [

                        DropdownMenuItem(
                          value: 'Rice',
                          child:
                          Text('Rice'),
                        ),

                        DropdownMenuItem(
                          value: 'Drink',
                          child:
                          Text('Drink'),
                        ),

                        DropdownMenuItem(
                          value: 'Soup',
                          child:
                          Text('Soup'),
                        ),

                        DropdownMenuItem(
                          value: 'Protein',
                          child: Text(
                              'Protein'),
                        ),

                        DropdownMenuItem(
                          value: 'Dessert',
                          child: Text(
                              'Dessert'),
                        ),

                        DropdownMenuItem(
                          value:
                          'Swallow',
                          child: Text(
                              'Swallow'),
                        ),

                        DropdownMenuItem(
                          value:
                          'Fast Food',
                          child: Text(
                              'Fast Food'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory =
                          value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(
                        context);
                  },
                  child:
                  const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {

                    await supabase
                        .from(
                        'menu_items')
                        .update({
                      'name':
                      nameController
                          .text,
                      'description':
                      descriptionController
                          .text,
                      'price':
                      double.parse(
                        priceController
                            .text,
                      ),
                      'category':
                      selectedCategory,
                      'image_url':
                      imageController
                          .text,
                    })
                        .eq(
                      'id',
                      item['id'],
                    );

                    Navigator.pop(
                        context);

                    loadMenuItems();
                  },
                  child:
                  const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> deleteFood(int id) async {
    await supabase
        .from('menu_items')
        .delete()
        .eq('id', id);

    loadMenuItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Menu',
        ),
      ),
      body: ListView.builder(
        itemCount: menuItems.length,
        itemBuilder: (context, index) {

          final item = menuItems[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  item['image_url'] ?? '',
                ),
              ),
              title: Text(
                item['name'],
              ),
              subtitle: Text(
                '₦${item['price']}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      showEditFoodDialog(item);
                    },
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () async {

                      final confirm =
                      await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text(
                              'Delete Food',
                            ),
                            content: Text(
                              'Are you sure you want to delete ${item['name']}?',
                            ),
                            actions: [

                              TextButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    false,
                                  );
                                },
                                child: const Text(
                                  'Cancel',
                                ),
                              ),

                              ElevatedButton(
                                style:
                                ElevatedButton.styleFrom(
                                  backgroundColor:
                                  Colors.red,
                                ),
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    true,
                                  );
                                },
                                child: const Text(
                                  'Delete',
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        deleteFood(item['id']);
                      }
                    },
                  ),                ],
              ),
            ),
          );
        },
      ),
    );
  }
}