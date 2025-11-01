// Create a singleton service to manage orders across screens
class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  // List of all orders
  List<Map<String, dynamic>> _orders = [];

  // Get all orders
  List<Map<String, dynamic>> get orders => _orders;

  // Initialize with mock data
  void initWithMockData() {
    if (_orders.isEmpty) {
      _orders = [
        {
          'id': 'ORD-001',
          'customerId': '1',
          'customerName': 'John Doe',
          'customerContact': '+973 1234 5678',
          'customerAddress': '123 Main St, Manama',
          'outfitType': 'Shirt',
          'numberOfOutfits': 2,
          'material': 'Cotton',
          'orderDate': DateTime.now().subtract(const Duration(days: 5)),
          'dueDate': DateTime.now().add(const Duration(days: 3)),
          'status': 'pending',
          'totalAmount': 150.00,
          'advanceAmount': 75.00,
          'priority': 'medium',
          'notes': 'Customer prefers slim fit. Needs the order ASAP.',
          'paymentStatus': 'pay_at_delivery',
        },
        {
          'id': 'ORD-002',
          'customerId': '2',
          'customerName': 'Jane Smith',
          'customerContact': '+973 9876 5432',
          'customerAddress': '456 Oak Ave, Riffa',
          'outfitType': 'Wedding Suit',
          'numberOfOutfits': 1,
          'material': 'Silk',
          'orderDate': DateTime.now().subtract(const Duration(days: 10)),
          'dueDate': DateTime.now().add(const Duration(days: 1)),
          'status': 'in_progress',
          'totalAmount': 350.00,
          'advanceAmount': 200.00,
          'priority': 'high',
          'notes': 'Wedding is on the weekend. Must be perfect!',
          'paymentStatus': 'paid',
        },
        {
          'id': 'ORD-003',
          'customerId': '3',
          'customerName': 'Robert Johnson',
          'customerContact': '+973 5555 1234',
          'customerAddress': '789 Pine St, Muharraq',
          'outfitType': 'Casual Shirt',
          'numberOfOutfits': 3,
          'material': 'Linen',
          'orderDate': DateTime.now().subtract(const Duration(days: 3)),
          'dueDate': DateTime.now().add(const Duration(days: 7)),
          'status': 'pending',
          'totalAmount': 95.00,
          'advanceAmount': 0.00,
          'priority': 'low',
          'notes': 'Will pick up when ready, no rush.',
          'paymentStatus': 'pay_at_delivery',
        },
      ];
    }
  }

  // Add a new order
  void addOrder(Map<String, dynamic> order) {
    // Ensure the order has a unique ID
    if (!order.containsKey('id')) {
      final newId = 'ORD-${(_orders.length + 1).toString().padLeft(3, '0')}';
      order['id'] = newId;
    }
    
    // Set default status to 'pending' if not specified
    if (!order.containsKey('status')) {
      order['status'] = 'pending';
    }
    
    // Add the order to the list
    _orders.add(order);
  }

  // Delete order by ID
  bool deleteOrder(String orderId) {
    final index = _orders.indexWhere((order) => order['id'] == orderId);
    if (index != -1) {
      _orders.removeAt(index);
      return true;
    }
    return false;
  }

  // Update order by ID
  bool updateOrder(String orderId, Map<String, dynamic> updatedOrder) {
    final index = _orders.indexWhere((order) => order['id'] == orderId);
    if (index != -1) {
      _orders[index] = updatedOrder;
      return true;
    }
    return false;
  }

  // Clear all orders
  void clearOrders() {
    _orders.clear();
  }

  // Set orders
  void setOrders(List<Map<String, dynamic>> orders) {
    _orders = orders;
  }
}
