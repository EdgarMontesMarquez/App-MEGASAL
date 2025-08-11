import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';

class PDFService {
  static final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

  static Future<void> generateInvoice(Client client) async {
    if (client.payments.isEmpty) {
    throw Exception('No se puede generar factura sin abonos.');
  }
    try {
      // Cargar imágenes
      final vacaImage = await rootBundle.load('assets/vaca.png');
      final bultoImage = await rootBundle.load('assets/bulto.png');
      final firmaImage = await rootBundle.load('assets/firma.png');

      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) => _buildInvoicePage(
            client, 
            vacaImage, 
            bultoImage, 
            firmaImage
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('Error al generar factura: $e');
    }
  }

  static pw.Widget _buildInvoicePage(
    Client client,
    ByteData vacaImage,
    ByteData bultoImage,
    ByteData firmaImage,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(vacaImage, bultoImage, client),
        pw.SizedBox(height: 18),
        _buildClientInfo(client),
        pw.SizedBox(height: 14),
        _buildPurchaseDate(client),
        pw.SizedBox(height: 10),
        if (client.payments.isNotEmpty) _buildPaymentsTable(client),
        pw.SizedBox(height: 20),
        pw.Divider(thickness: 1),
        _buildTotals(client, firmaImage),
      ],
    );
  }

  static pw.Widget _buildHeader(ByteData vacaImage, ByteData bultoImage, Client client) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 120,
          height: 120,
          child: pw.Image(pw.MemoryImage(vacaImage.buffer.asUint8List())),
        ),
        pw.Expanded(child: _buildCompanyInfo()),
        _buildInvoiceNumber(bultoImage, client),
      ],
    );
  }

  static pw.Widget _buildCompanyInfo() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('SALES Y PREMESCLAS DEL CARIBE',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
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
    );
  }

  static pw.Widget _buildInvoiceNumber(ByteData bultoImage, Client client) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Container(
        width: 100,
        height: 100,
        child: pw.Image(pw.MemoryImage(bultoImage.buffer.asUint8List())),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'ESTADO DE CUENTA\nNo. ${client.invoiceNumber}',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      ),
    ],
  );
}

  static pw.Widget _buildClientInfo(Client client) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text('SEÑOR(ES): ${client.name}',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              'FECHA: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Text(
        'PRODUCTO COMPRADO: ${client.purchaseDescription}',
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );
}

  static pw.Widget _buildPurchaseDate(Client client) {
    return pw.Text(
      'FECHA DE COMPRA: ${DateFormat('dd/MM/yyyy').format(client.purchaseDate)}',
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _buildPaymentsTable(Client client) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE1F5FE)),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('FECHA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('ABONO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...client.payments.map((payment) => pw.TableRow(
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text(DateFormat('dd/MM/yyyy').format(payment.date)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text(currencyFormat.format(payment.amount)),
            ),
          ],
        )).toList(),
      ],
    );
  }

  static pw.Widget _buildTotals(Client client, ByteData firmaImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Container(
          width: 150,
          height: 150,
          child: pw.Image(pw.MemoryImage(firmaImage.buffer.asUint8List())),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'TOTAL ABONOS: ${currencyFormat.format(client.totalPayments)}',
              style: pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              'SALDO PENDIENTE: ${currencyFormat.format(client.debt)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}
