class Payment {
  final int id;
  final double amount;
  final DateTime date;

  Payment({
    required this.id,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
    );
  }
}