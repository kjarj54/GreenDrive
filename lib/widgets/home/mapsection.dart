import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
  LatLng _currentPosition = const LatLng(9.9281, -84.0907);
  final Set<Marker> _markers = {};
  final Set<Polyline> _routes = {};
  String _currentFeature = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition));
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void toggleMapFeature(String feature) {
    setState(() {
      _currentFeature = _currentFeature == feature ? '' : feature;
    });

    switch (feature) {
      case 'Chargers':
        _loadNearbyChargers();
        break;
      case 'Routes':
        _findOptimalRoute();
        break;
      case 'Community':
        _loadCommunityMarkers();
        break;
      case 'Stats':
        _showStatsOverlay();
        break;
    }
  }

  Future<void> _loadNearbyChargers() async {
    // TODO: Implementar llamada a la API para cargar estaciones cercanas
    setState(() {
      _markers.clear();
      // Agregar marcadores de estaciones de carga
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
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
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
