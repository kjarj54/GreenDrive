import 'package:flutter/material.dart';
import 'package:greendrive/model/station.dart';
import 'package:greendrive/services/notification_manager.dart';
import 'package:greendrive/services/notification_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final _destinationController = TextEditingController(text: 'San José');
  final _distanceController = TextEditingController(text: '150');
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  final _promotionController = TextEditingController(text: '20% de descuento en tu próxima carga');
  
  @override
  void dispose() {
    _destinationController.dispose();
    _distanceController.dispose();
    _promotionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Notificaciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de recordatorio de carga
              const Text(
                'Recordatorio de carga',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destino',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: 'Distancia (km)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Fecha del viaje'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await NotificationManager.setTripReminder(
                      destination: _destinationController.text,
                      distanceKm: double.parse(_distanceController.text),
                      tripDate: _selectedDate,
                    );
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Recordatorio programado')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Programar recordatorio'),
              ),
              
              const Divider(height: 40),
              
              // Sección de prueba de notificación inmediata
              const Text(
                'Notificaciones de prueba (inmediatas)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: () async {
                  // Crear estación de ejemplo
                  final station = ChargingStation(
                    id: 1,
                    name: 'EcoCharge Central',
                    latitude: 9.9281,
                    longitude: -84.0907,
                    address: 'San José, Costa Rica',
                    chargerType: 'Tipo 2',
                    power: 50,
                    rate: 150.0,
                    availability: true,
                    schedule: '24/7',
                  );
                  
                  await NotificationManager.notifyNewStation(station);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notificación de nueva estación enviada')),
                    );
                  }
                },
                child: const Text('Probar notificación de nueva estación'),
              ),
              
              const SizedBox(height: 16),
              
              TextField(
                controller: _promotionController,
                decoration: const InputDecoration(
                  labelText: 'Detalles de la promoción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: () async {
                  // Crear estación de ejemplo
                  final station = ChargingStation(
                    id: 2,
                    name: 'Electrify Express',
                    latitude: 9.9365,
                    longitude: -84.0765,
                    address: 'Escazú, San José',
                    chargerType: 'CCS',
                    power: 150,
                    rate: 200.0,
                    availability: true,
                    schedule: '8:00-20:00',
                  );
                  
                  await NotificationManager.notifyPromotion(
                    station: station,
                    promotionDetails: _promotionController.text,
                    expirationDate: DateTime.now().add(const Duration(days: 7)),
                  );
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notificación de promoción enviada')),
                    );
                  }
                },
                child: const Text('Probar notificación de promoción'),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () async {
                  await NotificationService.showNotification(
                    title: 'Notificación de prueba',
                    body: 'Esta es una notificación de prueba básica',
                    payload: 'test_notification',
                  );
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notificación básica enviada')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                child: const Text('Enviar notificación básica'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}