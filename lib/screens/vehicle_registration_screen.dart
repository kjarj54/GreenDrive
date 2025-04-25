import 'package:flutter/material.dart';
import 'package:greendrive/model/vehicle.dart';
import 'package:greendrive/services/vehicle_service.dart';
import 'package:greendrive/widgets/shared/gradient_background.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  final int usuarioId;
  const VehicleRegistrationScreen({Key? key, required this.usuarioId})
    : super(key: key);

  @override
  _VehicleRegistrationScreenState createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _service = VehicleService();
  List<Vehicle> _catalog = [];
  Vehicle? _selected;
  Vehicle? _currentVehicle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final catalog = await _service.fetchCatalog();
      final current = await _service.fetchCurrentVehicle(widget.usuarioId);
      setState(() {
        _catalog = catalog;
        _currentVehicle = current;
        _selected = current;
      });
    } catch (e) {
      _showError('Could not load vehicle data');
    }
  }

  Future<void> _submit() async {
    if (_selected == null) {
      _showError('Please select a vehicle');
      return;
    }

    if (_currentVehicle != null && _selected!.id == _currentVehicle!.id) {
      _showError('You have already registered this vehicle.');
      return;
    }

    final confirm = await _showConfirmationDialog();
    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      await _service.registerVehicle(widget.usuarioId, _selected!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle registered successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError('Vehicle registration failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Change Vehicle'),
                content: const Text(
                  'Are you sure you want to change your registered vehicle?',
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Confirm'),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Vehicle'),
        backgroundColor: Colors.green.shade700,
      ),
      body: GradientBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child:
                _catalog.isEmpty
                    ? const CircularProgressIndicator()
                    : Column(
                      children: [
                        if (_currentVehicle != null)
                          Card(
                            color: Colors.green.shade100,
                            margin: const EdgeInsets.only(bottom: 24),
                            child: ListTile(
                              leading: const Icon(
                                Icons.directions_car,
                                size: 40,
                              ),
                              title: Text(
                                '${_currentVehicle!.marca} ${_currentVehicle!.modelo}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              subtitle: Text(
                                'Range: ${_currentVehicle!.autonomia} km',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        DropdownButtonFormField<Vehicle>(
                          decoration: InputDecoration(
                            labelText: 'Select Vehicle',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          isExpanded: true, // 👈 esto evita overflow
                          value: _selected,
                          items:
                              _catalog.map((v) {
                                return DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    '${v.marca} ${v.modelo} (${v.autonomia}km)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (v) => setState(() => _selected = v),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: Colors.green.shade700,
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Register'),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
