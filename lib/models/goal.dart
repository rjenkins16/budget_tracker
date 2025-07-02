// models/goal.dart
class Goal {
  final String name;
  final double amount;
  final double buffer;
  final int importance;

  Goal({required this.name, required this.amount, required this.buffer, required this.importance});

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      name: json['name'],
      amount: json['amount'],
      buffer: json['buffer'],
      importance: json['importance'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'buffer': buffer,
    'importance': importance,
  };
}
