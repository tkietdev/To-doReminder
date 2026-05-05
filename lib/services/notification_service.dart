import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Khởi tạo notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('✅ Notification Service initialized');
  }

  // Xử lý khi tap vào notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to task detail
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  // Schedule notifications cho một task
  Future<void> scheduleTaskNotifications(Task task) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    final deadline = task.deadline;

    // Không schedule nếu task đã hoàn thành hoặc quá hạn
    if (task.isCompleted || deadline.isBefore(now)) {
      return;
    }

    // Cancel notifications cũ của task này
    await cancelTaskNotifications(task.id);

    // Danh sách các mốc thời gian thông báo
    final notifications = <Map<String, dynamic>>[
      {
        'minutes': 1440, // 1 ngày = 1440 phút
        'title': '📅 Công việc sắp đến hạn',
        'body': '${task.title} sẽ đến hạn vào ngày mai',
      },
      {
        'minutes': 60, // 1 giờ
        'title': '⏰ Còn 1 giờ nữa!',
        'body': '${task.title} sẽ đến hạn trong 1 giờ',
      },
      {
        'minutes': 30, // 30 phút
        'title': '⚠️ Còn 30 phút!',
        'body': '${task.title} sắp đến hạn',
      },
      {
        'minutes': 1, // 1 phút
        'title': '🚨 GẤP! Còn 1 phút!',
        'body': '${task.title} sắp hết hạn',
      },
    ];

    // Schedule từng notification
    for (int i = 0; i < notifications.length; i++) {
      final notif = notifications[i];
      final minutes = notif['minutes'] as int;
      final notificationTime = deadline.subtract(Duration(minutes: minutes));

      // Chỉ schedule nếu thời gian thông báo chưa qua
      if (notificationTime.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(task.id, i),
          title: notif['title'] as String,
          body: notif['body'] as String,
          scheduledTime: notificationTime,
          payload: task.id,
          priority: _getPriority(minutes),
        );

        debugPrint('✅ Scheduled: ${notif['title']} at $notificationTime');
      }
    }
  }

  // Schedule một notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    required Priority priority,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task deadlines',
      importance: Importance.high,
      priority: priority,
      ticker: 'Task Reminder',
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Cancel notifications của một task
  Future<void> cancelTaskNotifications(String taskId) async {
    for (int i = 0; i < 4; i++) {
      await _notifications.cancel(_getNotificationId(taskId, i));
    }
    debugPrint('❌ Cancelled notifications for task: $taskId');
  }

  // Cancel tất cả notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('❌ Cancelled all notifications');
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Show immediate notification (test)
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      channelDescription: 'Instant notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // Generate unique notification ID
  int _getNotificationId(String taskId, int index) {
    return (taskId.hashCode + index).abs() % 2147483647;
  }

  // Get priority dựa vào số phút còn lại
  Priority _getPriority(int minutes) {
    if (minutes <= 1) return Priority.max;
    if (minutes <= 30) return Priority.high;
    if (minutes <= 60) return Priority.defaultPriority;
    return Priority.low;
  }
}