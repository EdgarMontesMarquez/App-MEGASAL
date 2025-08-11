import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../services/storage_service.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/app_constants.dart';


class AddEditClientScreen extends StatefulWidget {
  final Client? client;

  const AddEditClientScreen({Key? key, this.client}) : super(key: key);

  @override
  _AddEditClientScreenState createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _debtController = TextEditingController();
  final _purchaseDescriptionController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditing) {
      _nameController.text = widget.client!.name;
      _debtController.text = widget.client!.debt.toString();
      _selectedDate = widget.client!.purchaseDate;
      _purchaseDescriptionController.text = widget.client!.purchaseDescription;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _debtController.dispose();
    _purchaseDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      _showErrorMessage('Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final clients = await StorageService.getClients();
      
      if (_isEditing) {
        await _updateExistingClient(clients);
      } else {
        await _createNewClient(clients);
      }

      await StorageService.saveClients(clients);
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorMessage('Error al guardar cliente: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateExistingClient(List<Client> clients) async {
  final index = clients.indexWhere((c) => c.id == widget.client!.id);
  if (index != -1) {
    clients[index].name = _nameController.text.trim();
    clients[index].purchaseDate = _selectedDate!;
    clients[index].debt = double.parse(_debtController.text);
    clients[index].purchaseDescription = _purchaseDescriptionController.text.trim();
  }
}


  Future<void> _createNewClient(List<Client> clients) async {
  final random = Random();
  final invoiceNumber = (random.nextInt(9000000) + 1000000).toString(); // 7 dígitos
  final newClient = Client(
    id: DateTime.now().millisecondsSinceEpoch,
    invoiceNumber: invoiceNumber,
    name: _nameController.text.trim(),
    purchaseDate: _selectedDate!,
    debt: double.parse(_debtController.text),
    purchaseDescription: _purchaseDescriptionController.text.trim(),
    payments: [],
  );
  clients.add(newClient);
}

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.dangerRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Editar Cliente' : 'Agregar Cliente',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildPurchaseDescriptionField(),
                    const SizedBox(height: 16),
                    _buildDebtField(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nombre del Cliente',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor ingresa el nombre';
        }
        if (value.trim().length < 2) {
          return 'El nombre debe tener al menos 2 caracteres';
        }
        return null;
      },
    );
  }
  
 
  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha de Compra',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _selectedDate == null 
              ? 'Seleccionar fecha' 
              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
          style: TextStyle(
            color: _selectedDate == null ? Colors.grey[600] : null,
          ),
        ),
      ),
    );
  }
 Widget _buildPurchaseDescriptionField() {
  return TextFormField(
    controller: _purchaseDescriptionController,
    decoration: const InputDecoration(
      labelText: '¿Qué compró?',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.shopping_cart),
    ),
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Por favor describe lo que compró';
      }
      return null;
    },
  );
}
  Widget _buildDebtField() {
    return TextFormField(
      controller: _debtController,
      decoration: const InputDecoration(
        labelText: 'Deuda',
        border: OutlineInputBorder(),
        prefixText: '\$ ',
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa la deuda';
        }
        final debt = double.tryParse(value);
        if (debt == null) {
          return 'Por favor ingresa un número válido';
        }
        if (debt < 0) {
          return 'La deuda no puede ser negativa';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _isLoading ? null : _saveClient,
      icon: Icon(_isEditing ? Icons.update : Icons.save),
      label: Text(
        _isEditing ? 'Actualizar Cliente' : 'Guardar Cliente',
        style: const TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
}