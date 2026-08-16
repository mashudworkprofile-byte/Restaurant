import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() =>
      _AdminManagementPageState();
}

class _AdminManagementPageState
    extends State<AdminManagementPage> {

  List<dynamic> admins = [];

  @override
  void initState() {
    super.initState();
    loadAdmins();
  }

  Future<void> loadAdmins() async {
    try {
      final data = await supabase
          .from('admin_users')
          .select();

      print('================================');
      print('ADMIN USERS DATA');
      print(data);
      print('TOTAL ADMINS: ${data.length}');
      print('================================');

      setState(() {
        admins = data;
      });
    } catch (e) {
      print('ADMIN ERROR: $e');
    }
  }

  Future<void> deleteAdmin(int id) async {
    await supabase
        .from('admin_users')
        .delete()
        .eq('id', id);

    loadAdmins();
  }

  Future<void> showAddAdminDialog() async {
    final usernameController =
    TextEditingController();

    final passwordController =
    TextEditingController();

    String role = 'admin';

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
                'Add Admin',
              ),
              content: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                    usernameController,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Username',
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  TextField(
                    controller:
                    passwordController,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Password',
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  DropdownButton<String>(
                    value: role,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text(
                          'Admin',
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                        'superadmin',
                        child: Text(
                          'Super Admin',
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        role = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {
                    await supabase
                        .from(
                        'admin_users')
                        .insert({
                      'username':
                      usernameController
                          .text,
                      'password':
                      passwordController
                          .text,
                      'role': role,
                    });

                    Navigator.pop(
                      context,
                    );

                    loadAdmins();
                  },
                  child: const Text(
                    'Save',
                  ),
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
          'Manage Admins',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
            ),
            onPressed:
            showAddAdminDialog,
          ),
        ],
      ),

      body: ListView.builder(
        itemCount: admins.length,
        itemBuilder: (
            context,
            index,
            ) {
          final admin =
          admins[index];

          return Card(
            margin:
            const EdgeInsets.all(
              10,
            ),
            child: ListTile(
              leading: const Icon(
                Icons.person,
              ),

              title: Text(
                admin['username'],
              ),

              subtitle: Text(
                admin['role'],
              ),

              trailing: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () async {
                  final confirm =
                  await showDialog<
                      bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title:
                        const Text(
                          'Delete Admin',
                        ),
                        content: Text(
                          'Are you sure you want to delete ${admin['username']}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed:
                                () {
                              Navigator.pop(
                                context,
                                false,
                              );
                            },
                            child:
                            const Text(
                              'Cancel',
                            ),
                          ),

                          ElevatedButton(
                            style:
                            ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              Colors.red,
                            ),
                            onPressed:
                                () {
                              Navigator.pop(
                                context,
                                true,
                              );
                            },
                            child:
                            const Text(
                              'Delete',
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm ==
                      true) {
                    deleteAdmin(
                      admin['id'],
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
} 