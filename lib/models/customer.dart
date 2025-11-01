class Customer {
  String id;
  String name;
  String phoneNumber;
  String? address;
  String? email;
  
  Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.address,
    this.email,
  });
  
  // Convert from Map (for JSON/Excel import)
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phoneNumber: map['phone']?.toString() ?? map['phoneNumber']?.toString() ?? '',
      address: map['address']?.toString(),
      email: map['email']?.toString(),
    );
  }
  
  // Convert to Map (for JSON/Excel export)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phoneNumber,
      'phoneNumber': phoneNumber, // Keep both for compatibility
      'address': address,
      'email': email,
    };
  }
}