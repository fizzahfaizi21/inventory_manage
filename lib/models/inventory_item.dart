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
      price: map['price'] ?? 0.0,
      category: map['category'] ?? '',
    );
  }
}
