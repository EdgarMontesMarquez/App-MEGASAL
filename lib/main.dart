
import 'package:facturapp/screens/home_screen.dart' as home_screen;
import 'package:flutter/material.dart';
import 'package:facturapp/screens/generate_invoice_screen.dart';
import 'package:facturapp/screens/client_list_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Megasal',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'MX'), Locale('en', 'US')],
      home: home_screen.InvoiceHistoryScreen(),
      routes: {
        '/GenerateInvoiceScreen': (context) =>  GenerateInvoiceScreen(),
        '/ClientListScreen': (context) => ClientListScreen(),
      },
    );
  }
}
