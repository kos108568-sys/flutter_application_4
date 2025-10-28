class TimeSlot {
  final int? id;
  final int orderNumber;
  final String startTime;
  final String endTime;
  final String? description;

  TimeSlot({
    this.id,
    required this.orderNumber,
    required this.startTime,
    required this.endTime,
    this.description,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'order_number': orderNumber,
        'start_time': startTime,
        'end_time': endTime,
        'description': description,
      };

  factory TimeSlot.fromMap(Map<String, dynamic> map) => TimeSlot(
        id: map['id'] as int?,
        orderNumber: map['order_number'] as int,
        startTime: map['start_time'] as String,
        endTime: map['end_time'] as String,
        description: map['description'] as String?,
      );

  Map<String, dynamic> toSupabaseMap() => {
        if (id != null) 'id': id,
        'order_number': orderNumber,
        'start_time': startTime,
        'end_time': endTime,
        'description': description,
      };
}
