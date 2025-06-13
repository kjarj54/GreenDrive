import 'package:flutter/material.dart';
import 'package:greendrive/services/admin_service.dart';
import 'package:greendrive/services/auth_services.dart';
import 'package:greendrive/services/notification_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdminService _adminService;
  
  bool _isLoading = false;

  // Station Form Controllers
  final _stationFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _addressController = TextEditingController();
  final _powerController = TextEditingController();
  final _rateController = TextEditingController();
  final _scheduleController = TextEditingController();
  
  String _selectedChargerType = 'Type 2';
  bool _availability = true;

  // Notification Form Controllers
  final _notificationFormKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _selectedNotificationType = 'GENERAL';

  // Available charger types
  final List<String> _chargerTypes = [
    'Type 2',
    'CCS',
    'CHAdeMO',
    'Tesla',
    'Type 1',
    'Schuko',
  ];

  // Available notification types
  final List<String> _notificationTypes = [
    'GENERAL',
    'NUEVA_ESTACION',
    'PROMOCION',
    'MANTENIMIENTO',
    'EMERGENCIA',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _adminService = AdminService(AuthService());
    
    // Set default schedule
    _scheduleController.text = '24/7';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _powerController.dispose();
    _rateController.dispose();
    _scheduleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createStation() async {
    if (!_stationFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _adminService.createStation(
        name: _nameController.text.trim(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        address: _addressController.text.trim(),
        chargerType: _selectedChargerType,
        power: int.parse(_powerController.text.trim()),
        rate: double.parse(_rateController.text.trim()),
        availability: _availability,
        schedule: _scheduleController.text.trim(),
      );

      if (mounted) {
        // Clear form
        _clearStationForm();
        
        // Show success message
        NotificationService.showSuccessSnackBar(
          context,
          message: '¡Estación creada exitosamente!',
        );

        // Show native notification
        await NotificationService.showNotification(
          title: 'Nueva estación agregada',
          body: 'La estación "${_nameController.text}" ha sido creada y todos los usuarios han sido notificados.',
          payload: 'admin_station_created',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showErrorSnackBar(
          context,
          message: 'Error al crear la estación: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendBroadcastNotification() async {
    if (!_notificationFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _adminService.sendBroadcastNotification(
        message: _messageController.text.trim(),
        type: _selectedNotificationType,
      );

      if (mounted) {
        // Clear form
        _messageController.clear();
        
        // Show success message
        NotificationService.showSuccessSnackBar(
          context,
          message: '¡Notificación enviada a todos los usuarios!',
        );

        // Show native notification
        await NotificationService.showNotification(
          title: 'Notificación enviada',
          body: 'Se ha enviado la notificación masiva a todos los usuarios de la aplicación.',
          payload: 'admin_broadcast_sent',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showErrorSnackBar(
          context,
          message: 'Error al enviar la notificación: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearStationForm() {
    _nameController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _addressController.clear();
    _powerController.clear();
    _rateController.clear();
    _scheduleController.text = '24/7';
    _selectedChargerType = 'Type 2';
    _availability = true;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.ev_station),
              text: 'Nueva Estación',
            ),
            Tab(
              icon: Icon(Icons.notifications),
              text: 'Notificaciones',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStationForm(),
          _buildNotificationForm(),
        ],
      ),
    );
  }

  Widget _buildStationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _stationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Agregar Nueva Estación de Carga',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Al crear una nueva estación, todos los usuarios recibirán automáticamente una notificación.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Station Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Estación *',
                hintText: 'Ej: EcoCharge Central',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.ev_station),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingrese el nombre de la estación';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Coordinates
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitud *',
                      hintText: '9.9281',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Requerido';
                      }
                      final lat = double.tryParse(value.trim());
                      if (lat == null || lat < -90 || lat > 90) {
                        return 'Latitud inválida';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitud *',
                      hintText: '-84.0907',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Requerido';
                      }
                      final lng = double.tryParse(value.trim());
                      if (lng == null || lng < -180 || lng > 180) {
                        return 'Longitud inválida';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección *',
                hintText: 'Ej: San José, Costa Rica',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingrese la dirección';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Charger Type
            DropdownButtonFormField<String>(
              value: _selectedChargerType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Cargador *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.electrical_services),
              ),
              items: _chargerTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedChargerType = newValue);
                }
              },
            ),
            const SizedBox(height: 16),

            // Power and Rate
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _powerController,
                    decoration: const InputDecoration(
                      labelText: 'Potencia (kW) *',
                      hintText: '50',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bolt),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Requerido';
                      }
                      final power = int.tryParse(value.trim());
                      if (power == null || power <= 0) {
                        return 'Potencia inválida';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    decoration: const InputDecoration(
                      labelText: 'Tarifa (¢/kWh) *',
                      hintText: '150.0',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Requerido';
                      }
                      final rate = double.tryParse(value.trim());
                      if (rate == null || rate < 0) {
                        return 'Tarifa inválida';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Schedule
            TextFormField(
              controller: _scheduleController,
              decoration: const InputDecoration(
                labelText: 'Horario *',
                hintText: '24/7, 8:00-20:00, etc.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingrese el horario';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Availability
            SwitchListTile(
              title: const Text('Disponible'),
              subtitle: const Text('La estación está operativa'),
              value: _availability,
              onChanged: (bool value) {
                setState(() => _availability = value);
              },
              activeColor: Colors.green,
            ),
            const SizedBox(height: 32),

            // Create Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createStation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_location),
                        SizedBox(width: 8),
                        Text(
                          'Crear Estación y Notificar Usuarios',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _notificationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enviar Notificación Masiva',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta notificación se enviará a todos los usuarios registrados en la aplicación.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Notification Type
            DropdownButtonFormField<String>(
              value: _selectedNotificationType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Notificación *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _notificationTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(_getNotificationTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedNotificationType = newValue);
                }
              },
            ),
            const SizedBox(height: 16),

            // Message
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Mensaje *',
                hintText: 'Escriba el mensaje de la notificación...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingrese el mensaje';
                }
                if (value.trim().length < 10) {
                  return 'El mensaje debe tener al menos 10 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Send Button
            ElevatedButton(
              onPressed: _isLoading ? null : _sendBroadcastNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.send),
                        SizedBox(width: 8),
                        Text(
                          'Enviar Notificación a Todos los Usuarios',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNotificationTypeDisplayName(String type) {
    switch (type) {
      case 'GENERAL':
        return 'General';
      case 'NUEVA_ESTACION':
        return 'Nueva Estación';
      case 'PROMOCION':
        return 'Promoción';
      case 'MANTENIMIENTO':
        return 'Mantenimiento';
      case 'EMERGENCIA':
        return 'Emergencia';
      default:
        return type;
    }
  }
}
