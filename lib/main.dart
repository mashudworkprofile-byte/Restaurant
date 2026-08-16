import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_tracking_page.dart';
import 'admin_page.dart';
import 'super_admin_page.dart';
import 'cart_page.dart';
import 'rider_page.dart';
import 'rider_login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sozoexrbjkbgqanuaekj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNvem9leHJiamtiZ3FhbnVhZWtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1NDIyNDEsImV4cCI6MjA5NTExODI0MX0.ejGILsEivhyi9TAp5sktTjmKsp4e6_FbqZwW6lNBztQ',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bliss Bridge Restaurant',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MenuPage(selectedTable: 1),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.restaurant, size: 100, color: Colors.white),
            SizedBox(height: 15),
            Text(
              'Bliss Bridge Restaurant',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Welcome! Discover delicious meals and enjoy great food anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuPage extends StatefulWidget {
  final int selectedTable;

  const MenuPage({super.key, required this.selectedTable});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late int selectedTable;

  List<dynamic> menuItems = [];
  List<dynamic> cartItems = [];
  bool isLoading = true;

  final List<String> categories = const [
    'Rice',
    'Drink',
    'Soup',
    'Protein',
    'Dessert',
    'Swallow',
    'Fast Food',
  ];

  String selectedCategory = 'Rice';
  String searchQuery = '';

  final GlobalKey categorySectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    selectedTable = widget.selectedTable;
    fetchMenuItems();
  }

  Future<void> fetchMenuItems() async {
    try {
      final response = await supabase.from('menu_items').select();

      setState(() {
        menuItems = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void addToCart(dynamic item) {
    setState(() => cartItems.add(item));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${item['name']} added to cart')));
  }

  double getTotalPrice() {
    double total = 0;
    for (var item in cartItems) {
      total += (item['price'] as num).toDouble();
    }
    return total;
  }

  void increaseQuantity(dynamic item) {
    setState(() {
      cartItems.add(item);
    });
  }

  void decreaseQuantity(dynamic item) {
    setState(() {
      cartItems.remove(item);
    });
  }

  Future<void> placeOrder(Map<String, dynamic> details) async {
    try {
      final order = await supabase
          .from('orders')
          .insert({
        'table_number': selectedTable,
        'status': 'Pending',
        'total_amount': getTotalPrice() + (details['delivery_fee'] ?? 0),

        'customer_name': details['customer_name'],
        'customer_phone': details['customer_phone'],
        'order_type': details['order_type'],
        'delivery_address': details['delivery_address'],
        'delivery_note': details['delivery_note'],
        'delivery_fee': details['delivery_fee'],
        'delivery_latitude': details['delivery_latitude'],
        'delivery_longitude': details['delivery_longitude'],
      })
          .select()
          .single();

      final orderId = order['id'];

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingPage(orderId: orderId)),
      );

      for (var item in cartItems) {
        await supabase.from('order_items').insert({
          'order_id': orderId,
          'menu_item_id': item['id'],
          'quantity': 1,
          'price': item['price'],
        });
      }

      setState(() => cartItems.clear());
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> showAdminLogin() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Admin Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
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
                final user = await supabase
                    .from('admin_users')
                    .select()
                    .eq('username', usernameController.text)
                    .eq('password', passwordController.text)
                    .maybeSingle();

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid username or password'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                if (user['role'] == 'superadmin') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SuperAdminPage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPage()),
                  );
                }
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = menuItems.where((item) {
      final category = item['category']?.toString().trim();
      final name = item['name'].toString().toLowerCase();
      final matchesCategory = category == selectedCategory;
      final matchesSearch = name.contains(searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(
              Icons.restaurant,
              size: 40,
              color: Colors.green,
            ),
            SizedBox(width: 10),
            Text(
              'Bliss Bridge Restaurant',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Home'),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Menu'),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Place an order first to track it.',
                  ),
                ),
              );
            },
            child: const Text('Track Order'),
          ),
          IconButton(
            icon: Badge(
              label: Text('${cartItems.length}'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartPage(
                    cartItems: cartItems,
                    increaseQuantity: increaseQuantity,
                    decreaseQuantity: decreaseQuantity,
                    totalPrice: getTotalPrice(),
                    onCheckout: (details) => placeOrder(details),
                  ),
                ),
              ).then((_) {
                setState(() {});
              });
            },
          ),

          IconButton(
            icon: const Icon(Icons.delivery_dining),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RiderLoginPage(),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: showAdminLogin,
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 45,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F9D58), Color(0xFF00695C)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(

                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to Bliss Bridge',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Order fresh, tasty meals directly from your table.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 20),

                              ElevatedButton.icon(
                                onPressed: () {
                                  Scrollable.ensureVisible(
                                    categorySectionKey.currentContext!,
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                icon: Icon(Icons.restaurant_menu),
                                label: Text('Order Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 600,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search food...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<int>(
                        value: selectedTable,
                        decoration: const InputDecoration(
                          labelText: 'Select Table Number',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(
                          20,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('Table ${i + 1}'),
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            selectedTable = v!;
                          });
                        },
                      ),
                    ),
                  ),
                  Padding(
                    key: categorySectionKey,
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 16,
                      right: 16,
                      bottom: 5,
                    ),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Explore Categories',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = cat == selectedCategory;

                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedCategory = cat);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected ? Colors.green : Colors.grey.shade300,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 16,
                      right: 16,
                      bottom: 5,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$selectedCategory Menu',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  filteredItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(30),
                          child: Text('No items in this category'),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(15),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width > 1200
                                    ? 4
                                    : MediaQuery.of(context).size.width > 800
                                    ? 3
                                    : MediaQuery.of(context).size.width > 500
                                    ? 2
                                    : 1,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio:
                                    MediaQuery.of(context).size.width > 800
                                    ? 0.85
                                    : 0.75,
                              ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];

                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedScale(
                                scale: 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  color: Colors.white,
                                  margin: const EdgeInsets.all(12),
                                  elevation: 12,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          Image.network(
                                            item['image_url'] ?? '',
                                            width: double.infinity,
                                            height: 180,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                height: 180,
                                                color: Colors.grey,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 50,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                          Positioned(
                                            top: 10,
                                            left: 10,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'POPULAR',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),

                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.favorite_border,
                                                color: Colors.red,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              item['description'] ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '₦${item['price']}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed: () => addToCart(item),
                                                  icon: const Icon(Icons.shopping_cart),
                                                  label: const Text('Add'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    color: Colors.green,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '© 2026 Bliss Bridge Restaurant',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Fresh • Delicious • Fast',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: null,
    );
  }
}
