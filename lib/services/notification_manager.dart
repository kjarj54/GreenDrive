import 'package:greendrive/model/station.dart';
import 'package:greendrive/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationManager {
  // Gestionar recordatorios de carga basados en eventos del calendario o planificador de viajes
  static Future<void> setTripReminder({
    required String destination,
    required double distanceKm,
    required DateTime tripDate,
  }) async {
    // Por defecto, recordar el día anterior
    final reminderBefore = const Duration(days: 1);
    
    await NotificationService.scheduleChargingReminder(
      destination: destination,
      distanceKm: distanceKm,
      tripDate: tripDate,
      reminderBefore: reminderBefore,
    );
    
    // Guardar el recordatorio en SharedPreferences para referencia
    await _saveReminderToPrefs(
      destination: destination,
      distanceKm: distanceKm,
      tripDate: tripDate,
      reminderDate: tripDate.subtract(reminderBefore),
    );
  }
  
  // Guardar información del recordatorio en SharedPreferences
  static Future<void> _saveReminderToPrefs({
    required String destination,
    required double distanceKm,
    required DateTime tripDate,
    required DateTime reminderDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = prefs.getStringList('trip_reminders') ?? [];
    
    final reminderData = {
      'destination': destination,
      'distanceKm': distanceKm,
      'tripDate': tripDate.toIso8601String(),
      'reminderDate': reminderDate.toIso8601String(),
    };
    
    reminders.add(jsonEncode(reminderData));
    await prefs.setStringList('trip_reminders', reminders);
  }
  
  // Notificar sobre una nueva estación en la región del usuario
  static Future<void> notifyNewStation(ChargingStation station) async {
    await NotificationService.sendNewStationAlert(
      stationName: station.name,
      address: station.address,
      stationId: station.id,
    );
  }
  
  // Notificar sobre una promoción en una estación de carga
  static Future<void> notifyPromotion({
    required ChargingStation station,
    required String promotionDetails,
    required DateTime expirationDate,
  }) async {
    await NotificationService.sendPromotionAlert(
      stationName: station.name,
      promotionDetails: promotionDetails,
      stationId: station.id,
      expirationDate: expirationDate,
    );
  }
  
  // Obtener todos los recordatorios guardados
  static Future<List<Map<String, dynamic>>> getSavedReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = prefs.getStringList('trip_reminders') ?? [];
    
    return reminders
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }
}