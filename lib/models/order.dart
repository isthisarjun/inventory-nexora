class Order {
  final String id;
  final String customerId;
  final String customerName;
  final List<String> items;
  final List<String> materials;
  final double materialsCost;
  final double labourCost;
  final double totalCost;
  final double advanceAmount; // Add advance payment field
  final DateTime orderDate;
  final DateTime dueDate;
  final String status;
  final String paymentStatus; // 'paid' or 'pay_at_delivery'
  final double vatAmount; // VAT amount applied
  final bool includeVat; // Whether VAT was included

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.materials,
    required this.materialsCost,
    required this.labourCost,
    required this.totalCost,
    this.advanceAmount = 0.0, // Default to 0 (optional)
    required this.orderDate,
    required this.dueDate,
    required this.status,
    this.paymentStatus = 'pay_at_delivery',
    this.vatAmount = 0.0, // Default to 0
    this.includeVat = false, // Default to false
  });

  // Convert to map for Excel export
  Map<String, dynamic> toMap() {
    // Calculate total number of outfits from items like "Shirt (2), Pants (3)"
    int totalOutfits = 0;
    for (String item in items) {
      final match = RegExp(r'\((\d+)\)').firstMatch(item);
      if (match != null) {
        totalOutfits += int.parse(match.group(1)!);
      } else {
        totalOutfits += 1; // Default to 1 if no quantity specified
      }
    }
    
    return {
      'id': id,
      'customerName': customerName,
      'customerContact': '', // Not available in current Order model
      'customerAddress': '', // Not available in current Order model
      'outfitType': items.join(', '), // Already in format "shirt (2), pant (3)"
      'numberOfOutfits': totalOutfits,
      'material': materials.join(', '),
      'measurements': '', // Not available in current Order model
      'specialInstructions': '',
      'materialsCost': materialsCost,
      'labourCost': labourCost,
      'totalAmount': totalCost,
      'advanceAmount': advanceAmount, // Use actual advance amount
      'status': status,
      'paymentStatus': paymentStatus,
      'priority': 'medium',
      'orderDate': orderDate,
      'dueDate': dueDate,
      'notes': '',
      'vatAmount': vatAmount,
      'includeVat': includeVat,
    };
  }

  // Create from map (for loading from Excel)
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      items: (map['items'] as String?)?.split(', ') ?? [],
      materials: (map['materials'] as String?)?.split(', ') ?? [],
      materialsCost: (map['materialsCost'] as num?)?.toDouble() ?? 0.0,
      labourCost: (map['labourCost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (map['advanceAmount'] as num?)?.toDouble() ?? 0.0,
      orderDate: DateTime.tryParse(map['orderDate'] ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'Pending',
      paymentStatus: map['paymentStatus'] ?? 'pay_at_delivery',
      vatAmount: (map['vatAmount'] as num?)?.toDouble() ?? 0.0,
      includeVat: map['includeVat'] == true || map['includeVat'] == 'true',
    );
  }

  // Create a copy with modified fields
  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<String>? items,
    List<String>? materials,
    double? materialsCost,
    double? labourCost,
    double? totalCost,
    double? advanceAmount,
    DateTime? orderDate,
    DateTime? dueDate,
    String? status,
    String? paymentStatus,
    double? vatAmount,
    bool? includeVat,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      materials: materials ?? this.materials,
      materialsCost: materialsCost ?? this.materialsCost,
      labourCost: labourCost ?? this.labourCost,
      totalCost: totalCost ?? this.totalCost,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      orderDate: orderDate ?? this.orderDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      vatAmount: vatAmount ?? this.vatAmount,
      includeVat: includeVat ?? this.includeVat,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, customerName: $customerName, items: $items, materialsCost: $materialsCost, labourCost: $labourCost, totalCost: $totalCost, status: $status, paymentStatus: $paymentStatus, vatAmount: $vatAmount, includeVat: $includeVat)';
  }
}