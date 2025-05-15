import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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
}
