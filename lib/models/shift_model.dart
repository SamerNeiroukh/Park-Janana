class ShiftModel {
  final String id;
  final String date;
  final String department;
  final String startTime;
  final String endTime;
  final int maxWorkers;
  final List<String> requestedWorkers;

  ShiftModel({
    required this.id,
    required this.date,
    required this.department,
    required this.startTime,
    required this.endTime,
    required this.maxWorkers,
    required this.requestedWorkers,
  });

  // Convert ShiftModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'department': department,
      'startTime': startTime,
      'endTime': endTime,
      'maxWorkers': maxWorkers,
      'requestedWorkers': requestedWorkers,
    };
  }

  // Convert Firestore document to ShiftModel
  factory ShiftModel.fromMap(String id, Map<String, dynamic> map) {
    return ShiftModel(
      id: id,
      date: map['date'] ?? '',
      department: map['department'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      maxWorkers: map['maxWorkers'] ?? 0,
      requestedWorkers: List<String>.from(map['requestedWorkers'] ?? []),
    );
  }
}
