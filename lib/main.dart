
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
      title: 'Block call',
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
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        const SizedBox(height: 40),
        _buildHeader(),
        const Spacer(),
        _buildMainToggle(),
        const Spacer(),
        _buildStatusCards(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 30),
                _buildStatusCards(isLandscape: true),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              child: _buildMainToggle(isLandscape: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              const Icon(Icons.security, size: 40, color: Color(0xFF00E5FF)),
              const SizedBox(height: 10),
              const Text(
                'BLOCK CALL',
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
          ),
          Positioned(
            right: 5,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Color(0xFF00E5FF), size: 28),
              onPressed: () => _showFaq(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showFaq(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1D1E33),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          border: Border(
            top: BorderSide(color: Color(0xFF00E5FF), width: 2),
          ),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Row(
              children: [
                Icon(Icons.help_outline, color: Color(0xFF00E5FF)),
                SizedBox(width: 10),
                Text(
                  'Como funciona?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFaqItem(
                      'O que este app faz?',
                      'O Block Call funciona como um escudo para o seu celular. Ele identifica chamadas de números desconhecidos ou indesejados e os impede de incomodar você.',
                    ),
                    _buildFaqItem(
                      'Ele bloqueia meus amigos?',
                      'Não! O aplicativo respeita sua lista de contatos. Chamadas de pessoas que você conhece passarão normalmente.',
                    ),
                    _buildFaqItem(
                      'Preciso deixar o app aberto?',
                      'Não é necessário. Uma vez ativado, o sistema de proteção do Android cuida de tudo automaticamente em segundo plano.',
                    ),
                    _buildFaqItem(
                      'É seguro?',
                      'Totalmente. Seus dados e lista de contatos nunca saem do seu aparelho. O bloqueio é feito de forma privada e local.',
                    ),
                    const Divider(color: Colors.white10, height: 40),
                    const Text(
                      'DESENVOLVIDO POR',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Renan Amorim',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggle({bool isLandscape = false}) {
    double size = isLandscape ? 160 : 220;
    double iconSize = isLandscape ? 60 : 80;

    return GestureDetector(
      onTap: _toggleBlocking,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.all(isLandscape ? 15 : 20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (_isBlockingEnabled)
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2 * _pulseController.value),
                    spreadRadius: (isLandscape ? 15 : 20) * _pulseController.value,
                    blurRadius: 20,
                  ),
              ],
            ),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: size,
          width: size,
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
                  size: iconSize,
                  color: Colors.white,
                ),
                SizedBox(height: isLandscape ? 5 : 10),
                Text(
                  _isBlockingEnabled ? 'ATIVADO' : 'DESATIVADO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isLandscape ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCards({bool isLandscape = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isLandscape ? 20 : 30),
      child: Row(
        children: [
          _buildInfoCard(
            'Monitoramento',
            _isBlockingEnabled ? 'Ativo' : 'Inativo',
            _isBlockingEnabled ? Icons.radar : Icons.radar_outlined,
            isLandscape: isLandscape,
          ),
          SizedBox(width: isLandscape ? 10 : 20),
          _buildInfoCard(
            'Bloqueios',
            _blockedCallsCount.toString(),
            Icons.block_flipped,
            isLandscape: isLandscape,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {bool isLandscape = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isLandscape ? 10 : 15),
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
            Icon(icon, color: const Color(0xFF00E5FF), size: isLandscape ? 18 : 20),
            SizedBox(height: isLandscape ? 5 : 10),
            Text(
              title,
              style: TextStyle(color: Colors.grey, fontSize: isLandscape ? 11 : 12),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isLandscape ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
