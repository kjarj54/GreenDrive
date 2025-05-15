import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;


typedef TZDateTime = tz.TZDateTime;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // Inicializa el plugin de notificaciones
  static Future<void> init() async {
    if (_isInitialized) return;

    // For Android 13+ (API level 33+)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    // Use the correct method to request permission
    await androidImplementation?.requestNotificationsPermission();

    // Also request permission using permission_handler for better compatibility
    await Permission.notification.request();

    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración general
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar tap en notificación
        print('Notification clicked: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  // Mostrar una notificación nativa
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'greendrive_social',
          'Social Notifications',
          channelDescription:
              'Notificaciones de actividad social en GreenDrive',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          color: Color(0xFF2E7D32), // Verde oscuro
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond, // ID único
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Mostrar un SnackBar en la app
  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static Future<void> sendChargingReminder({
    required String destination,
    required double distanceKm,
    required DateTime tripDate,
  }) async {
    final title = 'Recordatorio de carga';
    final body =
        'Recuerda cargar tu vehículo antes de tu viaje a $destination '
        '(${distanceKm.toStringAsFixed(1)} km) programado para ${_formatDate(tripDate)}.';

    await showNotification(
      title: title,
      body: body,
      payload: 'charging_reminder:$destination',
    );
  }

  // Método para notificar sobre nuevas estaciones en la región
  static Future<void> sendNewStationAlert({
    required String stationName,
    required String address,
    required int stationId,
  }) async {
    final title = '¡Nueva estación de carga!';
    final body =
        'La estación "$stationName" está ahora disponible en $address.';

    await showNotification(
      title: title,
      body: body,
      payload: 'new_station:$stationId',
    );
  }

  // Método para notificar sobre ofertas y promociones
  static Future<void> sendPromotionAlert({
    required String stationName,
    required String promotionDetails,
    required int stationId,
    required DateTime expirationDate,
  }) async {
    final title = 'Promoción en $stationName';
    final body =
        '$promotionDetails. Válido hasta ${_formatDate(expirationDate)}.';

    await showNotification(
      title: title,
      body: body,
      payload: 'promotion:$stationId',
    );
  }

  // Función auxiliar para formatear fechas
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Método para programar un recordatorio de carga
  static Future<void> scheduleChargingReminder({
    required String destination,
    required double distanceKm,
    required DateTime tripDate,
    required Duration reminderBefore,
  }) async {
    await init();

    final scheduledDate = tripDate.subtract(reminderBefore);
    // Verificar si la fecha programada es en el futuro
    if (scheduledDate.isBefore(DateTime.now())) {
      return; // No programar recordatorios en el pasado
    }

    final androidDetails = AndroidNotificationDetails(
      'greendrive_reminders',
      'Recordatorios de viaje',
      channelDescription: 'Recordatorios para cargar antes de viajes',
      importance: Importance.high,
      priority: Priority.high,
    );

    final platformDetails = NotificationDetails(android: androidDetails);

    final title = 'Recordatorio de carga';
    final body =
        'Recuerda cargar tu vehículo antes de tu viaje a $destination '
        '(${distanceKm.toStringAsFixed(1)} km) programado para ${_formatDate(tripDate)}.';

    await _notificationsPlugin.zonedSchedule(
      tripDate
          .millisecondsSinceEpoch
          .hashCode, // ID único basado en la fecha del viaje
      title,
      body,
      TZDateTime.from(scheduledDate, local),
      platformDetails,
      payload: 'charging_reminder:$destination',
      androidScheduleMode: AndroidScheduleMode.exact,
    );
  }

  // Obtener la zona horaria local
  static final tz.Location local = tz.local;

  // Si necesitas una función para obtener la zona horaria local, puedes dejarla así:
  static tz.Location getLocalTimeZone() {
    return tz.local;
  }
}
