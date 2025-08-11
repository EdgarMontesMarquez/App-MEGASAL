import 'payment.dart';

class Client {
  final int id;
  final String invoiceNumber; // NUEVO CAMPO
  String name;
  DateTime purchaseDate;
  double debt;
  String purchaseDescription; // NUEVO CAMPO
  List<Payment> payments;

  Client({
    required this.id,
    required this.invoiceNumber, // NUEVO CAMPO
    required this.name,
    required this.purchaseDate,
    required this.debt,
    required this.purchaseDescription, // NUEVO CAMPO
    this.payments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber, // NUEVO CAMPO
      'name': name,
      'purchaseDate': purchaseDate.toIso8601String(),
      'debt': debt,
      'purchaseDescription': purchaseDescription, // NUEVO CAMPO
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      invoiceNumber: json['invoiceNumber'], // NUEVO CAMPO
      name: json['name'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      debt: json['debt'].toDouble(),
      purchaseDescription: json['purchaseDescription'] ?? '', // NUEVO CAMPO
      payments: (json['payments'] as List?)
          ?.map((p) => Payment.fromJson(p))
          .toList() ?? [],
    );
  }

  // Método para calcular el total de abonos
  double get totalPayments => payments.fold(0.0, (sum, payment) => sum + payment.amount);
  
  // Método para verificar si tiene deuda pendiente
  bool get hasDebt => debt > 0;
}