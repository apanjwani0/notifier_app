import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

// The callback function should always be a top-level function.

void startCallback() {
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class PermissionManager extends StatefulWidget {
  const PermissionManager({super.key});

  @override
  PermissionManagerState createState() => PermissionManagerState();
}

class PermissionManagerState extends State<PermissionManager> {
  ReceivePort? _receivePort;

  Future<void> _initForegroundTask() async {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'testButton', text: 'Test'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
      printDevLog: true,
    );
  }

 Future<bool> _startForegroundTask() async {
    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    ReceivePort? receivePort;
    if (await FlutterForegroundTask.isRunningService) {
      receivePort = await FlutterForegroundTask.restartService();
    } else {
      receivePort = await FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }

    if (receivePort != null) {
      _receivePort = receivePort;
      _receivePort?.listen((message) {
        log("$message");

        log("message recieved: $message");
        if (message is DateTime) {
          log('receive timestamp: $message');
        } else if (message is int) {
          log('receive updateCount: $message');
        }
      });

      return true;
    }

    return false;
  }


  Future<bool> _stopForegroundTask() async {
    return await FlutterForegroundTask.stopService();
  }

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
  }

  @override
  void dispose() {
    _receivePort?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WithForegroundTask(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Foreground Task'),
            centerTitle: true,
          ),
          body: _buildContentView(),
        ),
      ),
    );
  }

  Widget _buildContentView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTestButton('request Permission', onPressed: () async {
            await NotificationListenerService.requestPermission();
          }),
          _buildTestButton('start listening', onPressed: _startForegroundTask),
          _buildTestButton('stop', onPressed: _stopForegroundTask),
        ],
      ),
    );
  }

  Widget _buildTestButton(String text, {VoidCallback? onPressed}) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        child: Text(text),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(primary: const Color(0xFF587C8F)),
      ),
    );
  }


  List<Map<String, dynamic>> permissions = [
    {
      'name': 'Notification Access',
      'info': 'To interact with notifications',
      'granted': false,
      'platform': PlatformType.android, // Only applicable for Android
    },
    {
      'name': 'Overlay Access',
      'info': 'To interact with other apps',
      'granted': false,
      'platform': PlatformType.android, // Only applicable for Android
    },
    {
      'name': 'App List Access',
      'info': 'To list all apps',
      'granted': true, // No specific permission required for this
      'platform': PlatformType.both,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
    _checkPermissions();
  }

Future<void> _checkPermissions() async {
    // Check Overlay Access
    PermissionStatus overlayStatus = await Permission.systemAlertWindow.status;
    
    // Check if the app has Notification Access (indirectly, as there's no direct way using a package for this)
    bool hasNotificationAccess = await NotificationListenerService.hasPermission();

    // Check for Background run access (no direct way in Flutter, usually granted by default but can be restricted by user or certain OEMs)
    // For this demo, we'll assume true. You might need a platform-specific method to check this in native Android code.

    // Update permissions
    setState(() {
      permissions[0]['granted'] = hasNotificationAccess;
      permissions[1]['granted'] = overlayStatus.isGranted;
      permissions[2]['granted'] = true;  // For the demo, assuming background access is granted.
    });
}


  Future<void> _requestOverlayPermission() async {
    PermissionStatus overlayStatus =
        await Permission.systemAlertWindow.request();
    setState(() {
      permissions[1]['granted'] = overlayStatus.isGranted;
    });
  }

  Future<void> _openNotificationAccessSettings() async {
    if (Platform.isAndroid) {
      await launch('android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Permission Manager")),
      body: ListView.builder(
        itemCount: permissions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(permissions[index]['name']),
            subtitle: Text(permissions[index]['info']),
            trailing: permissions[index]['granted']
                ? const Icon(Icons.check, color: Colors.green)
                : const Icon(Icons.warning, color: Colors.red),
            onTap: () {
              if (index == 0) {
                _openNotificationAccessSettings();
              } else if (index == 1) {
                _requestOverlayPermission();
              }
              // App List Access doesn't require a specific action
            },
          );
        },
      ),
    );
  }
}

enum PlatformType { android, ios, both }
