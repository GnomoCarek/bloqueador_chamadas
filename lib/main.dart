
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const CallBlockerApp());
}

class CallBlockerApp extends StatelessWidget {
  const CallBlockerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloqueador de Chamadas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel('com.example.bloqueador_chamadas/call_blocker');
  bool _isBlockingEnabled = false;

  Future<void> _toggleBlocking() async {
    if (!_isBlockingEnabled) {
      bool permissionsGranted = await _requestPermissions();
      if (permissionsGranted) {
        await _enableCallScreening();
        setState(() {
          _isBlockingEnabled = true;
        });
      }
    } else {
      // TODO: Add logic to disable call screening
      setState(() {
        _isBlockingEnabled = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    var statusPhone = await Permission.phone.status;
    var statusContacts = await Permission.contacts.status;
    if (statusPhone.isDenied) {
      await Permission.phone.request();
    }
    if (statusContacts.isDenied) {
      await Permission.contacts.request();
    }
    return await Permission.phone.isGranted && await Permission.contacts.isGranted;
  }

  Future<void> _enableCallScreening() async {
    try {
      await platform.invokeMethod('enableCallScreening');
    } on PlatformException catch (e) {
      print("Failed to enable call screening: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bloqueador de Chamadas'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _isBlockingEnabled ? 'Bloqueio Ativado' : 'Bloqueio Desativado',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _toggleBlocking,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: _isBlockingEnabled ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isBlockingEnabled ? Icons.shield : Icons.shield_outlined,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
