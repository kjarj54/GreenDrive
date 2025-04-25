import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:greendrive/services/auth_services.dart';
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

  @override
  void initState() {
    super.initState();
    _stationService = ChargingStationService(AuthService());
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      _showMessage('Searching for nearby charging stations...');
      
      final stations = await _stationService.getNearbyStations(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _searchRadius
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
                snippet: '${station.chargerType} - ${station.power}kW - \$${station.rate}/kWh',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                station.availability ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed
              ),
            ),
          );
        }
      });

      if (stations.isEmpty) {
        _showMessage('No charging stations found nearby');
      } else {
        _showMessage('Found ${stations.length} charging stations');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error loading charging stations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _findOptimalRoute() async {
    // TODO: Implementar búsqueda de ruta óptima
    setState(() {
      _routes.clear();
      // Agregar polylines para la ruta
    });
  }

  Future<void> _loadCommunityMarkers() async {
    // TODO: Implementar carga de marcadores de la comunidad
    setState(() {
      _markers.clear();
      // Agregar marcadores de la comunidad
    });
  }

  void _showStatsOverlay() {
    // TODO: Implementar overlay de estadísticas
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
            backgroundColor: isActive ? Colors.green.shade700 : Colors.grey.shade300,
            child: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade700),
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
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
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
