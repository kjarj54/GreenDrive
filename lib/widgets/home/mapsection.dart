import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:greendrive/model/station.dart';
import 'package:greendrive/model/vehicle.dart';
import 'package:greendrive/services/auth_services.dart';
import 'package:greendrive/services/googlemaps_service.dart';
import 'package:greendrive/services/station_service.dart';
import 'package:greendrive/services/vehicle_service.dart';

class MapSection extends StatefulWidget {
  const MapSection({super.key});

  static _MapSectionState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MapSectionState>();
  }

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  late GoogleMapController mapController;
  late final ChargingStationService _stationService;
  LatLng _currentPosition = const LatLng(9.9281, -84.0907);
  final Set<Marker> _markers = {};
  final Set<Polyline> _routes = {};
  String _currentFeature = '';
  final double _searchRadius = 10.0;
  bool _isLoading = false;
  late final GoogleMapsService _googleMapsService;
  Polyline? _selectedRoute;
  ChargingStation?
  _selectedStation; // Propiedad para almacenar la estación seleccionada
  bool _showStationDetails =
      false; // Controla la visibilidad del panel de detalles

  @override
  void initState() {
    super.initState();
    _stationService = ChargingStationService(AuthService());
    _googleMapsService = GoogleMapsService();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition));
    } catch (e) {
      if (!mounted) return;
      _showError('Error getting location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void toggleMapFeature(String feature) async {
    setState(() {
      _currentFeature = _currentFeature == feature ? '' : feature;
    });

    switch (feature) {
      case 'Chargers':
        await _loadNearbyChargers();
        break;
      case 'Routes':
        await _findOptimalRoute();
        break;
      case 'Filters':
        await _showAdvancedFilters();
        break;
      case 'Trip':
        await _showTripPlanner();
        break;
    }
  }

  Future<void> _showAdvancedFilters() async {
    bool? isFreeFilter;
    bool? isAvailableFilter;
    bool? hasFastChargingFilter;
    String? selectedChargerType;
    RangeValues? powerRange;
    _routes.clear();
    _markers.clear();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Advanced Filters'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Free stations filter
                        CheckboxListTile(
                          title: const Text('Free Charging Stations'),
                          tristate: true,
                          value: isFreeFilter,
                          onChanged:
                              (value) => setState(() => isFreeFilter = value),
                        ),

                        // Available status filter
                        CheckboxListTile(
                          title: const Text('Available Stations Only'),
                          tristate: true,
                          value: isAvailableFilter,
                          onChanged:
                              (value) =>
                                  setState(() => isAvailableFilter = value),
                        ),

                        // Fast charging filter
                        CheckboxListTile(
                          title: const Text('Fast Charging Stations'),
                          tristate: true,
                          value: hasFastChargingFilter,
                          onChanged:
                              (value) =>
                                  setState(() => hasFastChargingFilter = value),
                        ),

                        const Divider(),

                        // Charger type filter
                        DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Charging Type',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedChargerType,
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All Types'),
                            ),
                            DropdownMenuItem(
                              value: 'Type 1',
                              child: Text('Type 1'),
                            ),
                            DropdownMenuItem(
                              value: 'Type 2',
                              child: Text('Type 2'),
                            ),
                            DropdownMenuItem(value: 'CCS', child: Text('CCS')),
                            DropdownMenuItem(
                              value: 'CHAdeMO',
                              child: Text('CHAdeMO'),
                            ),
                          ],
                          onChanged:
                              (value) =>
                                  setState(() => selectedChargerType = value),
                        ),

                        const SizedBox(height: 16),

                        // Power range filter
                        const Text('Power Output Range (kW)'),
                        RangeSlider(
                          values: powerRange ?? const RangeValues(0, 350),
                          min: 0,
                          max: 350,
                          divisions: 35,
                          labels: RangeLabels(
                            (powerRange?.start ?? 0).round().toString(),
                            (powerRange?.end ?? 350).round().toString(),
                          ),
                          onChanged:
                              (values) => setState(() => powerRange = values),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.pop(context, {
                            'isFree': isFreeFilter,
                            'isAvailable': isAvailableFilter,
                            'hasFastCharging': hasFastChargingFilter,
                            'chargerType': selectedChargerType,
                            'powerRange': powerRange,
                          }),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
          ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final stations = await _stationService.getNearbyStations(
          _currentPosition.latitude,
          _currentPosition.longitude,
          _searchRadius,
        );

        // Apply filters
        final filteredStations =
            stations.where((station) {
              if (result['isFree'] != null &&
                  station.rate > 0 != result['isFree']) {
                return false;
              }

              if (result['isAvailable'] != null &&
                  station.availability != result['isAvailable']) {
                return false;
              }

              if (result['hasFastCharging'] != null &&
                  (station.power >= 50) != result['hasFastCharging']) {
                return false;
              }

              if (result['chargerType'] != null &&
                  station.chargerType != result['chargerType']) {
                return false;
              }

              if (result['powerRange'] != null) {
                final range = result['powerRange'] as RangeValues;
                if (station.power < range.start || station.power > range.end) {
                  return false;
                }
              }

              return true;
            }).toList();

        setState(() {
          _markers.clear();
          // Usar _createStationMarker para agregar marcadores filtrados
          for (final station in filteredStations) {
            _markers.add(_createStationMarker(station: station));
          }
        });

        _showMessage(
          'Found ${filteredStations.length} stations matching filters',
        );
      } catch (e) {
        _showError('Error applying filters: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showTripPlanner() async {
    final vehicleService = VehicleService();
    Vehicle? selectedVehicle;
    String? selectedChargerType;
    final latController = TextEditingController();
    final lngController = TextEditingController();

    // Pre-fetch vehicles
    List<Vehicle> vehicles = [];
    try {
      vehicles = await vehicleService.fetchCatalog();
    } catch (e) {
      _showError('Error loading vehicles: $e');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              // controllers ya declarados fuera
              return AlertDialog(
                title: const Text('Plan Your Trip'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Destinos de prueba:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag),
                        title: const Text('San José Centro'),
                        subtitle: const Text('9.933333, -84.083333'),
                        onTap: () {
                          latController.text = '9.933333';
                          lngController.text = '-84.083333';
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag),
                        title: const Text('Liberia'),
                        subtitle: const Text('10.634600, -85.440000'),
                        onTap: () {
                          latController.text = '10.634600';
                          lngController.text = '-85.440000';
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag),
                        title: const Text('Puntarenas'),
                        subtitle: const Text('9.976273, -84.823031'),
                        onTap: () {
                          latController.text = '9.976273';
                          lngController.text = '-84.823031';
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag),
                        title: const Text('Heredia Centro'),
                        subtitle: const Text('9.998689, -84.117824'),
                        onTap: () {
                          latController.text = '9.998689';
                          lngController.text = '-84.117824';
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag),
                        title: const Text('Cartago Centro'),
                        subtitle: const Text('9.863540, -83.919236'),
                        onTap: () {
                          latController.text = '9.863540';
                          lngController.text = '-83.919236';
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text('From'),
                        subtitle: Text(
                          '${_currentPosition.latitude}, ${_currentPosition.longitude}',
                        ),
                      ),
                      const Divider(),
                      TextField(
                        controller: latController,
                        decoration: const InputDecoration(
                          labelText: 'Destination Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: lngController,
                        decoration: const InputDecoration(
                          labelText: 'Destination Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Vehicle>(
                        decoration: const InputDecoration(
                          labelText: 'Select Vehicle',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedVehicle,
                        items:
                            vehicles.map((vehicle) {
                              return DropdownMenuItem(
                                value: vehicle,
                                child: Text(
                                  '${vehicle.marca} ${vehicle.modelo} - ${vehicle.autonomia}km',
                                ),
                              );
                            }).toList(),
                        onChanged: (value) => selectedVehicle = value,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(
                          labelText: 'Charger Type (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedChargerType,
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All Types'),
                          ),
                          DropdownMenuItem(
                            value: 'Type 1',
                            child: Text('Type 1'),
                          ),
                          DropdownMenuItem(
                            value: 'Type 2',
                            child: Text('Type 2'),
                          ),
                          DropdownMenuItem(value: 'CCS', child: Text('CCS')),
                          DropdownMenuItem(
                            value: 'CHAdeMO',
                            child: Text('CHAdeMO'),
                          ),
                        ],
                        onChanged: (value) => selectedChargerType = value,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final lat = double.tryParse(latController.text);
                      final lng = double.tryParse(lngController.text);
                      if (selectedVehicle == null ||
                          lat == null ||
                          lng == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select a vehicle and enter valid coordinates',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'destination': LatLng(lat, lng),
                        'range': selectedVehicle!.autonomia,
                        'chargerType': selectedChargerType,
                      });
                    },
                    child: const Text('Plan Route'),
                  ),
                ],
              );
            },
          ),
    );

    if (result != null &&
        result['destination'] != null &&
        result['range'] != null) {
      await _planRouteWithStops(result);
    }
  }

  Future<void> _planRouteWithStops(Map<String, dynamic> routeData) async {
  setState(() => _isLoading = true);
  try {
    _markers.clear();
    _routes.clear();

    final routePointsFull = await _googleMapsService.getDirections(
      _currentPosition,
      routeData['destination'] as LatLng,
    );
    final autonomia = routeData['range'] as double;
    final stations = await _stationService.getNearbyStations(
      _currentPosition.latitude,
      _currentPosition.longitude,
      100.0,
    );
    final filtered = routeData['chargerType'] != null
        ? stations.where((s) => s.chargerType == routeData['chargerType']).toList()
        : stations;
    final stops = _calculateStopsByAutonomy(routePointsFull, autonomia, filtered);

    final routeWithStops = await _googleMapsService.getDirections(
      _currentPosition,
      routeData['destination'] as LatLng,
      waypoints: stops
          .map((s) => LatLng(s.latitude, s.longitude))
          .toList(),
    );

    setState(() {
      _routes.add(Polyline(
        polylineId: const PolylineId('planned_route'),
        points: routeWithStops,
        color: Colors.blue,
        width: 5,
      ));

      for (final stop in stops) {
        _markers.add(_createStationMarker(station: stop));
      }

      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: routeData['destination'] as LatLng,
        infoWindow: const InfoWindow(title: 'Destino'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    });

    if (stops.isEmpty) {
      _showMessage('No se requieren paradas intermedias. Puedes llegar directo.');
    } else {
      _showMessage('Se requieren ${stops.length} paradas intermedias.');
    }
  } catch (e) {
    _showError('Error planning route: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

  /// Recorre la lista de puntos de la ruta y calcula paradas cada [autonomy] km,
  /// interpolando sobre la polilínea y eligiendo el cargador más cercano.
  List<ChargingStation> _calculateStopsByAutonomy(
    List<LatLng> route,
    double autonomyKm,
    List<ChargingStation> stations,
  ) {
    // 1) Construir lista de tramos con distancias
    List<double> cumulative = [0.0];
    for (var i = 0; i < route.length - 1; i++) {
      final seg =
          Geolocator.distanceBetween(
            route[i].latitude,
            route[i].longitude,
            route[i + 1].latitude,
            route[i + 1].longitude,
          ) /
          1000.0; // km
      cumulative.add(cumulative.last + seg);
    }
    final total = cumulative.last;

    // 2) Para cada múltiplo de autonomía < total, interpolar punto
    List<LatLng> targets = [];
    for (double d = autonomyKm; d < total; d += autonomyKm) {
      // Encontrar tramo donde cumulative[j] < d <= cumulative[j+1]
      for (var j = 0; j < cumulative.length - 1; j++) {
        if (cumulative[j] <= d && d <= cumulative[j + 1]) {
          final ratio =
              (d - cumulative[j]) / (cumulative[j + 1] - cumulative[j]);
          final lat =
              route[j].latitude +
              (route[j + 1].latitude - route[j].latitude) * ratio;
          final lng =
              route[j].longitude +
              (route[j + 1].longitude - route[j].longitude) * ratio;
          targets.add(LatLng(lat, lng));
          break;
        }
      }
    }

    // 3) Para cada punto objetivo, buscar estación más cercana
    List<ChargingStation> stops = [];
    for (final t in targets) {
      ChargingStation? best;
      double bestDist = double.infinity;
      for (final s in stations) {
        final dist = Geolocator.distanceBetween(
          t.latitude,
          t.longitude,
          s.latitude,
          s.longitude,
        );
        if (dist < bestDist) {
          bestDist = dist;
          best = s;
        }
      }
      if (best != null) {
        // Evitar duplicados consecutivos
        if (stops.isEmpty || stops.last.id != best.id) {
          stops.add(best);
        }
      }
    }
    return stops;
  }

  double _getMarkerHue(double deviationScore) {
    // Verde para desviación baja, amarillo para media, rojo para alta
    if (deviationScore < 1.1) return BitmapDescriptor.hueGreen;
    if (deviationScore < 1.3) return BitmapDescriptor.hueYellow;
    return BitmapDescriptor.hueRed;
  }

  Future<void> _loadNearbyChargers() async {
    setState(() => _isLoading = true);
    try {
      _routes.clear();
      await _loadApiChargingStations();
    } catch (e) {
      if (!mounted) return;
      _showError('Error loading charging stations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadApiChargingStations() async {
    final stations = await _stationService.getNearbyStations(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _searchRadius,
    );

    if (!mounted) return;

    setState(() {
      _markers.clear();
      for (final station in stations) {
        _markers.add(_createStationMarker(station: station));
      }
    });
  }

  Future<void> _onMarkerTapped(LatLng destination) async {
    try {
      final points = await _googleMapsService.getDirections(
        _currentPosition,
        destination,
      );

      setState(() {
        _selectedRoute = Polyline(
          polylineId: const PolylineId('selected_route'),
          points: points,
          color: Colors.blue,
          width: 5,
        );
        _routes.clear();
        _routes.add(_selectedRoute!);
      });
    } catch (e) {
      _showError('Error calculating route: $e');
    }
  }

  Future<void> _findOptimalRoute() async {
    setState(() => _isLoading = true);
    try {
      // Obtener todas las estaciones cercanas
      final stations = await _stationService.getNearbyStations(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _searchRadius,
      );

      if (stations.isEmpty) {
        _showError('No charging stations found nearby');
        return;
      }

      // Encontrar la estación más cercana
      var nearestStation = stations.reduce((curr, next) {
        double currDist = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          curr.latitude,
          curr.longitude,
        );

        double nextDist = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          next.latitude,
          next.longitude,
        );

        return currDist < nextDist ? curr : next;
      });

      // Obtener la ruta hacia la estación más cercana
      final route = await _googleMapsService.getDirections(
        _currentPosition,
        LatLng(nearestStation.latitude, nearestStation.longitude),
      );

      setState(() {
        _routes.clear();
        _routes.add(
          Polyline(
            polylineId: const PolylineId('optimal_route'),
            points: route,
            color: Colors.green,
            width: 5,
          ),
        );

        // Agregar marcador de la estación más cercana
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId('nearest_${nearestStation.id}'),
            position: LatLng(nearestStation.latitude, nearestStation.longitude),
            infoWindow: InfoWindow(
              title: nearestStation.name,
              snippet: 'Nearest charging station',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      });
    } catch (e) {
      _showError('Error finding optimal route: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Función para crear un marcador para una estación de carga
  Marker _createStationMarker({
    required ChargingStation station,
    String? customTitle,
    String? customSnippet,
    BitmapDescriptor? customIcon,
    Function()? onTap,
    double? deviationScore,
  }) {
    final position = LatLng(station.latitude, station.longitude);

    // Determinar el color del marcador según disponibilidad o desviación
    BitmapDescriptor icon =
        customIcon ??
        BitmapDescriptor.defaultMarkerWithHue(
          deviationScore != null
              ? _getMarkerHue(deviationScore)
              : (station.availability
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed),
        );

    // Construir el snippet con la información de la estación
    final snippet =
        customSnippet ??
        '''
Tipo: ${station.chargerType}
Potencia: ${station.power}kW
Tarifa: \$${station.rate}/kWh
${deviationScore != null
            ? 'Desviación: ${(deviationScore * 100 - 100).toStringAsFixed(1)}%'
            : station.availability
            ? 'Disponible: Sí'
            : 'Disponible: No'}
''';

    return Marker(
      markerId: MarkerId('station_${station.id}'),
      position: position,
      infoWindow: InfoWindow(
        title: customTitle ?? station.name,
        snippet: snippet,
      ),
      icon: icon,
      onTap:
          onTap ??
          () {
            _onMarkerTapped(position);
            // Almacenar la estación seleccionada y mostrar el panel de detalle
            setState(() {
              _selectedStation = station;
              _showStationDetails = true;
            });
          },
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureButton(Icons.ev_station, 'Chargers'),
              _buildFeatureButton(Icons.route, 'Routes'),
              _buildFeatureButton(Icons.filter_list, 'Filters'),
              _buildFeatureButton(Icons.map, 'Trip'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton(IconData icon, String label) {
    final isActive = _currentFeature == label;
    return InkWell(
      onTap: () => toggleMapFeature(label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor:
                isActive ? Colors.green.shade700 : Colors.grey.shade300,
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: _currentPosition,
            zoom: 15.0,
          ),
          markers: _markers,
          polylines: _routes,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
        ),
        _buildMapControls(),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _getCurrentLocation,
            backgroundColor: Colors.green.shade700,
            child: const Icon(Icons.my_location),
          ),
        ),

        // Panel de detalles de la estación
        if (_showStationDetails && _selectedStation != null)
          _buildStationDetailsPanel(),
      ],
    );
  }

  // Widget para mostrar los detalles completos de la estación
  Widget _buildStationDetailsPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _selectedStation!.availability
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedStation!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed:
                        () => setState(() => _showStationDetails = false),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Dirección:', _selectedStation!.address),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Estado:',
                    _selectedStation!.availability
                        ? 'Disponible ✅'
                        : 'No disponible ❌',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Tipo de conector:',
                    _selectedStation!.chargerType,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Potencia:', '${_selectedStation!.power} kW'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Tarifa:', '\$${_selectedStation!.rate}/kWh'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper para crear filas de detalle consistentes
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}
