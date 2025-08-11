import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../models/payment.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/app_constants.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;

  const ClientDetailScreen({Key? key, required this.client}) : super(key: key);

  @override
  _ClientDetailScreenState createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late Client client;
  final _paymentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    client = widget.client;
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _addPayment() async {
    if (_paymentController.text.isEmpty) {
      _showErrorMessage('Por favor ingresa un monto');
      return;
    }

    final amount = double.tryParse(_paymentController.text);
    if (amount == null || amount <= 0) {
      _showErrorMessage('Por favor ingresa un monto válido');
      return;
    }

    if (amount > client.debt) {
      _showErrorMessage('El abono no puede ser mayor a la deuda pendiente');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payment = Payment(
        id: DateTime.now().millisecondsSinceEpoch,
        amount: amount,
        date: DateTime.now(),
      );

      setState(() {
        client.payments = [...client.payments, payment];
        client.debt = (client.debt - amount).clamp(0.0, double.infinity);
      });

      await StorageService.updateClient(client);
      _paymentController.clear();
      _showSuccessMessage('Abono agregado exitosamente');
    } catch (e) {
      _showErrorMessage('Error al agregar abono: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateInvoice() async {
    setState(() => _isLoading = true);
    try {
      await PDFService.generateInvoice(client);
      _showSuccessMessage('Factura generada exitosamente');
    } catch (e) {
      _showErrorMessage('Error al generar factura: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.dangerRed,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Detalles del Cliente'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClientInfoCard(),
                  const SizedBox(height: 16),
                  _buildAddPaymentCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                  if (client.payments.isNotEmpty) _buildPaymentHistoryCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildClientInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Nombre', client.name),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha de compra',
              DateFormat('dd/MM/yyyy').format(client.purchaseDate),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.attach_money,
              'Deuda actual',
              AppConstants.currencyFormat.format(client.debt),
              valueColor: client.hasDebt ? AppConstants.dangerRed : AppConstants.successGreen,
            ),
            if (client.payments.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.payment,
                'Total abonos',
                AppConstants.currencyFormat.format(client.totalPayments),
                valueColor: AppConstants.successGreen,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 16)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPaymentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar Abono',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _paymentController,
              decoration: const InputDecoration(
                labelText: 'Monto del Abono',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: client.debt > 0 ? _addPayment : null,
                icon: const Icon(Icons.add),
                label: const Text('Agregar Abono'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: client.payments.isNotEmpty ? _generateInvoice : null,
            icon: const Icon(Icons.receipt),
            label: const Text('Generar Factura'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.warningOrange,
              foregroundColor: Colors.white,
              
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Pagos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...client.payments.reversed.map((payment) => ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: Text(AppConstants.currencyFormat.format(payment.amount)),
              subtitle: Text(DateFormat('dd/MM/yyyy - HH:mm').format(payment.date)),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
