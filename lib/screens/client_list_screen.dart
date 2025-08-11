import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/storage_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/client_card.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../utils/app_constants.dart';
import 'add_edit_client_screen.dart';
import 'client_detail_screen.dart';

class ClientListScreen extends StatefulWidget {
  @override
  _ClientListScreenState createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  List<Client> clients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      setState(() => isLoading = true);
      final loadedClients = await StorageService.getClients();
      setState(() {
        clients = loadedClients;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Error al cargar clientes: $e');
    }
  }

  Future<void> _deleteClient(int id) async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed) {
      try {
        await StorageService.deleteClient(id);
        await _loadClients();
        _showSuccessSnackBar('Cliente eliminado exitosamente');
      } catch (e) {
        _showErrorSnackBar('Error al eliminar cliente: $e');
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este cliente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _handleBottomNavigationTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
    } else if (index == 2) {
      Navigator.pushNamed(context, AppConstants.clientListRoute);
    } else if (index == 1) {
      Navigator.pushNamed(context, '/GenerateInvoiceScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(10),
        child: AppBar(
          backgroundColor: AppConstants.primaryColor,
          elevation: 0,
          toolbarHeight: 30,
          automaticallyImplyLeading: false,
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          
          
          // Título de la sección
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF002B5C),
                  const Color(0xFF002B5C).withOpacity(0.8),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lista de Clientes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${clients.length} cliente${clients.length != 1 ? 's' : ''} registrado${clients.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (clients.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${clients.where((c) => c.hasDebt).length} con deuda',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Lista de clientes
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : clients.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.people,
                        title: AppConstants.noClientsMessage,
                        subtitle: AppConstants.addFirstClientMessage,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: clients.length,
                        itemBuilder: (context, index) {
                          final client = clients[index];
                          return ClientCard(
                            client: client,
                            onView: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClientDetailScreen(client: client),
                                ),
                              );
                              if (result == true) _loadClients();
                            },
                            onEdit: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditClientScreen(client: client),
                                ),
                              );
                              if (result == true) _loadClients();
                            },
                            onDelete: () => _deleteClient(client.id),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditClientScreen()),
          );
          if (result == true) _loadClients();
        },
        backgroundColor: AppConstants.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 2,
        onTap: _handleBottomNavigationTap,
      ),
    );
  }
}