import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';

class StorageService {
  static const String _clientsKey = 'clients';

  static Future<List<Client>> getClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = prefs.getString(_clientsKey);
      if (clientsJson == null) return [];
      
      final List<dynamic> clientsList = json.decode(clientsJson);
      return clientsList.map((json) => Client.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar clientes: $e');
    }
  }

  static Future<void> saveClients(List<Client> clients) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = json.encode(clients.map((c) => c.toJson()).toList());
      await prefs.setString(_clientsKey, clientsJson);
    } catch (e) {
      throw Exception('Error al guardar clientes: $e');
    }
  }

  static Future<void> deleteClient(int clientId) async {
    final clients = await getClients();
    clients.removeWhere((client) => client.id == clientId);
    await saveClients(clients);
  }

  static Future<void> updateClient(Client updatedClient) async {
    final clients = await getClients();
    final index = clients.indexWhere((c) => c.id == updatedClient.id);
    if (index != -1) {
      clients[index] = updatedClient;
      await saveClients(clients);
    }
  }
}