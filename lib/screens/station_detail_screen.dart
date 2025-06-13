import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/station.dart';
import '../model/rating.dart';
import '../services/rating_service.dart';
import '../services/auth_services.dart';
import '../services/station_service.dart';
import '../providers/user_provider.dart';
import 'package:intl/intl.dart';

class StationDetailScreen extends StatefulWidget {
  final ChargingStation station;

  const StationDetailScreen({super.key, required this.station});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  final AuthService _authService = AuthService();
  late final RatingService _ratingService;
  late final ChargingStationService _stationService;
  List<StationRating> _ratings = [];
  bool _isLoading = false;
  bool _ratingsLoaded = false;
  String _error = '';
  int _userRating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;
  
  // Estado para la estación actualizada
  ChargingStation? _updatedStation;

  @override
  void initState() {
    super.initState();
    _ratingService = RatingService(_authService);
    _stationService = ChargingStationService(_authService);
    // No cargar las reseñas automáticamente
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }  Future<void> _loadRatings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final ratings = await _ratingService.getRatingsByStation(widget.station.id);
      if (mounted) {
        setState(() {
          _ratings = ratings;
          _isLoading = false;
          _ratingsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load ratings: $e';
          _isLoading = false;
        });
      }
    }
  }
  Future<void> _loadRatingsIfNeeded() async {
    if (_ratingsLoaded) return; // No recargar si ya están cargadas
    await _loadRatings();
  }  double _calculateAverageRating() {
    // Siempre usar la calificación de la estación que viene del backend
    // El backend ya calcula el promedio correctamente incluyendo todas las calificaciones
    return currentStation.rating;
  }
  int _getRatingCount() {
    // Siempre usar el conteo de la estación que viene del backend
    // El backend ya cuenta correctamente todas las calificaciones
    return currentStation.reviewCount;
  }
  // Función para recargar la información de la estación
  Future<void> _refreshStationInfo() async {
    try {
      // Obtener todas las estaciones y buscar la actualizada
      final stations = await _stationService.getNearbyStations(
        widget.station.latitude, 
        widget.station.longitude, 
        0.1
      );
      
      final updatedStation = stations.firstWhere(
        (s) => s.id == widget.station.id,
        orElse: () => widget.station,
      );
      
      // Verificar si el widget sigue montado antes de llamar setState
      if (mounted) {
        setState(() {
          _updatedStation = updatedStation;
        });
      }
    } catch (e) {
      print('Error refreshing station info: $e');
      // Si hay error, mantener la información original
    }
  }

  // Getter para obtener la estación actual (actualizada o original)
  ChargingStation get currentStation => _updatedStation ?? widget.station;Future<void> _submitRating(int userId) async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() => _submitting = true);    try {
      await _ratingService.addRating(
        userId,
        widget.station.id,
        _userRating,
        _commentController.text.isEmpty ? null : _commentController.text,
      );

      _commentController.clear();
      
      // Verificar si el widget sigue montado antes de llamar setState
      if (mounted) {
        setState(() {
          _userRating = 0;
          _submitting = false;
        });
      }

      // Recargar las calificaciones para mostrar la nueva
      _loadRatings();
      
      // Actualizar la información de la estación con el nuevo promedio
      await _refreshStationInfo();
      
      // Solo navegar y mostrar snackbar si el widget sigue montado
      if (mounted) {
        // Notificar al padre que la estación ha sido actualizada
        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit rating: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.isLoggedIn;
    final userId = userProvider.userId;

    return Scaffold(
      appBar: AppBar(title: Text(widget.station.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la estación
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.station.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.station.address,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        Icons.electric_bolt,
                        '${widget.station.power} kW',
                        'Power',
                      ),
                      _buildInfoItem(
                        Icons.ev_station,
                        widget.station.chargerType,
                        'Type',
                      ),
                      _buildInfoItem(
                        Icons.attach_money,
                        '\$${widget.station.rate.toStringAsFixed(2)}',
                        'Rate',
                      ),
                      _buildInfoItem(
                        widget.station.availability
                            ? Icons.check_circle
                            : Icons.cancel,
                        widget.station.availability
                            ? 'Available'
                            : 'Unavailable',
                        'Status',
                        color:
                            widget.station.availability
                                ? Colors.green
                                : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hours: ${widget.station.schedule}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),                      Text(
                        '${_calculateAverageRating().toStringAsFixed(1)} (${_getRatingCount()} reviews)',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sección de calificación
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rate this station',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _userRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 36,
                              ),
                              onPressed: () {
                                setState(() {
                                  _userRating = index + 1;
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment (optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _submitting
                                    ? null
                                    : () => _submitRating(userId ?? 0),
                            child:
                                _submitting
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text('Submit Rating'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),            // Lista de reseñas con carga lazy
            Padding(
              padding: const EdgeInsets.all(16),
              child: ExpansionTile(
                title: const Text(
                  'Reviews',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${_getRatingCount()} reviews'),                onExpansionChanged: (expanded) {
                  if (expanded && !_ratingsLoaded) {
                    _loadRatingsIfNeeded();
                  }
                },
                children: [
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error.isNotEmpty)
                    Center(
                      child: Column(
                        children: [
                          Text(_error),                          ElevatedButton(
                            onPressed: () {
                              setState(() => _ratingsLoaded = false);
                              _loadRatingsIfNeeded();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_ratings.isEmpty && _ratingsLoaded)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No reviews yet. Be the first to review!'),
                      ),
                    )                  else
                    Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _ratings.length,
                          itemBuilder: (context, index) {
                            final rating = _ratings[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          rating.username ?? 'Anonymous',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          DateFormat(
                                            'MMM d, yyyy',
                                          ).format(rating.date),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < rating.rating
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 18,
                                        );
                                      }),
                                    ),
                                    if (rating.comment != null) ...[
                                      const SizedBox(height: 8),
                                      Text(rating.comment!),
                                    ],

                                    // Opción de eliminar si el usuario es el autor
                                    if (userId == rating.userId)
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: TextButton(
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: const Text(
                                                      'Delete Review',
                                                    ),
                                                    content: const Text(
                                                      'Are you sure you want to delete your review?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );                                            if (confirm == true) {
                                              try {
                                                await _ratingService.deleteRating(
                                                  rating.id,
                                                );

                                                // Verificar si el widget sigue montado antes de llamar setState
                                                if (mounted) {
                                                  setState(() => _ratingsLoaded = false);
                                                }
                                                await _loadRatings();
                                                
                                                // Actualizar la información de la estación con el nuevo promedio
                                                await _refreshStationInfo();
                                                
                                                // Solo navegar si el widget sigue montado
                                                if (mounted) {
                                                  // Notificar al padre que la estación ha sido actualizada
                                                  Navigator.of(context).pop(true);
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Failed to delete review: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ),                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String text,
    String label, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
