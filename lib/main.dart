import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';


void main() => runApp(const NotifierApp());

class NotifierApp extends StatelessWidget {
  const NotifierApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      title: 'Notifier App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PermissionManager(),
    );
  }
}

class PermissionManager extends StatefulWidget {
  const PermissionManager({Key? key}) : super(key: key);

  @override
  PermissionManagerState createState() => PermissionManagerState();
}

class PermissionManagerState extends State<PermissionManager> {
    static const platform =  MethodChannel('notifier.notifier_app.notification_access');

  // Mock data for permissions
  List<Map<String, dynamic>> permissions = [
    {
      'name': 'Notification Access',
      'info': 'To interact with notifications',
      'granted': false,
    }, 
    {
      'name': 'Overlay Access',
      'info': 'To interact with other apps',
      'granted': false,
    },
    {
      'name': 'App List Access',
      'info': 'To list all apps',
      'granted': true, // No specific permission required for this
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
  // Check Overlay Access (Display over other apps)
  PermissionStatus overlayStatus = await Permission.systemAlertWindow.status;


  // TODO: Check Notification Access (This needs a custom method since Flutter doesn't provide direct support)
  bool hasNotificationAccess = false; // You'll need to implement a custom method to check this.

  // Background Run Access is not directly checkable. You usually request other permissions 
  // and if granted, the app can run tasks in the background. So, there's no direct check for this.
  bool hasBackgroundAccess = true;  // Assuming you have other required permissions

try {
    final bool result = await platform.invokeMethod('hasNotificationAccess');
    hasNotificationAccess = result;
  } on PlatformException catch (e) {
    print("Failed to get notification access: '${e.message}'.");
  }
  
  setState(() {
    permissions[0]['granted'] = hasNotificationAccess;
    permissions[1]['granted'] = overlayStatus.isGranted;
    permissions[2]['granted'] = hasBackgroundAccess;
  });
}


  Future<void> _requestPermissions() async {
    // Request Overlay Access
    PermissionStatus overlayStatus = await Permission.systemAlertWindow.request();
    setState(() {
      permissions[1]['granted'] = overlayStatus.isGranted;
    });
    // TODO: Guide user for Notification Access since it's not directly requestable
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _requestPermissions,
        tooltip: 'Request Permissions',
        child: const Icon(Icons.lock_open),
      ),
    );
  }

}
