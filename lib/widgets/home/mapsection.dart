import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
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
  Set<Marker> _googleMarkers = {};
  Polyline? _selectedRoute;

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

  // TODO: Implement method to show and handle advanced filters
  // - Free charging stations
  // - Available/Occupied status
  // - Fast charging capabilities
  // - Compatible charging types
  // - Power output ranges
  Future<void> _showAdvancedFilters() async {
    bool? isFreeFilter;
    bool? isAvailableFilter;
    bool? hasFastChargingFilter;
    String? selectedChargerType;
    RangeValues? powerRange;
    _routes.clear();
    _markers.clear();
    _googleMarkers.clear();

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
          for (final station in filteredStations) {
            _markers.add(
              Marker(
                markerId: MarkerId('station_${station.id}'),
                position: LatLng(station.latitude, station.longitude),
                infoWindow: InfoWindow(
                  title: station.name,
                  snippet: '''
Tipo: ${station.chargerType}
Potencia: ${station.power}kW
Tarifa: \$${station.rate}/kWh
Disponible: ${station.availability ? 'Sí' : 'No'}
''',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  station.availability
                      ? BitmapDescriptor.hueGreen
                      : BitmapDescriptor.hueRed,
                ),
              ),
            );
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

  // TODO: Implement method to show trip planner interface
  // - Origin and destination selection
  // - Vehicle range input
  // - Consider vehicle range
  // - Calculate optimal charging stops
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
      _googleMarkers.clear();
      _routes.clear();
      final stations = await _stationService.getNearbyStations(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _searchRadius,
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

      final potentialStops = _calculateChargingStops(
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
        // Agregar marcadores para todas las paradas potenciales
        for (final stop in potentialStops) {
          double deviationScore = _calculateDeviationScore(
            _currentPosition,
            LatLng(stop.latitude, stop.longitude),
            routeData['destination'] as LatLng,
          );

          _markers.add(
            Marker(
              markerId: MarkerId('stop_${stop.id}'),
              position: LatLng(stop.latitude, stop.longitude),
              infoWindow: InfoWindow(
                title: stop.name,
                snippet: '''
Tipo: ${stop.chargerType}
Potencia: ${stop.power}kW
Tarifa: \$${stop.rate}/kWh
Desviación: ${(deviationScore * 100 - 100).toStringAsFixed(1)}%
              ''',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerHue(deviationScore),
              ),
            ),
          );
        }
      });

      _showMessage('Found ${potentialStops.length} potential charging stops');
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
    double searchRadiusKm = 5.0;
    int maxPotentialStops =
        10; // Número máximo de paradas potenciales por punto

    while (true) {
      double distanceToEnd =
          Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            end.latitude,
            end.longitude,
          ) /
          1000;

      if (distanceToEnd <= remainingRange) {
        break;
      }

      double optimalStopDistance = remainingRange * 0.8;
      double ratio = optimalStopDistance / distanceToEnd;
      LatLng idealPoint = LatLng(
        currentPosition.latitude +
            (end.latitude - currentPosition.latitude) * ratio,
        currentPosition.longitude +
            (end.longitude - currentPosition.longitude) * ratio,
      );

      // Encontrar estaciones cercanas al punto ideal
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
        searchRadiusKm *= 1.5;
        continue;
      }

      // Ordenar estaciones por score de desviación
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

      // Tomar las mejores estaciones como paradas potenciales
      potentialStops.addAll(nearbyStations.take(maxPotentialStops));

      // Usar la mejor estación como siguiente parada
      ChargingStation bestStation = nearbyStations.first;
      stops.add(bestStation);

      currentPosition = LatLng(bestStation.latitude, bestStation.longitude);
      remainingRange = vehicleRange;
      searchRadiusKm = 5.0;
    }

    return potentialStops; // Retornar todas las paradas potenciales
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
      await Future.wait([
        _loadGoogleChargingStations(),
        _loadApiChargingStations(),
      ]);
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
        _markers.add(
          Marker(
            markerId: MarkerId('station_${station.id}'),
            position: LatLng(station.latitude, station.longitude),
            infoWindow: InfoWindow(
              title: station.name,
              snippet:
                  '${station.chargerType} - ${station.power}kW - \$${station.rate}/kWh',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              station.availability
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
            onTap:
                () => _onMarkerTapped(
                  LatLng(station.latitude, station.longitude),
                ),
          ),
        );
      }
    });
  }

  Future<void> _loadGoogleChargingStations() async {
    try {
      final stations = await _googleMapsService.getNearbyChargingStations(
        _currentPosition,
        _searchRadius * 1000, // Convert km to meters
      );

      setState(() {
        _googleMarkers.clear();
        for (final station in stations) {
          _googleMarkers.add(
            Marker(
              markerId: MarkerId('google_${station.placeId}'),
              position: LatLng(
                station.geometry!.location.lat,
                station.geometry!.location.lng,
              ),
              infoWindow: InfoWindow(
                title: station.name,
                snippet: station.vicinity,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              onTap:
                  () => _onMarkerTapped(
                    LatLng(
                      station.geometry!.location.lat,
                      station.geometry!.location.lng,
                    ),
                  ),
            ),
          );
        }
      });
    } catch (e) {
      _showError('Error loading Google charging stations: $e');
    }
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
          markers: _markers.union(_googleMarkers),
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
      ],
    );
  }
}
