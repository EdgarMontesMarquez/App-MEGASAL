import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class GenerateInvoiceScreen extends StatefulWidget {
  const GenerateInvoiceScreen({super.key});

  @override
  State<GenerateInvoiceScreen> createState() => _GenerateInvoiceScreenState();
}

class _GenerateInvoiceScreenState extends State<GenerateInvoiceScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _clientNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _carrierNameController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _plateController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitValueController = TextEditingController();

  // Form keys for validation
  final _formKey = GlobalKey<FormState>();

  // Data
  final List<Map<String, dynamic>> _products = [];
  late String _invoiceNumber;
  DateTime? _selectedDate;
  double _subtotal = 0.0;
  double _total = 0.0;
  bool _isGenerating = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Constants
  static const _primaryColor = Color(0xFF002B5C);
  static const _accentColor = Color(0xFF1479CC);
  static const _successColor = Color(0xFF16C91C);

  // Validation flags
  bool get _hasClientData => _clientNameController.text.trim().isNotEmpty && _selectedDate != null;
  bool get _hasTransportData => 
      _carrierNameController.text.trim().isNotEmpty && 
      _vehicleController.text.trim().isNotEmpty && 
      _plateController.text.trim().isNotEmpty;
  bool get _canGenerateInvoice => _hasClientData && _hasTransportData && _products.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAnimation();
    _setupListeners();
  }

  void _initializeData() {
    _invoiceNumber = _generateUniqueInvoiceNumber();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  void _setupListeners() {
    // Optimized listeners with debouncing
    _clientNameController.addListener(_onDataChanged);
    _carrierNameController.addListener(_onDataChanged);
    _vehicleController.addListener(_onDataChanged);
    _plateController.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    // Debounced state update to prevent excessive rebuilds
    if (mounted) {
      setState(() {});
    }
  }

  String _generateUniqueInvoiceNumber() {
  final random = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
  return random.toString().padLeft(6, '0');
}

  @override
  void dispose() {
    _clientNameController.dispose();
    _dateController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _unitValueController.dispose();
    _carrierNameController.dispose();
    _vehicleController.dispose();
    _plateController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _validateProductForm() {
    final quantity = int.tryParse(_quantityController.text.trim());
    final unitValue = double.tryParse(_unitValueController.text.trim());
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      _showSnackBar('La descripción del producto es requerida', Icons.warning, Colors.orange);
      return false;
    }
    if (quantity == null || quantity <= 0) {
      _showSnackBar('La cantidad debe ser un número válido mayor a 0', Icons.warning, Colors.orange);
      return false;
    }
    if (unitValue == null || unitValue <= 0) {
      _showSnackBar('El valor unitario debe ser un número válido mayor a 0', Icons.warning, Colors.orange);
      return false;
    }
    return true;
  }

  void _addProduct() {
    if (!_validateProductForm()) return;

    final int quantity = int.parse(_quantityController.text.trim());
    final double unitValue = double.parse(_unitValueController.text.trim());
    final double totalValue = quantity * unitValue;

    setState(() {
      _products.add({
        'quantity': quantity,
        'description': _descriptionController.text.trim(),
        'unitValue': unitValue,
        'totalValue': totalValue,
      });

      _subtotal += totalValue;
      _total = _subtotal;

      // Clear product form
      _quantityController.clear();
      _descriptionController.clear();
      _unitValueController.clear();
    });

    _showSnackBar('Producto agregado exitosamente', Icons.check_circle, _successColor);
  }

  void _removeProduct(int index) {
    setState(() {
      _subtotal -= _products[index]['totalValue'];
      _total = _subtotal;
      _products.removeAt(index);
    });
    _showSnackBar('Producto eliminado', Icons.delete, Colors.orange);
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      });
    }
  }

  Future<void> _generateAndShareInvoice() async {
    if (!_canGenerateInvoice) {
      String message = '';
      if (!_hasClientData) {
        message = 'Complete los datos del cliente';
      } else if (!_hasTransportData) {
        message = 'Complete los datos del transportista';
      } else if (_products.isEmpty) {
        message = 'Agregue al menos un producto';
      }
      _showSnackBar(message, Icons.warning, Colors.orange);
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final pdf = pw.Document();
      final NumberFormat currencyFormat = NumberFormat.currency(
        locale: 'es_MX',
        symbol: '\$',
      );

      // Load images with error handling
      pw.MemoryImage? vacaImage, firmaImage, bultoImage;
      
      try {
        final vacaBytes = await rootBundle.load('assets/vaca.png');
        vacaImage = pw.MemoryImage(vacaBytes.buffer.asUint8List());
        
        final firmaBytes = await rootBundle.load('assets/firma.png');
        firmaImage = pw.MemoryImage(firmaBytes.buffer.asUint8List());
        
        final bultoBytes = await rootBundle.load('assets/bulto.png');
        bultoImage = pw.MemoryImage(bultoBytes.buffer.asUint8List());
      } catch (e) {
        print('Error loading images: $e');
      }

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) => _buildPdfContent(
            vacaImage,
            firmaImage,
            bultoImage,
            currencyFormat,
          ),
        ),
      );

      // Save and share PDF
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/factura_$_invoiceNumber.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'Factura $_invoiceNumber generada');
      
      _showSnackBar('Factura generada y compartida exitosamente', Icons.share, _successColor);
    } catch (e) {
      _showSnackBar('Error al generar la factura: ${e.toString()}', Icons.error, Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  pw.Widget _buildPdfContent(
    pw.MemoryImage? vacaImage,
    pw.MemoryImage? firmaImage,
    pw.MemoryImage? bultoImage,
    NumberFormat currencyFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header with logos and company data
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (vacaImage != null)
              pw.Container(width: 120, height: 120, child: pw.Image(vacaImage))
            else
              pw.Container(width: 120, height: 120, color: PdfColor.fromInt(0xFFE0E0E0)),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('SALES Y PREMESCLAS DEL CARIBE',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('"MEGASAL"',
                      style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('Prop.: DAVID PALMERA CARRILLO',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('NIT 7593129-0 RÉGIMEN SIMPLIFICADO',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('CALLE 9 BIS CRA. 6 - 3 \nTOLUVIEJO - SUCRE',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('CEL.: 310 691 7927 - 310 355 9795',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (bultoImage != null)
                  pw.Container(width: 100, height: 100, child: pw.Image(bultoImage))
                else
                  pw.Container(width: 100, height: 100, color: PdfColor.fromInt(0xFFE0E0E0)),
                pw.SizedBox(height: 6),
                pw.Text('FACTURA DE VENTA \n          No. $_invoiceNumber',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        
        // Client data and date
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Text('SEÑOR(ES): ${_clientNameController.text}',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('FECHA: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        
        pw.SizedBox(height: 14),
        
        // Products table
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          headers: ['CANT', 'DESCRIPCIÓN', 'VR. UNITARIO', 'VALOR TOTAL'],
          cellStyle: pw.TextStyle(fontSize: 10),
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE1F5FE)),
          data: _products.map((product) => [
            product['quantity'].toString(),
            product['description'],
            currencyFormat.format(product['unitValue']),
            currencyFormat.format(product['totalValue']),
          ]).toList(),
          border: pw.TableBorder.all(width: 0.5, color: PdfColor.fromInt(0xFFBDBDBD)),
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
          columnWidths: {
            0: const pw.FixedColumnWidth(40),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.2),
          },
        ),
        
        pw.SizedBox(height: 14),
        
        // Transport data
        pw.Text('Transportista: ${_carrierNameController.text}',
            style: pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 1),
        pw.Text('Vehículo: ${_vehicleController.text}',
            style: pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 1),
        pw.Text('Placa: ${_plateController.text}',
            style: pw.TextStyle(fontSize: 12)),
        
        pw.SizedBox(height: 5),
        pw.Divider(thickness: 1),
        
        // Signature and totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (firmaImage != null)
              pw.Container(width: 150, height: 150, child: pw.Image(firmaImage))
            else
              pw.Container(width: 150, height: 150, color: PdfColor.fromInt(0xFFE0E0E0)),
            pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 250,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('SUB-TOTAL:', style: pw.TextStyle(fontSize: 16)),
                          pw.Text(currencyFormat.format(_subtotal),
                              style: pw.TextStyle(fontSize: 16)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL:',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                          pw.Text(currencyFormat.format(_total),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    IconData? icon,
    Color? backgroundColor,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: backgroundColor ?? Colors.white,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: _primaryColor, size: 24),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? prefixIcon,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: _primaryColor) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
    required Color color,
    required IconData icon,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 20),
        label: Text(
          isLoading ? 'Procesando...' : text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          disabledBackgroundColor: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _accentColor,
          radius: 20,
          child: Text(
            '${product['quantity']}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        title: Text(
          product['description'],
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Precio unitario: \$${NumberFormat('#,##0', 'es_MX').format(product['unitValue'])}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total:', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                Text(
                  '\$${NumberFormat('#,##0', 'es_MX').format(product['totalValue'])}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _removeProduct(index),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationIndicator(bool isValid, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isValid ? _successColor.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isValid ? _successColor : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            size: 16,
            color: isValid ? _successColor : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isValid ? _successColor : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        toolbarHeight:11,
        automaticallyImplyLeading: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header with company info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor.withOpacity(0.1), Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Image.asset('assets/vaca.png', height: 45, width: 45),
                          const Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Sales y Premesclas del Caribe',
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '"MEGASAL"',
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Image.asset('assets/bulto.png', height: 45, width: 45),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Factura No. $_invoiceNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Validation indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildValidationIndicator(_hasClientData, 'Cliente'),
                    _buildValidationIndicator(_hasTransportData, 'Transporte'),
                    _buildValidationIndicator(_products.isNotEmpty, 'Productos'),
                  ],
                ),

                const SizedBox(height: 20),

                // Client Information
                _buildSectionCard(
                  title: 'Datos del Cliente',
                  icon: Icons.person,
                  backgroundColor: _hasClientData ? _successColor.withOpacity(0.05) : null,
                  children: [
                    _buildCustomTextField(
                      controller: _clientNameController,
                      label: 'Nombre del Cliente *',
                      hintText: 'Ingrese el nombre completo',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre del cliente es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildCustomTextField(
                      controller: _dateController,
                      label: 'Fecha *',
                      prefixIcon: Icons.calendar_today,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La fecha es requerida';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                // Transport Information
                _buildSectionCard(
                  title: 'Datos del Transportista',
                  icon: Icons.local_shipping,
                  backgroundColor: _hasTransportData ? _successColor.withOpacity(0.05) : null,
                  children: [
                    _buildCustomTextField(
                      controller: _carrierNameController,
                      label: 'Nombre del Transportista *',
                      hintText: 'Nombre completo del conductor',
                      prefixIcon: Icons.person_pin,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre del transportista es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCustomTextField(
                            controller: _vehicleController,
                            label: 'Vehículo *',
                            hintText: 'Tipo de vehículo',
                            prefixIcon: Icons.directions_car,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El vehículo es requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCustomTextField(
                            controller: _plateController,
                            label: 'Placa *',
                            hintText: 'ABC-123',
                            prefixIcon: Icons.confirmation_number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La placa es requerida';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Product Form
                _buildSectionCard(
                  title: 'Agregar Producto',
                  icon: Icons.inventory,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildCustomTextField(
                            controller: _quantityController,
                            label: 'Cantidad *',
                            hintText: '1',
                            prefixIcon: Icons.numbers,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _buildCustomTextField(
                            controller: _descriptionController,
                            label: 'Descripción *',
                            hintText: 'Nombre del producto',
                            prefixIcon: Icons.description,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildCustomTextField(
                      controller: _unitValueController,
                      label: 'Valor Unitario *',
                      hintText: '0.00',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    _buildActionButton(
                      text: 'Agregar Producto',
                      onPressed: _hasClientData && _hasTransportData ? _addProduct : null,
                      color: _accentColor,
                      icon: Icons.add,
                    ),
                    if (!_hasClientData || !_hasTransportData)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Complete los datos del cliente y transportista para agregar productos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),

                // Products Summary
                if (_products.isNotEmpty)
                  _buildSectionCard(
                    title: 'Productos Agregados (${_products.length})',
                    icon: Icons.list_alt,
                    backgroundColor: _successColor.withOpacity(0.05),
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(_products[index], index);
                        },
                      ),
                      const Divider(thickness: 1),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_successColor.withOpacity(0.1), _successColor.withOpacity(0.05)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _successColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL FACTURA: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                            Text(
                              '\$${NumberFormat('#,##0', 'es_MX').format(_total)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // Generate Invoice Button
                _buildActionButton(
                  text: 'Generar y Compartir Factura',
                  onPressed: _canGenerateInvoice ? _generateAndShareInvoice : null,
                  color: _successColor,
                  icon: Icons.receipt_long,
                  isLoading: _isGenerating,
                ),

                if (!_canGenerateInvoice)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Complete todos los datos requeridos para generar la factura',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/');
            } else if (index == 2) {
              Navigator.pushNamed(context, '/ClientListScreen');
            }
          },
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Historial',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Generar Factura',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.attach_money),
              label: 'Abonos',
            ),
          ],
        ),
      ),
    );
  }
}