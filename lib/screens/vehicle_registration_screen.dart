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

class _VehicleRegistrationScreenState
    extends State<VehicleRegistrationScreen> {
  final _service = VehicleService();
  List<Vehicle> _catalog = [];
  Vehicle? _selected;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final list = await _service.fetchCatalog();
      setState(() => _catalog = list);
    } catch (e) {
      _showError('Could not load vehicle catalog');
    }
  }

  Future<void> _submit() async {
    if (_selected == null) return _showError('Please select a vehicle');
    setState(() => _isLoading = true);

    try {
      await _service.registerVehicle(widget.usuarioId, _selected!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle registered!')),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError('Registration failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
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
            child: Column(
              children: [
                if (_catalog.isEmpty)
                  const CircularProgressIndicator()
                else
                  DropdownButtonFormField<Vehicle>(
                    decoration: InputDecoration(
                      labelText: 'Select Vehicle',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    value: _selected,
                    items: _catalog.map((v) {
                      return DropdownMenuItem(
                        value: v,
                        child: Text('${v.marca} ${v.modelo} (${v.autonomia}km)'),
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
                  child: _isLoading
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
