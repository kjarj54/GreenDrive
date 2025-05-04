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
  ChargingStation? _selectedStation; // Propiedad para almacenar la estación seleccionada
  bool _showStationDetails = false; // Controla la visibilidad del panel de detalles

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
          (context) => AlertDialog(
            title: const Text('Plan Your Trip'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      DropdownMenuItem(value: null, child: Text('All Types')),
                      DropdownMenuItem(value: 'Type 1', child: Text('Type 1')),
                      DropdownMenuItem(value: 'Type 2', child: Text('Type 2')),
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

                  if (selectedVehicle == null || lat == null || lng == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select a vehicle and enter destination coordinates',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'destination': LatLng(lat, lng),
                    'range': selectedVehicle?.autonomia,
                    'chargerType': selectedChargerType,
                  });
                },
                child: const Text('Plan Route'),
              ),
            ],
          ),
    );

    if (result != null &&
        result['destination'] != null &&
        result['range'] != null) {
      await _planRouteWithStops(result);
    }
  }

  // Helper method to handle route planning
  Future<void> _planRouteWithStops(Map<String, dynamic> routeData) async {
    setState(() => _isLoading = true);
    try {
      _markers.clear();
      _routes.clear();

      final stations = await _stationService.getNearbyStations(
        _currentPosition.latitude,
        _currentPosition.longitude,
        100.0,
      );

      final filteredStations =
          routeData['chargerType'] != null
              ? stations
                  .where((s) => s.chargerType == routeData['chargerType'])
                  .toList()
              : stations;

      if (filteredStations.isEmpty) {
        _showError('No compatible charging stations found');
        return;
      }

      // Aquí usamos stops reales, no potentialStops
      final stops = _calculateChargingStops(
        _currentPosition,
        routeData['destination'] as LatLng,
        filteredStations,
        routeData['range'] as double,
      );

      final routePoints = await _googleMapsService.getDirections(
        _currentPosition,
        routeData['destination'] as LatLng,
      );

      setState(() {
        _routes.clear();
        _routes.add(
          Polyline(
            polylineId: const PolylineId('planned_route'),
            points: routePoints,
            color: Colors.blue,
            width: 5,
          ),
        );

        _markers.clear();
        // Usar _createStationMarker para cada parada
        for (final stop in stops) {
          double deviationScore = _calculateDeviationScore(
            _currentPosition,
            LatLng(stop.latitude, stop.longitude),
            routeData['destination'] as LatLng,
          );

          _markers.add(_createStationMarker(
            station: stop,
            deviationScore: deviationScore,
          ));
        }
        
        // Añadir el marcador de destino
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: routeData['destination'] as LatLng,
            infoWindow: const InfoWindow(title: 'Destino'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      });

      if (stops.isEmpty) {
        _showMessage(
          'No se requieren paradas intermedias. Puedes llegar directo al destino.',
        );
      } else {
        _showMessage(
          'Se requieren ${stops.length} paradas intermedias para llegar al destino.',
        );
      }
    } catch (e) {
      _showError('Error planning route: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _getMarkerHue(double deviationScore) {
    // Verde para desviación baja, amarillo para media, rojo para alta
    if (deviationScore < 1.1) return BitmapDescriptor.hueGreen;
    if (deviationScore < 1.3) return BitmapDescriptor.hueYellow;
    return BitmapDescriptor.hueRed;
  }

  List<ChargingStation> _calculateChargingStops(
    LatLng start,
    LatLng end,
    List<ChargingStation> stations,
    double vehicleRange,
  ) {
    List<ChargingStation> stops = [];
    List<ChargingStation> potentialStops = [];
    double remainingRange = vehicleRange;
    LatLng currentPosition = start;
    double searchRadiusKm = 20.0;
    const int maxPotentialStops = 10;
    const int maxIterations = 20;
    const double maxSearchRadiusKm = 60.0;
    int iterations = 0;

    while (iterations < maxIterations) {
      iterations++;

      double distanceToEnd =
          Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            end.latitude,
            end.longitude,
          ) /
          1000;

      if (distanceToEnd <= remainingRange) break;

      double optimalStopDistance = remainingRange * 0.7;
      double ratio = optimalStopDistance / distanceToEnd;

      LatLng idealPoint = LatLng(
        currentPosition.latitude +
            (end.latitude - currentPosition.latitude) * ratio,
        currentPosition.longitude +
            (end.longitude - currentPosition.longitude) * ratio,
      );

      List<ChargingStation> nearbyStations =
          stations.where((station) {
            double distanceToStation =
                Geolocator.distanceBetween(
                  idealPoint.latitude,
                  idealPoint.longitude,
                  station.latitude,
                  station.longitude,
                ) /
                1000;
            return distanceToStation <= searchRadiusKm;
          }).toList();

      if (nearbyStations.isEmpty) {
        if (searchRadiusKm < maxSearchRadiusKm) {
          searchRadiusKm *= 2;
        } else {
          break;
        }
        continue;
      }

      nearbyStations.sort((a, b) {
        double scoreA = _calculateDeviationScore(
          currentPosition,
          LatLng(a.latitude, a.longitude),
          end,
        );
        double scoreB = _calculateDeviationScore(
          currentPosition,
          LatLng(b.latitude, b.longitude),
          end,
        );
        return scoreA.compareTo(scoreB);
      });

      potentialStops.addAll(nearbyStations.take(maxPotentialStops));

      ChargingStation bestStation = nearbyStations.first;
      stops.add(bestStation);

      currentPosition = LatLng(bestStation.latitude, bestStation.longitude);
      remainingRange = vehicleRange;
      searchRadiusKm = 20.0;
    }

    return stops;
  }

  double _calculateDeviationScore(LatLng start, LatLng station, LatLng end) {
    // Calculate direct distance from start to end
    double directDistance = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    // Calculate distance through the station
    double distanceThroughStation =
        Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          station.latitude,
          station.longitude,
        ) +
        Geolocator.distanceBetween(
          station.latitude,
          station.longitude,
          end.latitude,
          end.longitude,
        );

    // Return deviation score (ratio of actual path to direct path)
    return distanceThroughStation / directDistance;
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
    BitmapDescriptor icon = customIcon ?? 
      BitmapDescriptor.defaultMarkerWithHue(
        deviationScore != null 
          ? _getMarkerHue(deviationScore)
          : (station.availability 
              ? BitmapDescriptor.hueGreen 
              : BitmapDescriptor.hueRed)
      );
    
    // Construir el snippet con la información de la estación
    final snippet = customSnippet ?? '''
Tipo: ${station.chargerType}
Potencia: ${station.power}kW
Tarifa: \$${station.rate}/kWh
${deviationScore != null ? 'Desviación: ${(deviationScore * 100 - 100).toStringAsFixed(1)}%' : 
  station.availability ? 'Disponible: Sí' : 'Disponible: No'}
''';

    return Marker(
      markerId: MarkerId('station_${station.id}'),
      position: position,
      infoWindow: InfoWindow(
        title: customTitle ?? station.name,
        snippet: snippet,
      ),
      icon: icon,
      onTap: onTap ?? () {
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
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedStation!.availability 
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
                    onPressed: () => setState(() => _showStationDetails = false),
                  )
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
                  _buildDetailRow('Estado:', _selectedStation!.availability 
                      ? 'Disponible ✅' 
                      : 'No disponible ❌'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Tipo de conector:', _selectedStation!.chargerType),
                  const SizedBox(height: 12),
                  _buildDetailRow('Potencia:', '${_selectedStation!.power} kW'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Tarifa:', '\$${_selectedStation!.rate}/kWh'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Aquí se podría implementar la funcionalidad para iniciar navegación
                      final destLatLng = LatLng(_selectedStation!.latitude, _selectedStation!.longitude);
                      _onMarkerTapped(destLatLng);
                      // Opcional: cerrar panel después de iniciar navegación
                      // setState(() => _showStationDetails = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.directions),
                    label: const Text('Iniciar navegación'),
                  ),
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
