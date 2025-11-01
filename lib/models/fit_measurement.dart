class FitMeasurement {
  final String orderId;
  final String customerId;
  final String customerName;
  final String itemType;
  final String itemName;
  final int fitIndex;
  final String fitId;
  final Map<String, String> measurements;
  final DateTime createdAt;

  FitMeasurement({
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.itemType,
    required this.itemName,
    required this.fitIndex,
    required this.fitId,
    required this.measurements,
    required this.createdAt,
  });

  // Convert to map for Excel export
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'itemType': itemType,
      'itemName': itemName,
      'fitIndex': fitIndex,
      'fitId': fitId,
      'measurements': measurements,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from map (for loading from Excel)
  factory FitMeasurement.fromMap(Map<String, dynamic> map) {
    return FitMeasurement(
      orderId: map['orderId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      itemType: map['itemType'] ?? '',
      itemName: map['itemName'] ?? '',
      fitIndex: map['fitIndex'] ?? 1,
      fitId: map['fitId'] ?? '',
      measurements: Map<String, String>.from(map['measurements'] ?? {}),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Create a copy with modified fields
  FitMeasurement copyWith({
    String? orderId,
    String? customerId,
    String? customerName,
    String? itemType,
    String? itemName,
    int? fitIndex,
    String? fitId,
    Map<String, String>? measurements,
    DateTime? createdAt,
  }) {
    return FitMeasurement(
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      itemType: itemType ?? this.itemType,
      itemName: itemName ?? this.itemName,
      fitIndex: fitIndex ?? this.fitIndex,
      fitId: fitId ?? this.fitId,
      measurements: measurements ?? this.measurements,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'FitMeasurement(orderId: $orderId, fitId: $fitId, itemName: $itemName, fitIndex: $fitIndex)';
  }

  /// Get a human-readable description of this fit
  String get description {
    return '$itemName #$fitIndex';
  }

  /// Get a summary of all measurements as a formatted string
  String get measurementsSummary {
    if (measurements.isEmpty) return 'No measurements';
    
    final entries = measurements.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => '${entry.key}: ${entry.value}"')
        .toList();
    
    return entries.join(', ');
  }
}
