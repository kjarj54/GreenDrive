import 'package:flutter/material.dart';
import 'package:greendrive/model/station.dart';
import 'package:greendrive/providers/user_provider.dart';
import 'package:greendrive/screens/station_detail_screen.dart';
import 'package:greendrive/services/auth_services.dart';
import 'package:greendrive/services/station_service.dart';
import 'package:provider/provider.dart';

class StationListScreen extends StatefulWidget {
  const StationListScreen({Key? key}) : super(key: key);

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  final _stationService = ChargingStationService(AuthService());
  bool _isLoading = true;
  List<ChargingStation> _stations = [];
  List<ChargingStation> _filteredStations = [];
  String _error = '';
  String? _selectedChargerType;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Lista de tipos de cargadores para filtrar
  final List<String> _chargerTypes = [
    'All',
    'CCS',
    'CHAdeMO',
    'Type 2',
    'Tesla',
    'Type 1',
    'Schuko',
  ];
  @override
  void initState() {
    super.initState();
    _loadStations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterStations();
    });
  }

  void _filterStations() {
    // Si no hay estaciones cargadas, no hay nada que filtrar
    if (_stations.isEmpty) {
      _filteredStations = [];
      return;
    }

    // Filtrar por tipo de cargador y búsqueda
    _filteredStations = _stations.where((station) {
      // Filtrar por tipo de cargador
      final bool matchesType = _selectedChargerType == null || 
                              _selectedChargerType == 'All' || 
                              station.chargerType == _selectedChargerType;
      
      // Filtrar por texto de búsqueda
      final bool matchesSearch = _searchQuery.isEmpty || 
                               station.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                               station.address.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesType && matchesSearch;
    }).toList();
  }
  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Obtenemos todas las estaciones con un radio grande para obtener todas
      // En una implementación real, deberías tener un endpoint específico para listar todas
      // o usar la ubicación actual y un radio adecuado
      final stations = await _stationService.getNearbyStations(9.9281, -84.0907, 50.0);
      
      setState(() {
        _stations = stations;
        _filterStations();
        _isLoading = false;
      });    } catch (e) {
      setState(() {
        _error = 'Error al cargar las estaciones: $e';
        _isLoading = false;
      });
    }
  }
  void _showChargerTypeFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtrar por tipo de cargador'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _chargerTypes.map((String type) {
                  return ListTile(
                    title: Text(type),
                    selected: _selectedChargerType == type,
                    onTap: () {
                      setState(() {
                        _selectedChargerType = type == 'All' ? null : type;
                        _filterStations();
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estaciones de Carga')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStations,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(      appBar: AppBar(
        title: const Text('Estaciones de Carga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showChargerTypeFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o dirección',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Mostrar el filtro seleccionado como un chip
          if (_selectedChargerType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Chip(
                    label: Text(_selectedChargerType!),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedChargerType = null;
                        _filterStations();
                      });
                    },
                  ),
                ],
              ),
            ),

          // Lista de estaciones
          Expanded(
            child: _filteredStations.isEmpty
                ? const Center(child: Text('No hay estaciones disponibles con los criterios seleccionados.'))
                : ListView.builder(
                    itemCount: _filteredStations.length,
                    padding: const EdgeInsets.all(8.0),
                    itemBuilder: (context, index) {
                      final station = _filteredStations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StationDetailScreen(station: station),
                              ),
                            ).then((_) => _loadStations());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  station.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  station.address,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Tipo de cargador
                                    Chip(
                                      label: Text(
                                        station.chargerType,
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: Colors.blue.shade100,
                                    ),
                                    
                                    // Potencia
                                    Text(
                                      '${station.power} kW',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    
                                    // Disponibilidad
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: station.availability
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        station.availability
                                            ? 'Disponible'
                                            : 'No disponible',
                                        style: TextStyle(
                                          color: station.availability
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Tarifa y calificación
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Tarifa
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.attach_money,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        Text(
                                          ' ${station.rate.toStringAsFixed(2)} /kWh',
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Calificación
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                        Text(
                                          ' ${station.rating.toStringAsFixed(1)} (${station.reviewCount})',
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
