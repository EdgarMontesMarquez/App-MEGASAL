import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppConstants {
  // Colores
  static const Color primaryColor = Color(0xFF002B5C);
  static final Color primaryBlue = Colors.blue[800]!;
  static final Color successGreen = Colors.green[600]!;
  static final Color warningOrange = Colors.orange[600]!;
  static final Color dangerRed = Colors.red[600]!;

  // Formato de moneda
  static final NumberFormat currencyFormat = 
      NumberFormat.currency(locale: 'es_CO', symbol: '\$');

  // Strings
  static const String appTitle = 'Gestión de Clientes';
  static const String noClientsMessage = 'No hay clientes registrados';
  static const String addFirstClientMessage = 'Agrega tu primer cliente para comenzar';
  
  // Rutas
  static const String homeRoute = '/';
  static const String clientListRoute = '/ClientListScreen';
}