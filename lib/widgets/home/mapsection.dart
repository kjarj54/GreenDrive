import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:greendrive/model/station.dart';
import 'package:greendrive/services/auth_services.dart';
import 'package:greendrive/services/googlemaps_service.dart';
import 'package:greendrive/services/station_service.dart';

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
      case 'Community':
        await _loadCommunityMarkers();
        break;
      case 'Stats':
        _showStatsOverlay();
        break;
    }
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

  Future<void> _loadCommunityMarkers() async {
    setState(() => _isLoading = true);
    try {
      final topStations = await _stationService.getTopRatedStations(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _searchRadius * 2,
      );

      setState(() {
        _markers.clear();
        _routes.clear();

        for (final station in topStations) {
          _markers.add(
            Marker(
              markerId: MarkerId('community_${station.id}'),
              position: LatLng(station.latitude, station.longitude),
              infoWindow: InfoWindow(
                title: '⭐ ${station.name}',
                snippet:
                    'Rating: ${station.rating.toStringAsFixed(1)}/5\n'
                    '${station.reviewCount} reviews\n'
                    '${station.totalCharges} total charges',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                station.rating >= 4.5
                    ? BitmapDescriptor.hueGreen
                    : station.rating >= 4.0
                    ? BitmapDescriptor.hueAzure
                    : BitmapDescriptor.hueYellow,
              ),
            ),
          );
        }
      });

      if (topStations.isEmpty) {
        _showMessage('No highly rated stations found in this area');
      }
    } catch (e) {
      _showError('Error loading community markers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showStatsOverlay() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _stationService.getStationStats(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _searchRadius,
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        builder:
            (context) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Charging Station Statistics',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildStatCard('Coverage Statistics', [
                    _buildStatRow(
                      'Total Stations',
                      '${stats['totalStations']}',
                    ),
                    _buildStatRow(
                      'Available Now',
                      '${stats['availableStations']}',
                    ),
                    _buildStatRow(
                      'Average Rating',
                      '${(stats['avgRating'] as double).toStringAsFixed(1)}/5',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  if (stats['topRated'] != null) ...[
                    _buildStatCard('Top Rated Station', [
                      _buildStatRow(
                        'Name',
                        (stats['topRated'] as ChargingStation).name,
                      ),
                      _buildStatRow(
                        'Rating',
                        '${(stats['topRated'] as ChargingStation).rating}/5',
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  if (stats['mostUsed'] != null) ...[
                    _buildStatCard('Most Used Station', [
                      _buildStatRow(
                        'Name',
                        (stats['mostUsed'] as ChargingStation).name,
                      ),
                      _buildStatRow(
                        'Total Charges',
                        '${(stats['mostUsed'] as ChargingStation).totalCharges}',
                      ),
                    ]),
                  ],
                ],
              ),
            ),
      );
    } catch (e) {
      _showError('Error loading statistics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatCard(String title, List<Widget> stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...stats,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
              _buildFeatureButton(Icons.group, 'Community'),
              _buildFeatureButton(Icons.bar_chart, 'Stats'),
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
