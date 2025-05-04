import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorSection extends StatefulWidget {
  const CalculatorSection({super.key});

  @override
  State<CalculatorSection> createState() => _CalculatorSectionState();
}

class _CalculatorSectionState extends State<CalculatorSection> {
  // Controladores para los inputs
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _fuelEfficiencyController = TextEditingController();
  final TextEditingController _fuelPriceController = TextEditingController();
  final TextEditingController _electricityConsumptionController = TextEditingController();
  final TextEditingController _electricityPriceController = TextEditingController();

  // Resultados del cálculo
  double _gasolineCost = 0.0;
  double _electricCost = 0.0;
  double _costSaving = 0.0;
  double _costSavingPercent = 0.0;
  double _co2Emissions = 0.0;
  double _co2Reduction = 0.0;

  // Valores predeterminados
  final double _defaultFuelEfficiency = 12.0; // km/L
  final double _defaultFuelPrice = 4800.0; // pesos/L
  final double _defaultElectricityConsumption = 0.17; // kWh/km
  final double _defaultElectricityPrice = 600.0; // pesos/kWh
  final double _gasolineCO2PerKm = 0.22; // kg de CO2/km aproximado para vehículos a gasolina
  final double _electricityCO2PerKWh = 0.1; // kg de CO2/kWh (depende del mix energético)

  @override
  void initState() {
    super.initState();
    // Establecer valores predeterminados
    _fuelEfficiencyController.text = _defaultFuelEfficiency.toString();
    _fuelPriceController.text = _defaultFuelPrice.toString();
    _electricityConsumptionController.text = _defaultElectricityConsumption.toString();
    _electricityPriceController.text = _defaultElectricityPrice.toString();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _fuelEfficiencyController.dispose();
    _fuelPriceController.dispose();
    _electricityConsumptionController.dispose();
    _electricityPriceController.dispose();
    super.dispose();
  }

  // Función para calcular costos y emisiones
  void _calculateCostsAndEmissions() {
    try {
      // Obtener valores de los inputs
      final double distance = double.parse(_distanceController.text);
      final double fuelEfficiency = double.parse(_fuelEfficiencyController.text);
      final double fuelPrice = double.parse(_fuelPriceController.text);
      final double electricityConsumption = double.parse(_electricityConsumptionController.text);
      final double electricityPrice = double.parse(_electricityPriceController.text);

      // Cálculo de costos
      final double fuelUsed = distance / fuelEfficiency; // litros de combustible
      final double electricityUsed = distance * electricityConsumption; // kWh usados

      setState(() {
        _gasolineCost = fuelUsed * fuelPrice;
        _electricCost = electricityUsed * electricityPrice;
        _costSaving = _gasolineCost - _electricCost;
        _costSavingPercent = (_costSaving / _gasolineCost) * 100;

        // Cálculo de emisiones CO2
        _co2Emissions = distance * _gasolineCO2PerKm; // kg CO2 del vehículo a gasolina
        double electricCO2 = electricityUsed * _electricityCO2PerKWh; // kg CO2 del vehículo eléctrico
        _co2Reduction = _co2Emissions - electricCO2;
      });
    } catch (e) {
      // Manejo de errores en caso de inputs inválidos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa valores válidos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calculadora de Costos y Emisiones',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Sección de entrada de datos
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del Viaje',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _distanceController,
                      decoration: const InputDecoration(
                        labelText: 'Distancia del viaje (km)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.route),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Vehículo a Gasolina',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fuelEfficiencyController,
                            decoration: const InputDecoration(
                              labelText: 'Rendimiento (km/L)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_gas_station),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _fuelPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Precio gasolina (\$/L)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Vehículo Eléctrico',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _electricityConsumptionController,
                            decoration: const InputDecoration(
                              labelText: 'Consumo (kWh/km)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.electric_car),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _electricityPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Precio electricidad (\$/kWh)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.bolt),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _calculateCostsAndEmissions,
                        child: const Text(
                          'Calcular',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sección de resultados
            if (_gasolineCost > 0 || _electricCost > 0)
              Card(
                elevation: 4,
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resultados',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Comparativa de costos
                      _buildResultRow(
                        'Costo con gasolina',
                        '\$${_gasolineCost.toStringAsFixed(2)}',
                        Icons.local_gas_station,
                        Colors.red.shade700,
                      ),
                      _buildResultRow(
                        'Costo eléctrico',
                        '\$${_electricCost.toStringAsFixed(2)}',
                        Icons.electric_car,
                        Colors.green.shade700,
                      ),
                      const Divider(thickness: 1),
                      _buildResultRow(
                        'Ahorro',
                        '\$${_costSaving.toStringAsFixed(2)} (${_costSavingPercent.toStringAsFixed(1)}%)',
                        Icons.savings,
                        Colors.blue.shade700,
                        isBold: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Comparativa de emisiones
                      _buildResultRow(
                        'Emisiones CO₂ con gasolina',
                        '${_co2Emissions.toStringAsFixed(2)} kg',
                        Icons.cloud,
                        Colors.red.shade700,
                      ),
                      _buildResultRow(
                        'Reducción de CO₂',
                        '${_co2Reduction.toStringAsFixed(2)} kg',
                        Icons.eco,
                        Colors.green.shade700,
                        isBold: true,
                      ),
                      
                      // Representación visual
                      const SizedBox(height: 24),
                      _buildComparisonChart(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart() {
    if (_gasolineCost <= 0 || _electricCost <= 0) return const SizedBox.shrink();
    
    final maxValue = _gasolineCost > _electricCost ? _gasolineCost : _electricCost;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comparativa Visual',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 100, child: Text('Gasolina')),
            Expanded(
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: MediaQuery.of(context).size.width * (_gasolineCost / maxValue) * 0.6,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '\$${_gasolineCost.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 100, child: Text('Eléctrico')),
            Expanded(
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: MediaQuery.of(context).size.width * (_electricCost / maxValue) * 0.6,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '\$${_electricCost.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}