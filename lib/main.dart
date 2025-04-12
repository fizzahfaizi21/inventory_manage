import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Add these Firebase options for manual configuration
const firebaseOptions = FirebaseOptions(
  apiKey: "YOUR_API_KEY", // Replace with your actual Firebase project values
  appId: "YOUR_APP_ID",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  projectId: "YOUR_PROJECT_ID",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: firebaseOptions,
  ); // Use the manual options
  runApp(InventoryApp());
}

// Inventory Item Model
class InventoryItem {
  String? id;
  String name;
  int quantity;
  double price;
  String category;

  InventoryItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'category': category,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map, String documentId) {
    return InventoryItem(
      id: documentId,
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price:
          (map['price'] is int)
              ? (map['price'] as int).toDouble()
              : map['price'] ?? 0.0,
      category: map['category'] ?? '',
    );
  }
}

// Firestore Service
class FirestoreService {
  final CollectionReference _itemsCollection = FirebaseFirestore.instance
      .collection('items');

  // Create: Add a new item to Firestore
  Future<DocumentReference> addItem(InventoryItem item) {
    return _itemsCollection.add(item.toMap());
  }

  // Read: Get a stream of all items
  Stream<List<InventoryItem>> getItems() {
    return _itemsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return InventoryItem.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Update: Update an existing item
  Future<void> updateItem(InventoryItem item) {
    return _itemsCollection.doc(item.id).update(item.toMap());
  }

  // Delete: Remove an item
  Future<void> deleteItem(String itemId) {
    return _itemsCollection.doc(itemId).delete();
  }
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: InventoryHomePage(title: 'Inventory Management'),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  InventoryHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool _isLoading = false;

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Inventory Items',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<InventoryItem>>(
                stream: _firestoreService.getItems(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No items in inventory'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final item = snapshot.data![index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            'Quantity: ${item.quantity} | Price: \$${item.price.toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Category: ${item.category}'),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  try {
                                    await _firestoreService.deleteItem(
                                      item.id!,
                                    );
                                    _showSnackBar('Item deleted successfully');
                                  } catch (e) {
                                    _showSnackBar('Error deleting item: $e');
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            // Will implement editing in next step
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddItemDialog(context);
          },
          tooltip: 'Add Item',
          child:
              _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Item'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Item Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter item name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: quantityController,
                    decoration: InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: categoryController,
                    decoration: InputDecoration(labelText: 'Category'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter category';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Validate form
                if (formKey.currentState!.validate()) {
                  // Create a new item object
                  final newItem = InventoryItem(
                    name: nameController.text,
                    quantity: int.parse(quantityController.text),
                    price: double.parse(priceController.text),
                    category: categoryController.text,
                  );

                  Navigator.of(context).pop();

                  // Show loading indicator
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // Add item to Firestore
                    await _firestoreService.addItem(newItem);
                    _showSnackBar('Item added successfully');
                  } catch (e) {
                    _showSnackBar('Error adding item: $e');
                  } finally {
                    // Hide loading indicator
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
