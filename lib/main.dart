
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const CallBlockerApp());
}

class CallBlockerApp extends StatelessWidget {
  const CallBlockerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shield Call',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00E5FF), // Cyan Neon
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        fontFamily: 'Roboto',
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const platform = MethodChannel('com.example.bloqueador_chamadas/call_blocker');
  bool _isBlockingEnabled = false;
  int _blockedCallsCount = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBlockingState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadBlockingState(); // Refresh data when app comes to foreground
    }
  }

  Future<void> _loadBlockingState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBlockingEnabled = prefs.getBool('isBlockingEnabled') ?? false;
      _blockedCallsCount = prefs.getInt('blockedCallsCount') ?? 0;
    });
  }

  Future<void> _toggleBlocking() async {
    final prefs = await SharedPreferences.getInstance();
    bool newState = !_isBlockingEnabled;

    if (newState) {
      bool permissionsGranted = await _requestPermissions();
      if (permissionsGranted) {
        await _enableCallScreening();
        await prefs.setBool('isBlockingEnabled', true);
        setState(() {
          _isBlockingEnabled = true;
        });
      }
    } else {
      await prefs.setBool('isBlockingEnabled', false);
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
      debugPrint("Failed to enable call screening: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1D1E33),
              Color(0xFF0A0E21),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const Spacer(),
              _buildMainToggle(),
              const Spacer(),
              _buildStatusCards(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.security, size: 40, color: Color(0xFF00E5FF)),
        const SizedBox(height: 10),
        const Text(
          'SHIELD CALL',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _isBlockingEnabled ? 'PROTEÇÃO ATIVA' : 'SISTEMA DESLIGADO',
          style: TextStyle(
            fontSize: 14,
            color: _isBlockingEnabled ? const Color(0xFF00E5FF) : const Color(0xFFFF5252),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMainToggle() {
    return GestureDetector(
      onTap: _toggleBlocking,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (_isBlockingEnabled)
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2 * _pulseController.value),
                    spreadRadius: 20 * _pulseController.value,
                    blurRadius: 20,
                  ),
              ],
            ),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 220,
          width: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isBlockingEnabled
                  ? [const Color(0xFF00E5FF), const Color(0xFF0097A7)]
                  : [const Color(0xFFFF5252), const Color(0xFFD32F2F)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: (_isBlockingEnabled ? const Color(0xFF00E5FF) : const Color(0xFFFF5252))
                    .withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 15,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isBlockingEnabled ? Icons.shield : Icons.shield_outlined,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  _isBlockingEnabled ? 'ATIVADO' : 'DESATIVADO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          _buildInfoCard(
            'Monitoramento',
            _isBlockingEnabled ? 'Ativo' : 'Inativo',
            _isBlockingEnabled ? Icons.radar : Icons.radar_outlined,
          ),
          const SizedBox(width: 20),
          _buildInfoCard(
            'Bloqueios',
            _blockedCallsCount.toString(),
            Icons.block_flipped,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 20),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
