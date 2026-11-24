import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'data/lost_found_repository.dart';
import 'data/school_services_repository.dart';
import 'data/school_transfer_repository.dart';
import 'data/schools.dart';
import 'admin_dashboard.dart';
import 'admin_school_selector.dart';
import 'firebase_options.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseOptions? options;
  try {
    options = DefaultFirebaseOptions.currentPlatform;
  } on StateError {
    options = null;
  } on UnsupportedError {
    options = null;
  }

  if (options != null) {
    await Firebase.initializeApp(options: options);
    if (!kIsWeb) await GoogleSignIn.instance.initialize();
  }

  runApp(SchoolHubApp(firebaseConfigured: options != null));
}

const _ink = Color(0xFF4A4038);
const _muted = Color(0xFF8A7E74);
const _paper = Color(0xFFFAF7F2);
const _pink = Color(0xFFE8D6C8);
const _lilac = Color(0xFFE2D9CF);
const _mint = Color(0xFFDFE5DA);
const _peach = Color(0xFFF0DFD0);
const _purple = Color(0xFF9A7E68);
const _maxLostItemImageBytes = 700000;
const _adminAccountEmail = 'knightt.fc@gmail.com';
const _allSchoolsId = 'all-schools';
const _allSchoolsName = 'Semua sekolah';

class SchoolHubApp extends StatelessWidget {
  const SchoolHubApp({super.key, this.firebaseConfigured = false});

  final bool firebaseConfigured;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'School Hub',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _purple,
        surface: _paper,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: _ink,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: _ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: _ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: _ink, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: _muted, fontSize: 12, height: 1.4),
      ),
    ),
    home: firebaseConfigured
        ? const _StartupSplashGate(child: _AuthGate())
        : const LoginPage(firebaseConfigured: false),
  );
}

class _StartupSplashGate extends StatefulWidget {
  const _StartupSplashGate({required this.child});

  final Widget child;

  @override
  State<_StartupSplashGate> createState() => _StartupSplashGateState();
}

class _StartupSplashGateState extends State<_StartupSplashGate> {
  bool _showSplash = true;
  bool _removeSplash = false;

  void _finishSplash() {
    if (!mounted || !_showSplash) return;
    setState(() => _showSplash = false);
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _removeSplash = true);
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (!_removeSplash)
        AnimatedOpacity(
          opacity: _showSplash ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          child: _AnimatedSplash(onFinished: _finishSplash),
        ),
    ],
  );
}

class _AnimatedSplash extends StatefulWidget {
  const _AnimatedSplash({required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<_AnimatedSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..addStatusListener(_onAnimationStatus);
    _controller.forward();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = Curves.easeInOutCubic.transform(_controller.value);
        final logoProgress = Curves.elasticOut.transform(
          ((_controller.value - 0.12) / 0.48).clamp(0, 1),
        );
        final titleProgress = Curves.easeOutCubic.transform(
          ((_controller.value - 0.38) / 0.34).clamp(0, 1),
        );
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF241C1A), Color(0xFF49342D), Color(0xFF745541)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -100,
                right: -80,
                child: _SplashGlow(
                  size: 290,
                  color: _pink.withValues(alpha: 0.16),
                ),
              ),
              Positioned(
                bottom: -130,
                left: -90,
                child: _SplashGlow(
                  size: 340,
                  color: _mint.withValues(alpha: 0.12),
                ),
              ),
              CustomPaint(
                painter: _SplashParticlePainter(progress: progress),
                child: const SizedBox.expand(),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.rotate(
                              angle: progress * 1.45,
                              child: Container(
                                width: 218,
                                height: 218,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            Transform.rotate(
                              angle: -progress * 2.1,
                              child: Container(
                                width: 174,
                                height: 174,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _pink.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 17,
                              child: _SplashOrbitIcon(
                                icon: Icons.auto_awesome_rounded,
                                color: _peach,
                                scale: logoProgress,
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 56,
                              child: _SplashOrbitIcon(
                                icon: Icons.menu_book_rounded,
                                color: _mint,
                                scale: logoProgress,
                              ),
                            ),
                            Positioned(
                              left: 16,
                              bottom: 45,
                              child: _SplashOrbitIcon(
                                icon: Icons.edit_note_rounded,
                                color: _pink,
                                scale: logoProgress,
                              ),
                            ),
                            Transform.scale(
                              scale: logoProgress,
                              child: Container(
                                width: 126,
                                height: 126,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(38),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFF8EE), _pink],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _peach.withValues(alpha: 0.34),
                                      blurRadius: 42,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  size: 68,
                                  color: _purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: titleProgress,
                        child: Transform.translate(
                          offset: Offset(0, 18 * (1 - titleProgress)),
                          child: Column(
                            children: [
                              const Text(
                                'SchoolHub',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                'SEKOLAH • KOMUNITI • MASA DEPAN',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 38),
                      Opacity(
                        opacity: titleProgress,
                        child: SizedBox(
                          width: 112,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 3,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                _peach,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _SplashGlow extends StatelessWidget {
  const _SplashGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}

class _SplashOrbitIcon extends StatelessWidget {
  const _SplashOrbitIcon({
    required this.icon,
    required this.color,
    required this.scale,
  });

  final IconData icon;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: scale,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF392A25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 21),
    ),
  );
}

class _SplashParticlePainter extends CustomPainter {
  const _SplashParticlePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.42);
    const particles = [
      Offset(0.13, 0.18),
      Offset(0.82, 0.2),
      Offset(0.9, 0.46),
      Offset(0.12, 0.68),
      Offset(0.78, 0.84),
      Offset(0.34, 0.88),
      Offset(0.66, 0.12),
      Offset(0.24, 0.42),
    ];
    for (var index = 0; index < particles.length; index++) {
      final particle = particles[index];
      final pulse = 1 + 1.8 * (0.5 + 0.5 * math.sin(progress * 8 + index));
      canvas.drawCircle(
        Offset(size.width * particle.dx, size.height * particle.dy),
        pulse,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SplashParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _AuthErrorPage();
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: _purple)),
        );
      }
      final user = snapshot.data;
      if (user == null) {
        return const LoginPage(firebaseConfigured: true);
      }
      return MainShell(user: user);
    },
  );
}

class _AuthErrorPage extends StatelessWidget {
  const _AuthErrorPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Tidak dapat menyemak status log masuk. Sila semak sambungan internet dan cuba lagi.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.user});

  final User? user;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  String _role = 'Guru';
  String _school = supportedSchools.first;
  String _adminSelectedSchool = supportedSchools.first;
  bool _profileReady = false;
  bool _needsProfileSetup = false;
  Object? _profileError;
  final Set<String> _shownAnnouncementIds = {};
  final Set<String> _scheduledAnnouncementIds = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;

  bool get _canSetAdminRole =>
      widget.user?.email?.trim().toLowerCase() == _adminAccountEmail;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = widget.user;
    if (user == null) {
      _profileReady = true;
      return;
    }

    if (mounted) {
      setState(() {
        _profileError = null;
        _profileReady = false;
        _needsProfileSetup = false;
      });
    }

    try {
      final reference = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final snapshot = await reference.get();
      _applyProfileSnapshot(snapshot);
      _profileSubscription ??= reference.snapshots().listen(
        _applyProfileSnapshot,
        onError: (Object error) {
          if (mounted) setState(() => _profileError = error);
        },
      );
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _profileError = error);
    } on StateError catch (error) {
      if (mounted) setState(() => _profileError = error);
    }
  }

  void _applyProfileSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!mounted) return;
    try {
      if (!snapshot.exists) {
        setState(() {
          _needsProfileSetup = true;
          _profileReady = true;
          _profileError = null;
        });
        return;
      }
      final profile = snapshot.data()!;
      final schoolName = profile['schoolName'];
      final schoolId = profile['schoolId'];
      final role = profile['role'];
      if (profile['setupComplete'] != true) {
        if (role == 'Admin' && _canSetAdminRole) {
          _school = _allSchoolsName;
          _role = 'Admin';
        } else if (schoolName is String &&
            schoolId == schoolIdForName(schoolName)) {
          _school = schoolName;
        }
        if (role is String &&
            ['Guru', 'Ibu bapa', 'PK HEM', 'Admin'].contains(role) &&
            (role != 'Admin' || _canSetAdminRole)) {
          _role = role;
        }
        _needsProfileSetup = true;
      } else if (role == 'Admin' && _canSetAdminRole) {
        _school = _allSchoolsName;
        _role = 'Admin';
        _needsProfileSetup =
            schoolId != _allSchoolsId || schoolName != _allSchoolsName;
      } else if (_canSetAdminRole &&
          role is String &&
          ['Guru', 'Ibu bapa', 'PK HEM'].contains(role)) {
        _school = _allSchoolsName;
        _role = 'Admin';
        _needsProfileSetup = true;
      } else if (schoolName is String &&
          schoolId == schoolIdForName(schoolName) &&
          role is String &&
          ['Guru', 'Ibu bapa', 'PK HEM', 'Admin'].contains(role) &&
          supportedSchools.contains(schoolName)) {
        _school = schoolName;
        _role = role;
        _needsProfileSetup = false;
      } else if (role is String &&
          ['Guru', 'Ibu bapa', 'PK HEM'].contains(role)) {
        _school = supportedSchools.first;
        _role = _canSetAdminRole ? 'Admin' : role;
        _needsProfileSetup = true;
      } else {
        throw StateError('Profil sekolah tidak sah.');
      }
      setState(() {
        _profileReady = true;
        _profileError = null;
      });
    } on StateError catch (error) {
      if (mounted) setState(() => _profileError = error);
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  Future<void> _completeProfileSetup(String school, String role) async {
    final user = widget.user;
    if (user == null) return;
    try {
      final reference = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final snapshot = await reference.get();
      final profileSchoolId = role == 'Admin'
          ? _allSchoolsId
          : schoolIdForName(school);
      final profileSchoolName = role == 'Admin' ? _allSchoolsName : school;
      final profile = <String, dynamic>{
        'schoolId': profileSchoolId,
        'schoolName': profileSchoolName,
        'role': role,
        'setupComplete': true,
      };
      if (snapshot.exists) {
        await reference.update(profile);
      } else {
        await reference.set({
          ...profile,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        setState(() {
          _school = profileSchoolName;
          _role = role;
          _needsProfileSetup = false;
        });
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'permission-denied'
                ? 'Akses ditolak. Pastikan Firestore rules terkini sudah diterbitkan dan anda log masuk menggunakan akaun Google yang dibenarkan.'
                : 'Profil tidak dapat disimpan (${error.code}).',
          ),
        ),
      );
    }
  }

  void _openModule(String module, {String? school}) {
    final moduleSchool =
        school ??
        (_role == 'Admin' && module != 'Kelulusan tukar sekolah'
            ? _adminSelectedSchool
            : _school);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModulePage(
          module: module,
          role: _role,
          school: moduleSchool,
          user: widget.user,
        ),
      ),
    );
  }

  void _openAdminModule(String module, String school) =>
      _openModule(module, school: school == _allSchoolsName ? _school : school);

  String get _displayName {
    final name = widget.user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = widget.user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Pengguna';
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!kIsWeb) await GoogleSignIn.instance.signOut();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Tidak dapat log keluar.')),
      );
    } on GoogleSignInException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.description ?? 'Tidak dapat log keluar Google.'),
        ),
      );
    }
  }

  void _setTab(int index) => setState(() => _tab = index);

  void _showAnnouncementPopup(SchoolAnnouncement announcement) {
    if (_shownAnnouncementIds.contains(announcement.id) ||
        !_scheduledAnnouncementIds.add(announcement.id)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduledAnnouncementIds.remove(announcement.id);
      if (!mounted ||
          _tab != 0 ||
          !_shownAnnouncementIds.add(announcement.id)) {
        return;
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AnnouncementPopup(announcement: announcement),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      if (_role == 'Admin')
        AdminDashboard(
          user: widget.user,
          displayName: _displayName,
          onOpenModule: _openAdminModule,
          onCreateAnnouncement: () {
            final user = widget.user;
            if (user != null) {
              _showAnnouncementEditor(
                context,
                _allSchoolsName,
                user,
                isGlobal: true,
              );
            }
          },
        )
      else
        _HomePage(
          role: _role,
          school: _school,
          user: widget.user,
          displayName: _displayName,
          onOpenModule: _openModule,
          onNotifications: () => _openModule('Pengumuman'),
          onShowAnnouncement: _showAnnouncementPopup,
        ),
      NoticePage(school: _school, user: widget.user, role: _role),
      ServicesPage(onOpenModule: _openModule, role: _role),
      ProfilePage(
        role: _role,
        school: _school,
        user: widget.user,
        onSignOut: _signOut,
      ),
    ];

    if (_profileReady && _needsProfileSetup) {
      if (kIsWeb && !_canSetAdminRole) {
        return _WebAdminOnlyPage(onSignOut: _signOut);
      }
      return Scaffold(
        body: SafeArea(
          child: _ProfileSetupPage(
            initialSchool: _school,
            initialRole: _canSetAdminRole
                ? 'Admin'
                : _role == 'Ibu bapa'
                ? 'Ibu bapa'
                : 'Guru',
            canSetAdminRole: _canSetAdminRole,
            onSubmit: _completeProfileSetup,
          ),
        ),
      );
    }

    if (_profileReady && kIsWeb && (!_canSetAdminRole || _role != 'Admin')) {
      return _WebAdminOnlyPage(onSignOut: _signOut);
    }

    final isAdminDesktop =
        kIsWeb &&
        _canSetAdminRole &&
        _role == 'Admin' &&
        MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: SafeArea(
        child: _profileError != null
            ? _ProfileRetryPage(onRetry: _loadUserProfile)
            : !_profileReady
            ? const Center(child: CircularProgressIndicator(color: _purple))
            : isAdminDesktop
            ? Row(
                children: [
                  _AdminDesktopSidebar(
                    displayName: _displayName,
                    email: widget.user?.email ?? '',
                    selectedIndex: _tab,
                    selectedSchool: _adminSelectedSchool,
                    onDestinationSelected: _setTab,
                    onSchoolSelected: (school) =>
                        setState(() => _adminSelectedSchool = school),
                    onSignOut: _signOut,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey(_tab),
                        child: pages[_tab],
                      ),
                    ),
                  ),
                ],
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
              ),
      ),
      bottomNavigationBar: isAdminDesktop
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: _ink.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: NavigationBar(
                height: 72,
                backgroundColor: Colors.white,
                indicatorColor: _lilac.withValues(alpha: 0.66),
                selectedIndex: _tab,
                onDestinationSelected: _setTab,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Utama',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.campaign_outlined),
                    selectedIcon: Icon(Icons.campaign_rounded),
                    label: 'Notis',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_rounded),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: 'Servis',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
    );
  }
}

class _AdminDesktopSidebar extends StatelessWidget {
  const _AdminDesktopSidebar({
    required this.displayName,
    required this.email,
    required this.selectedIndex,
    required this.selectedSchool,
    required this.onDestinationSelected,
    required this.onSchoolSelected,
    required this.onSignOut,
  });

  final String displayName;
  final String email;
  final int selectedIndex;
  final String selectedSchool;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<String> onSchoolSelected;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    const labels = ['Ringkasan', 'Papan notis', 'Servis', 'Profil'];
    const icons = [
      Icons.dashboard_outlined,
      Icons.campaign_outlined,
      Icons.grid_view_rounded,
      Icons.person_outline_rounded,
    ];

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFF0EAE2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(21, 24, 18, 19),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _peach,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.school_rounded, color: _purple),
                ),
                const SizedBox(width: 11),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SchoolHub',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _purple,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'PORTAL PENTADBIR',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _muted,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AdminSchoolSelector(
              selectedSchool: selectedSchool,
              onSelected: onSchoolSelected,
            ),
          ),
          const SizedBox(height: 17),
          for (var index = 0; index < labels.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: ListTile(
                selected: selectedIndex == index,
                selectedTileColor: _lilac.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(
                  icons[index],
                  color: selectedIndex == index ? _purple : _muted,
                ),
                title: Text(
                  labels[index],
                  style: TextStyle(
                    color: selectedIndex == index ? _ink : _muted,
                    fontWeight: selectedIndex == index
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
                onTap: () => onDestinationSelected(index),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 5),
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log keluar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRetryPage extends StatelessWidget {
  const _ProfileRetryPage({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: _purple, size: 38),
          const SizedBox(height: 12),
          Text(
            'Profil sekolah belum dapat dimuat.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 7),
          Text(
            'Semak sambungan internet dan tetapan Firestore, kemudian cuba lagi.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Cuba lagi'),
          ),
        ],
      ),
    ),
  );
}

class _WebAdminOnlyPage extends StatelessWidget {
  const _WebAdminOnlyPage({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_rounded, size: 46),
              const SizedBox(height: 14),
              Text(
                'Portal ini untuk Admin sahaja',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Gunakan aplikasi SchoolHub di telefon untuk akaun sekolah anda.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log keluar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ProfileSetupPage extends StatefulWidget {
  const _ProfileSetupPage({
    required this.initialSchool,
    required this.initialRole,
    required this.canSetAdminRole,
    required this.onSubmit,
  });

  final String initialSchool;
  final String initialRole;
  final bool canSetAdminRole;
  final Future<void> Function(String school, String role) onSubmit;

  @override
  State<_ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<_ProfileSetupPage> {
  late String _school;
  late String _role;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _school = supportedSchools.contains(widget.initialSchool)
        ? widget.initialSchool
        : supportedSchools.first;
    _role = widget.initialRole;
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    await widget.onSubmit(_school, _role);
    if (mounted) setState(() => _saving = false);
  }

  bool get _showSchoolSelector => !widget.canSetAdminRole || _role != 'Admin';

  @override
  Widget build(BuildContext context) => _PageScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const _PageHeading(
          title: 'Selamat datang ke SchoolHub',
          subtitle: 'Tetapkan akaun anda untuk mula menggunakan SchoolHub.',
          icon: Icons.school_rounded,
          color: _mint,
        ),
        const SizedBox(height: 24),
        if (_showSchoolSelector) ...[
          const _FormLabel(label: 'Pilih sekolah'),
          DropdownButtonFormField<String>(
            initialValue: _school,
            isExpanded: true,
            decoration: _inputDecoration('Pilih sekolah'),
            items: [
              for (final school in supportedSchools)
                DropdownMenuItem(value: school, child: Text(school)),
            ],
            onChanged: _saving
                ? null
                : (school) {
                    if (school != null) setState(() => _school = school);
                  },
          ),
          const SizedBox(height: 20),
        ],
        const _FormLabel(label: 'Saya ialah'),
        Wrap(
          spacing: 9,
          children: [
            for (final role
                in widget.canSetAdminRole
                    ? const ['Guru', 'Ibu bapa', 'PK HEM', 'Admin']
                    : const ['Guru', 'Ibu bapa', 'PK HEM'])
              ChoiceChip(
                label: Text(role),
                selected: _role == role,
                onSelected: _saving
                    ? null
                    : (_) => setState(() => _role = role),
                selectedColor: _lilac,
              ),
          ],
        ),
        const SizedBox(height: 8),
        _InfoBanner(
          icon: Icons.lock_outline_rounded,
          title: 'Peranan Admin dihadkan kepada akaun pentadbir',
          body: widget.canSetAdminRole
              ? 'Akaun ini ialah Admin untuk semua sekolah dan tidak perlu memilih sekolah.'
              : 'Pilih sekolah anda. Permohonan pertukaran sekolah perlu diluluskan Admin.',
          color: _peach,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 51),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan dan teruskan'),
        ),
      ],
    ),
  );
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.role,
    required this.school,
    required this.user,
    required this.displayName,
    required this.onOpenModule,
    required this.onNotifications,
    required this.onShowAnnouncement,
  });

  final String role;
  final String school;
  final User? user;
  final String displayName;
  final ValueChanged<String> onOpenModule;
  final VoidCallback onNotifications;
  final ValueChanged<SchoolAnnouncement> onShowAnnouncement;

  @override
  Widget build(BuildContext context) => _PageScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SchoolHub',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _purple,
                      fontSize: 17,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    school,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _RoundButton(
              icon: Icons.notifications_none_rounded,
              onTap: onNotifications,
              badge: true,
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 22,
              backgroundColor: _pink,
              child: Text(
                role == 'Ibu bapa' ? 'IB' : 'CN',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _WelcomeCard(role: role, displayName: displayName),
        const SizedBox(height: 27),
        LayoutBuilder(
          builder: (context, constraints) {
            final title = Text(
              'Apa yang anda perlukan?',
              style: Theme.of(context).textTheme.titleLarge,
            );
            final action = TextButton(
              onPressed: () => onOpenModule('Semua servis'),
              child: const Text('Lihat semua'),
            );
            if (constraints.maxWidth < 360) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: title),
                action,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _ServiceGrid(onOpenModule: onOpenModule),
        const SizedBox(height: 27),
        _HomeAnnouncements(
          stream: user == null
              ? null
              : school == _allSchoolsName
              ? SchoolServicesRepository(
                  firestore: FirebaseFirestore.instance,
                  schoolId: _allSchoolsId,
                ).watchAllAnnouncements()
              : SchoolServicesRepository(
                  firestore: FirebaseFirestore.instance,
                  schoolId: schoolIdForName(school),
                ).watchAnnouncements(),
          onOpenAnnouncements: () => onOpenModule('Pengumuman'),
          onShowAnnouncement: onShowAnnouncement,
        ),
        const SizedBox(height: 22),
        _HelpCard(onTap: () => onOpenModule('Pengumuman')),
      ],
    ),
  );
}

class _HomeAnnouncements extends StatelessWidget {
  const _HomeAnnouncements({
    required this.stream,
    required this.onOpenAnnouncements,
    required this.onShowAnnouncement,
  });

  final Stream<List<SchoolAnnouncement>>? stream;
  final VoidCallback onOpenAnnouncements;
  final ValueChanged<SchoolAnnouncement> onShowAnnouncement;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Untuk perhatian',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      const SizedBox(height: 13),
      if (stream == null)
        const _InfoBanner(
          icon: Icons.campaign_outlined,
          title: 'Pengumuman sekolah',
          body: 'Log masuk untuk melihat pengumuman sekolah anda.',
          color: _lilac,
        )
      else
        StreamBuilder<List<SchoolAnnouncement>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _InfoBanner(
                icon: Icons.error_outline_rounded,
                title: 'Pengumuman tidak dapat dimuat',
                body: 'Sila semak sambungan atau kebenaran Firestore.',
                color: _peach,
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(color: _purple)),
              );
            }
            final announcements = snapshot.data!;
            if (announcements.isNotEmpty) {
              onShowAnnouncement(announcements.first);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TinyLabel(
                    icon: Icons.campaign_rounded,
                    label: '${announcements.length} pengumuman tersedia',
                    color: _purple,
                  ),
                ),
                if (announcements.isEmpty)
                  const _InfoBanner(
                    icon: Icons.campaign_outlined,
                    title: 'Tiada pengumuman aktif',
                    body:
                        'Pengumuman akan kekal di sini sehingga dipadam oleh Admin.',
                    color: _lilac,
                  ),
                for (final notice in announcements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AnnouncementCard(
                      icon: notice.category == 'AKTIVITI'
                          ? Icons.event_available_rounded
                          : notice.category == 'PENTING'
                          ? Icons.priority_high_rounded
                          : Icons.campaign_rounded,
                      iconColor: _noticeColor(notice.category) == _mint
                          ? const Color(0xFF82907B)
                          : _purple,
                      title: notice.title,
                      subtitle: '${notice.dateLabel} · ${notice.body}',
                      tag: notice.schoolId == _allSchoolsId
                          ? 'SEMUA SEKOLAH · ${notice.category}'
                          : notice.category,
                      imageBytes: notice.imageBytes,
                      onTap: onOpenAnnouncements,
                    ),
                  ),
              ],
            );
          },
        ),
      const SizedBox(height: 22),
      _HelpCard(onTap: onOpenAnnouncements),
    ],
  );
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.role, required this.displayName});
  final String role;
  final String displayName;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        colors: [Color(0xFFF0E6D9), Color(0xFFE8D8CB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          right: 4,
          top: 0,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 31,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'KHAMIS, 5 NOVEMBER',
                style: TextStyle(
                  color: _purple.withValues(alpha: 0.95),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 17),
            Text(
              'Hai, ${role == 'Ibu bapa' ? 'ibu bapa' : displayName.split(' ').first}! 🌷',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontSize: 23),
            ),
            const SizedBox(height: 7),
            Text(
              'Semua urusan sekolah, kini lebih mudah.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _ink.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 19),
            Row(
              children: [
                const Icon(
                  Icons.wb_sunny_rounded,
                  color: Color(0xFFAA896D),
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Semoga hari anda indah!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _ink.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.onOpenModule});
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    const services = [
      _ServiceData(
        'Lost & Found',
        'Barang hilang & jumpa',
        Icons.backpack_rounded,
        _peach,
      ),
      _ServiceData(
        'Aduan fasiliti',
        'Laporkan kerosakan',
        Icons.handyman_rounded,
        _mint,
      ),
      _ServiceData(
        'Tempahan',
        'Bilik & peralatan',
        Icons.calendar_month_rounded,
        _lilac,
      ),
      _ServiceData(
        'Pengumuman',
        'Info terkini sekolah',
        Icons.campaign_rounded,
        _pink,
      ),
    ];
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return GridView.builder(
      itemCount: services.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 138 * textScale.clamp(1, 1.5),
      ),
      itemBuilder: (context, index) {
        final item = services[index];
        return _Pressable(
          onTap: () => onOpenModule(item.title),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: const Color(0xFFF0EAE2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(item.icon, size: 21, color: _ink),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceData {
  const _ServiceData(this.title, this.subtitle, this.icon, this.color);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
    this.imageBytes,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) => _Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFF0EAE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.memory(
                imageBytes!,
                width: double.infinity,
                height: 130,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _purple,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: _muted.withValues(alpha: .7),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E8DE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: _purple),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Ada soalan? Kami sedia membantu.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: _purple, size: 19),
        ],
      ),
    ),
  );
}

class NoticePage extends StatelessWidget {
  const NoticePage({
    super.key,
    required this.school,
    required this.user,
    required this.role,
  });
  final String school;
  final User? user;
  final String role;

  @override
  Widget build(BuildContext context) => _PageScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeading(
          title: 'Papan notis',
          subtitle: 'Makluman rasmi untuk komuniti sekolah',
          icon: Icons.campaign_rounded,
          color: _pink,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0EAE2)),
          ),
          child: const TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Cari pengumuman...',
              icon: Icon(Icons.search_rounded, color: _muted),
            ),
          ),
        ),
        const SizedBox(height: 17),
        _SchoolScope(school: school),
        const SizedBox(height: 17),
        if (role == 'PK HEM' || role == 'Admin')
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: user == null
                  ? null
                  : () => _showAnnouncementEditor(
                      context,
                      school,
                      user!,
                      isGlobal: role == 'Admin',
                    ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah pengumuman'),
            ),
          ),
        if (user == null) ...[
          const _NoticeTile(
            category: 'PENTING',
            title: 'Jadual peperiksaan pertengahan tahun',
            body:
                'Semua murid diminta menyemak jadual peperiksaan yang telah dikemaskini. Sila hubungi guru kelas jika terdapat sebarang pertanyaan.',
            date: 'Hari ini · 9:30 pagi',
            color: _lilac,
            icon: Icons.menu_book_rounded,
          ),
          const _NoticeTile(
            category: 'AKTIVITI',
            title: 'Hari Sukan Tahunan 2025',
            body:
                'Jom memeriahkan Hari Sukan Tahunan! Ibu bapa dan penjaga dijemput hadir untuk memberi sokongan kepada anak-anak.',
            date: 'Semalam · 2:15 petang',
            color: _mint,
            icon: Icons.directions_run_rounded,
          ),
          const _NoticeTile(
            category: 'MAKLUMAN',
            title: 'Kemas kini waktu operasi kantin',
            body:
                'Waktu rehat sesi pagi akan bermula pada 10:00 pagi mulai minggu hadapan.',
            date: '3 Nov 2025',
            color: _peach,
            icon: Icons.restaurant_rounded,
          ),
        ] else
          _SchoolAnnouncementsView(
            stream: role == 'Admin'
                ? SchoolServicesRepository(
                    firestore: FirebaseFirestore.instance,
                    schoolId: _allSchoolsId,
                  ).watchAllAnnouncements()
                : SchoolServicesRepository(
                    firestore: FirebaseFirestore.instance,
                    schoolId: schoolIdForName(school),
                  ).watchAnnouncements(),
            canDelete: (role == 'PK HEM' || role == 'Admin') && user != null,
            canDeleteGlobal: role == 'Admin',
            onDelete: (notice) => SchoolServicesRepository(
              firestore: FirebaseFirestore.instance,
              schoolId: notice.schoolId,
            ).deleteAnnouncement(notice.id),
          ),
      ],
    ),
  );
}

class _SchoolAnnouncementsView extends StatelessWidget {
  const _SchoolAnnouncementsView({
    required this.stream,
    this.canDelete = false,
    this.canDeleteGlobal = false,
    this.onDelete,
  });
  final Stream<List<SchoolAnnouncement>> stream;
  final bool canDelete;
  final bool canDeleteGlobal;
  final Future<void> Function(SchoolAnnouncement notice)? onDelete;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<SchoolAnnouncement>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _InfoBanner(
          icon: Icons.error_outline_rounded,
          title: 'Pengumuman tidak dapat dimuat',
          body: 'Sila semak sambungan atau kebenaran Firestore.',
          color: _peach,
        );
      }
      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.data!.isEmpty) {
        return const _InfoBanner(
          icon: Icons.campaign_outlined,
          title: 'Belum ada pengumuman',
          body: 'Pengumuman sekolah akan dipaparkan di sini.',
          color: _lilac,
        );
      }
      return Column(
        children: snapshot.data!
            .map(
              (notice) => _SwipeToDeleteCard(
                itemKey: 'announcement-${notice.id}',
                title: notice.title,
                enabled:
                    canDelete &&
                    onDelete != null &&
                    (canDeleteGlobal || notice.schoolId != _allSchoolsId),
                onDelete: () => onDelete!(notice),
                child: _NoticeTile(
                  category: notice.category,
                  title: notice.title,
                  body: notice.body,
                  date: notice.dateLabel,
                  color: _noticeColor(notice.category),
                  icon: Icons.campaign_rounded,
                  imageBytes: notice.imageBytes,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

Color _noticeColor(String category) {
  switch (category) {
    case 'PENTING':
      return _peach;
    case 'AKTIVITI':
      return _mint;
    default:
      return _lilac;
  }
}

Future<void> _showAnnouncementEditor(
  BuildContext context,
  String school,
  User? user, {
  bool isGlobal = false,
}) async {
  if (user == null) return;
  final draft = await showModalBottomSheet<_AnnouncementDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 620),
    backgroundColor: Colors.transparent,
    builder: (_) => _AnnouncementEditor(isGlobal: isGlobal),
  );
  if (!context.mounted || draft == null) return;
  try {
    await SchoolServicesRepository(
      firestore: FirebaseFirestore.instance,
      schoolId: isGlobal
          ? _allSchoolsId
          : school == _allSchoolsName
          ? _allSchoolsId
          : schoolIdForName(school),
    ).addAnnouncement(
      title: draft.title,
      body: draft.body,
      category: draft.category,
      eventDate: draft.eventDate,
      userId: user.uid,
      imageBytes: draft.imageBytes,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengumuman berjaya ditambah.')),
    );
  } on FirebaseException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.code == 'permission-denied'
              ? 'Akses Firestore ditolak. Terbitkan Firestore Rules terkini (termasuk sokongan gambar pengumuman) dan pastikan akaun anda Admin/PK HEM.'
              : 'Pengumuman gagal disimpan (${error.code}).',
        ),
      ),
    );
  } on ArgumentError catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message?.toString() ?? 'Imej tidak sah.')),
    );
  }
}

class _AnnouncementDraft {
  const _AnnouncementDraft(
    this.title,
    this.body,
    this.category,
    this.eventDate,
    this.imageBytes,
  );
  final String title;
  final String body;
  final String category;
  final DateTime eventDate;
  final Uint8List? imageBytes;
}

class _AnnouncementEditor extends StatefulWidget {
  const _AnnouncementEditor({required this.isGlobal});

  final bool isGlobal;

  @override
  State<_AnnouncementEditor> createState() => _AnnouncementEditorState();
}

class _AnnouncementEditorState extends State<_AnnouncementEditor> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _category = 'MAKLUMAN';
  DateTime _eventDate = DateUtils.dateOnly(DateTime.now());
  Uint8List? _imageBytes;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isGlobal
                  ? 'Pengumuman semua sekolah'
                  : 'Pengumuman baharu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            if (widget.isGlobal) ...[
              const _InfoBanner(
                icon: Icons.public_rounded,
                title: 'Untuk semua sekolah',
                body: 'Pengumuman ini akan dipaparkan kepada semua sekolah.',
                color: _lilac,
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _titleController,
              maxLength: 100,
              decoration: _inputDecoration('Tajuk / header'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _inputDecoration('Kategori'),
              items: const ['MAKLUMAN', 'PENTING', 'AKTIVITI']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 10),
            const _FormLabel(label: 'Tarikh pengumuman'),
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _eventDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (selected != null) {
                  setState(() => _eventDate = DateUtils.dateOnly(selected));
                }
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                '${_eventDate.day}/${_eventDate.month}/${_eventDate.year}',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              maxLength: 1000,
              decoration: _inputDecoration('Penerangan pengumuman'),
            ),
            const SizedBox(height: 10),
            const _FormLabel(label: 'Gambar pengumuman (pilihan)'),
            if (_imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  _imageBytes!,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _imageBytes = null),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Buang gambar'),
                ),
              ),
            ],
            OutlinedButton.icon(
              onPressed: _chooseImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _imageBytes == null ? 'Pilih gambar' : 'Tukar gambar',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: const BorderSide(color: Color(0xFFD9C8B8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                minimumSize: const Size(double.infinity, 47),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final title = _titleController.text.trim();
                  final body = _bodyController.text.trim();
                  if (title.isEmpty || body.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Isi tajuk dan penerangan.'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(
                    context,
                    _AnnouncementDraft(
                      title,
                      body,
                      _category,
                      _eventDate,
                      _imageBytes,
                    ),
                  );
                },
                child: const Text('Terbitkan'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _chooseImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 55,
      );
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      if (bytes.length > maxAnnouncementImageBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Saiz gambar terlalu besar. Sila pilih gambar yang lebih kecil.',
            ),
          ),
        );
        return;
      }
      setState(() => _imageBytes = bytes);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar tidak dapat dibuka. Cuba lagi.')),
      );
    }
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({
    required this.category,
    required this.title,
    required this.body,
    required this.date,
    required this.color,
    required this.icon,
    this.imageBytes,
  });

  final String category;
  final String title;
  final String body;
  final String date;
  final Color color;
  final IconData icon;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFF0EAE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 20, color: _ink),
              ),
              const SizedBox(width: 10),
              _TinyLabel(icon: Icons.circle, label: category, color: _purple),
              const Spacer(),
              const Icon(Icons.more_horiz_rounded, color: _muted),
            ],
          ),
          const SizedBox(height: 13),
          if (imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                imageBytes!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 13),
          ],
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _muted),
          ),
          const SizedBox(height: 10),
          Text(
            date,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _AnnouncementPopup extends StatelessWidget {
  const _AnnouncementPopup({required this.announcement});

  final SchoolAnnouncement announcement;

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _TinyLabel(
                    icon: Icons.campaign_rounded,
                    label: announcement.category,
                    color: _purple,
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup pengumuman',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (announcement.imageBytes != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  announcement.imageBytes!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              announcement.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 5),
            Text(
              announcement.dateLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              announcement.body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ),
  );
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({
    super.key,
    required this.onOpenModule,
    required this.role,
  });

  final ValueChanged<String> onOpenModule;
  final String role;

  @override
  Widget build(BuildContext context) => _PageScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeading(
          title: 'Servis sekolah',
          subtitle: 'Semua urusan sekolah di satu tempat',
          icon: Icons.grid_view_rounded,
          color: _lilac,
        ),
        const SizedBox(height: 21),
        Text(
          'UNTUK ANDA',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        _ModuleListTile(
          icon: Icons.backpack_rounded,
          color: _peach,
          title: 'Lost & Found',
          subtitle: 'Cari atau laporkan barang tercicir',
          onTap: () => onOpenModule('Lost & Found'),
        ),
        if (role != 'Ibu bapa')
          _ModuleListTile(
            icon: Icons.handyman_rounded,
            color: _mint,
            title: 'Aduan fasiliti',
            subtitle: 'Laporkan kerosakan di sekolah',
            onTap: () => onOpenModule('Aduan fasiliti'),
          ),
        if (role != 'Ibu bapa')
          _ModuleListTile(
            icon: Icons.calendar_month_rounded,
            color: _lilac,
            title: 'Tempahan & pinjaman',
            subtitle: 'Tempah ruang atau peralatan',
            onTap: () => onOpenModule('Tempahan'),
          ),
        _ModuleListTile(
          icon: Icons.campaign_rounded,
          color: _pink,
          title: 'Pengumuman',
          subtitle: 'Baca berita terkini sekolah',
          onTap: () => onOpenModule('Pengumuman'),
        ),
        if (['Guru', 'PK HEM'].contains(role))
          _ModuleListTile(
            icon: Icons.swap_horiz_rounded,
            color: _peach,
            title: 'Permohonan tukar sekolah',
            subtitle: 'Mohon tukar sekolah atau jawatan kepada admin',
            onTap: () => onOpenModule('Permohonan tukar sekolah'),
          ),
        if (role == 'Admin')
          _ModuleListTile(
            icon: Icons.fact_check_rounded,
            color: _mint,
            title: 'Permohonan tukar sekolah',
            subtitle: 'Semak dan luluskan pertukaran sekolah',
            onTap: () => onOpenModule('Kelulusan tukar sekolah'),
          ),
        const SizedBox(height: 12),
        const _InfoBanner(
          icon: Icons.lock_outline_rounded,
          title: 'Maklumat sekolah anda sahaja',
          body:
              'Kandungan dipaparkan mengikut sekolah yang dipautkan pada profil anda.',
          color: _mint,
        ),
      ],
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.role,
    required this.school,
    required this.user,
    required this.onSignOut,
  });

  final String role;
  final String school;
  final User? user;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) => _PageScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeading(
          title: 'Profil saya',
          subtitle: 'Urus akaun dan tetapan sekolah',
          icon: Icons.person_rounded,
          color: _pink,
        ),
        const SizedBox(height: 21),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: const Color(0xFFF0EAE2)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: _lilac,
                child: user?.photoURL == null
                    ? const Icon(Icons.person_rounded, color: _purple, size: 35)
                    : ClipOval(
                        child: Image.network(
                          user!.photoURL!,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person_rounded,
                            color: _purple,
                            size: 35,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              Text(
                user?.displayName ?? user?.email ?? 'Pengguna SchoolHub',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'E-mel tidak tersedia',
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 19),
        _SettingsTile(
          icon: Icons.school_rounded,
          color: _mint,
          title: 'Sekolah saya',
          subtitle: school,
          locked: true,
        ),
        _SettingsTile(
          icon: Icons.badge_outlined,
          color: _peach,
          title: 'Jenis akaun',
          subtitle: role,
          locked: true,
        ),
        _SettingsTile(
          icon: Icons.notifications_active_outlined,
          color: _lilac,
          title: 'Notifikasi',
          subtitle: 'Pengumuman dan kemas kini',
          onTap: () => _showMessage(
            context,
            'Notifikasi',
            'Tetapan notifikasi akan tersedia selepas akaun disambungkan.',
          ),
        ),
        _SettingsTile(
          icon: Icons.help_outline_rounded,
          color: _pink,
          title: 'Bantuan & maklum balas',
          subtitle: 'Kami sedia membantu anda',
          onTap: () => _showMessage(
            context,
            'Bantuan SchoolHub',
            'Hubungi pihak pentadbiran sekolah untuk bantuan lanjut.',
          ),
        ),
        _SettingsTile(
          icon: Icons.logout_rounded,
          color: _peach,
          title: 'Log keluar',
          subtitle: 'Log keluar daripada akaun ini',
          onTap: onSignOut,
        ),
        const SizedBox(height: 12),
        const _InfoBanner(
          icon: Icons.shield_outlined,
          title: 'Privasi anda diutamakan',
          body: 'Data hanya boleh diakses oleh komuniti sekolah anda.',
          color: _lilac,
        ),
      ],
    ),
  );
}

class ModulePage extends StatefulWidget {
  const ModulePage({
    super.key,
    required this.module,
    required this.role,
    required this.school,
    this.user,
  });

  final String module;
  final String role;
  final String school;
  final User? user;

  @override
  State<ModulePage> createState() => _ModulePageState();
}

class _ModulePageState extends State<ModulePage> {
  String _filter = 'Semua';
  Stream<List<LostFoundItem>>? _lostItemsStream;
  Stream<List<SchoolServiceEntry>>? _reportsStream;
  Stream<List<SchoolServiceEntry>>? _bookingsStream;
  Stream<List<SchoolAnnouncement>>? _announcementsStream;
  Stream<List<SchoolTransferRequest>>? _userTransferRequestsStream;
  Stream<List<SchoolTransferRequest>>? _pendingTransferRequestsStream;
  final List<_LostItem> _lostItems = [
    _LostItem(
      'Botol air pastel',
      'Berhampiran kantin',
      'Hari ini, 10:20 pagi',
      Icons.water_drop_rounded,
      _mint,
    ),
    _LostItem(
      'Kotak pensel bunga',
      'Kelas 5 Bestari',
      'Semalam, 1:15 petang',
      Icons.edit_note_rounded,
      _pink,
    ),
    _LostItem(
      'Baju sukan sekolah',
      'Dewan terbuka',
      '3 Nov 2025',
      Icons.checkroom_rounded,
      _lilac,
    ),
  ];
  final List<_Report> _reports = [
    _Report('Kipas siling tidak berfungsi', 'Kelas 4 Cerdas', 'In Progress'),
    _Report('Paip air bocor', 'Tandas Blok B', 'Reported'),
  ];
  final List<_Booking> _bookings = [
    _Booking('Makmal Komputer', 'Jumaat, 7 Nov · 10:00 pagi', 'Pending'),
    _Booking('Projektor LCD', 'Isnin, 10 Nov · 8:00 pagi', 'Approved'),
  ];

  bool get _isAdmin => widget.role == 'Admin';

  @override
  void initState() {
    super.initState();
    _createLostItemsStream();
  }

  void _createLostItemsStream() {
    final user = widget.user;
    if (user == null) return;
    _lostItemsStream = LostFoundRepository(
      firestore: FirebaseFirestore.instance,
      schoolId: schoolIdForName(widget.school),
    ).watchItems();
    final schoolServices = SchoolServicesRepository(
      firestore: FirebaseFirestore.instance,
      schoolId: widget.school == _allSchoolsName
          ? _allSchoolsId
          : schoolIdForName(widget.school),
    );
    _reportsStream = schoolServices.watchFacilityReports();
    _bookingsStream = schoolServices.watchBookings();
    _announcementsStream = widget.role == 'Admin'
        ? schoolServices.watchAllAnnouncements()
        : schoolServices.watchAnnouncements();
    final transfers = SchoolTransferRepository(
      firestore: FirebaseFirestore.instance,
    );
    if (['Guru', 'PK HEM'].contains(widget.role)) {
      _userTransferRequestsStream = transfers.watchUserRequests(user.uid);
    } else if (_isAdmin) {
      _pendingTransferRequestsStream = transfers.watchPendingRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final isLost = module == 'Lost & Found';
    final isReport = module == 'Aduan fasiliti';
    final isBooking = module == 'Tempahan';
    final isParent = widget.role == 'Ibu bapa';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        title: Text(
          module == 'Semua servis' ? 'Semua servis' : module,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Cari',
            onPressed: () => _showSearch(context),
            icon: const Icon(Icons.search_rounded, color: _ink),
          ),
          const SizedBox(width: 5),
        ],
      ),
      floatingActionButton: !isParent && (isLost || isReport || isBooking)
          ? FloatingActionButton.extended(
              onPressed: () => _createEntry(context, isLost, isReport),
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                isLost
                    ? 'Laporkan barang'
                    : isReport
                    ? 'Buat aduan'
                    : 'Tempahan baharu',
              ),
            )
          : null,
      body: SafeArea(
        child: _PageScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SchoolScope(school: widget.school),
              const SizedBox(height: 16),
              if (module == 'Semua servis')
                _AllModules(
                  role: widget.role,
                  onTap: (value) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ModulePage(
                          module: value,
                          role: widget.role,
                          school: widget.school,
                          user: widget.user,
                        ),
                      ),
                    );
                  },
                )
              else if (isParent && !isLost && module != 'Pengumuman')
                const _InfoBanner(
                  icon: Icons.lock_outline_rounded,
                  title: 'Servis ini tidak tersedia',
                  body:
                      'Akaun Ibu bapa hanya boleh melihat Lost & Found dan Pengumuman.',
                  color: _peach,
                )
              else if (isLost)
                _buildLost(context)
              else if (isReport)
                _buildReports(context)
              else if (isBooking)
                _buildBookings(context)
              else if (module == 'Pengumuman')
                _buildNotices(context)
              else if (module == 'Permohonan tukar sekolah')
                _buildTeacherTransfers(context)
              else if (module == 'Kelulusan tukar sekolah')
                _buildAdminTransfers(context)
              else
                _AllModules(
                  role: widget.role,
                  onTap: (value) {
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLost(BuildContext context) {
    if (widget.user == null) return _buildLostItems(_lostItems);

    return StreamBuilder<List<LostFoundItem>>(
      stream: _lostItemsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _InfoBanner(
                icon: Icons.cloud_off_rounded,
                title: 'Barang belum dapat dimuat',
                body:
                    'Semak sambungan internet dan akses Firestore untuk projek ini.',
                color: _peach,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(_createLostItemsStream),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Cuba lagi'),
              ),
            ],
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: _purple)),
          );
        }

        final items = (snapshot.data ?? const <LostFoundItem>[])
            .map(
              (item) => _LostItem(
                item.title,
                item.location,
                item.dateLabel,
                Icons.inventory_2_rounded,
                _peach,
                description: item.description,
                id: item.id,
                claimed: item.claimed,
                imageBytes: item.imageBytes,
              ),
            )
            .toList();
        return _buildLostItems(items);
      },
    );
  }

  Widget _buildLostItems(List<_LostItem> items) {
    final visibleItems = items.where(
      (item) =>
          _filter == 'Semua' ||
          (_filter == 'Belum dituntut' && !item.claimed) ||
          (_filter == 'Dituntut' && item.claimed),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoBanner(
          icon: Icons.volunteer_activism_rounded,
          title: 'Jom bantu barang pulang ke tuannya',
          body: 'Barang yang dijumpai boleh dituntut di pejabat sekolah.',
          color: _peach,
        ),
        const SizedBox(height: 20),
        _filterChips(['Semua', 'Belum dituntut', 'Dituntut']),
        const SizedBox(height: 13),
        if (visibleItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                const Icon(Icons.inbox_rounded, color: _purple, size: 31),
                const SizedBox(height: 9),
                Text(
                  _filter == 'Semua'
                      ? 'Belum ada laporan barang'
                      : 'Tiada barang dalam kategori ini',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Barang yang dilaporkan akan dipaparkan untuk semua pengguna sekolah ini.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          for (final item in visibleItems)
            _SwipeToDeleteCard(
              itemKey: 'lost-${item.id ?? item.title}',
              title: item.title,
              enabled:
                  (widget.role == 'PK HEM' || widget.role == 'Admin') &&
                  widget.user != null &&
                  item.id != null,
              onDelete: () => LostFoundRepository(
                firestore: FirebaseFirestore.instance,
                schoolId: schoolIdForName(widget.school),
              ).deleteItem(item.id!),
              child: _LostItemCard(
                item: item,
                onClaim: () => _claimLostItem(item),
                canClaim: widget.role != 'Ibu bapa',
                onOpen: () => _showLostItemDetails(context, item),
              ),
            ),
      ],
    );
  }

  Widget _buildTeacherTransfers(BuildContext context) {
    final user = widget.user;
    final requestsStream = _userTransferRequestsStream;
    if (user == null || requestsStream == null) {
      return const _InfoBanner(
        icon: Icons.swap_horiz_rounded,
        title: 'Log masuk untuk memohon',
        body:
            'Guru dan PK HEM yang log masuk boleh memohon pertukaran sekolah atau jawatan.',
        color: _peach,
      );
    }

    return StreamBuilder<List<SchoolTransferRequest>>(
      stream: requestsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _InfoBanner(
            icon: Icons.cloud_off_rounded,
            title: 'Permohonan belum dapat dimuat',
            body: 'Semak sambungan internet dan akses Firestore.',
            color: _peach,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }
        final requests = snapshot.data ?? const <SchoolTransferRequest>[];
        final hasPending = requests.any(
          (request) => request.status == 'pending',
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _InfoBanner(
              icon: Icons.info_outline_rounded,
              title: 'Pertukaran perlu kelulusan admin',
              body:
                  'Sekolah dan jawatan hanya akan berubah selepas permohonan diluluskan.',
              color: _peach,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: hasPending ? null : _requestSchoolTransfer,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                hasPending
                    ? 'Permohonan sedang disemak'
                    : 'Mohon tukar sekolah atau jawatan',
              ),
            ),
            const SizedBox(height: 16),
            if (requests.isEmpty)
              Text(
                'Permohonan anda akan dipaparkan di sini.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final request in requests)
                _TransferRequestCard(request: request),
          ],
        );
      },
    );
  }

  Widget _buildAdminTransfers(BuildContext context) {
    final requestStream = _pendingTransferRequestsStream;
    if (!_isAdmin || widget.user == null || requestStream == null) {
      return const _InfoBanner(
        icon: Icons.lock_outline_rounded,
        title: 'Akses admin diperlukan',
        body:
            'Log masuk menggunakan akaun pentadbir untuk menyemak permohonan.',
        color: _peach,
      );
    }

    return StreamBuilder<List<SchoolTransferRequest>>(
      stream: requestStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _InfoBanner(
            icon: Icons.cloud_off_rounded,
            title: 'Permohonan belum dapat dimuat',
            body: 'Semak sambungan internet dan akses Firestore.',
            color: _peach,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }
        final requests = snapshot.data ?? const <SchoolTransferRequest>[];
        if (requests.isEmpty) {
          return const _InfoBanner(
            icon: Icons.check_circle_outline_rounded,
            title: 'Tiada permohonan menunggu',
            body:
                'Permohonan pertukaran daripada guru, ibu bapa dan PK HEM akan dipaparkan di sini.',
            color: _mint,
          );
        }
        return Column(
          children: [
            const _InfoBanner(
              icon: Icons.fact_check_rounded,
              title: 'Semak sebelum meluluskan',
              body:
                  'Kelulusan akan mengemas kini sekolah dan jawatan pada profil pemohon serta-merta.',
              color: _mint,
            ),
            const SizedBox(height: 14),
            for (final request in requests)
              _TransferRequestCard(
                request: request,
                onApprove: () => _reviewTransfer(request, approve: true),
                onReject: () => _reviewTransfer(request, approve: false),
              ),
          ],
        );
      },
    );
  }

  Future<void> _requestSchoolTransfer() async {
    final user = widget.user;
    if (user == null) return;
    final request = await showModalBottomSheet<_TransferRequestDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => SafeArea(
        top: false,
        child: _TransferRequestSheet(
          currentSchool: widget.school,
          currentRole: widget.role,
        ),
      ),
    );
    if (!mounted || request == null) return;
    try {
      await SchoolTransferRepository(
        firestore: FirebaseFirestore.instance,
      ).createRequest(
        teacherId: user.uid,
        teacherName: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : widget.role,
        teacherEmail: user.email ?? '',
        requesterRole: widget.role,
        toRole: request.role,
        fromSchoolName: widget.school,
        toSchoolName: request.school,
        reason: request.reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permohonan dihantar kepada admin.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permohonan tidak dapat dihantar (${error.code}).'),
        ),
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permohonan tidak sah: ${error.message}')),
      );
    }
  }

  Future<void> _reviewTransfer(
    SchoolTransferRequest request, {
    required bool approve,
  }) async {
    final admin = widget.user;
    if (admin == null) return;
    try {
      await SchoolTransferRepository(
        firestore: FirebaseFirestore.instance,
      ).reviewRequest(request: request, adminId: admin.uid, approve: approve);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Permohonan diluluskan dan profil pemohon dikemas kini.'
                : 'Permohonan ditolak.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keputusan tidak dapat disimpan (${error.code}).'),
        ),
      );
    }
  }

  void _showLostItemDetails(BuildContext context, _LostItem item) {
    showDialog<void>(
      context: context,
      builder: (_) => _LostItemDetailsDialog(
        item: item,
        repository: widget.user == null
            ? null
            : LostFoundRepository(
                firestore: FirebaseFirestore.instance,
                schoolId: schoolIdForName(widget.school),
              ),
        user: widget.user,
      ),
    );
  }

  Future<void> _claimLostItem(_LostItem item) async {
    final user = widget.user;
    if (user == null) {
      setState(() => item.claimed = true);
      return;
    }
    if (item.id == null) return;

    try {
      await LostFoundRepository(
        firestore: FirebaseFirestore.instance,
        schoolId: schoolIdForName(widget.school),
      ).claimItem(itemId: item.id!, userId: user.uid);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barang tidak dapat dikemas kini (${error.code}).'),
        ),
      );
    }
  }

  Widget _buildReports(BuildContext context) {
    final stream = _reportsStream;
    if (stream == null) return _buildReportList(_reports);
    return StreamBuilder<List<SchoolServiceEntry>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _serviceLoadError('Aduan');
        if (!snapshot.hasData) return _serviceLoading();
        return _buildReportList(
          snapshot.data!
              .map(
                (item) =>
                    _Report(item.title, item.detail, item.status, id: item.id),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildReportList(List<_Report> reports) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _InfoBanner(
        icon: Icons.handyman_rounded,
        title: 'Bantu sekolah lebih selesa',
        body: 'Sertakan lokasi dan gambar supaya tindakan lebih cepat.',
        color: _mint,
      ),
      const SizedBox(height: 20),
      _filterChips(['Semua', 'Reported', 'In Progress', 'Done']),
      const SizedBox(height: 13),
      if (reports.isEmpty)
        const _InfoBanner(
          icon: Icons.inbox_outlined,
          title: 'Belum ada aduan',
          body: 'Aduan fasiliti baharu akan dipaparkan di sini.',
          color: _lilac,
        ),
      for (final report in reports.where(
        (item) => _filter == 'Semua' || item.status == _filter,
      ))
        _SwipeToDeleteCard(
          itemKey: 'report-${report.id ?? report.title}',
          title: report.title,
          enabled:
              (widget.role == 'PK HEM' || widget.role == 'Admin') &&
              widget.user != null &&
              report.id != null,
          onDelete: () => SchoolServicesRepository(
            firestore: FirebaseFirestore.instance,
            schoolId: schoolIdForName(widget.school),
          ).deleteFacilityReport(report.id!),
          child: _ReportCard(
            report: report,
            canManage: widget.role == 'PK HEM' || widget.role == 'Admin',
            onStatusChanged: (status) => _setEntryStatus(
              isBooking: false,
              itemId: report.id,
              status: status,
              fallback: () => setState(() => report.status = status),
            ),
          ),
        ),
    ],
  );

  Widget _buildBookings(BuildContext context) {
    final stream = _bookingsStream;
    if (stream == null) return _buildBookingList(_bookings);
    return StreamBuilder<List<SchoolServiceEntry>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _serviceLoadError('Tempahan');
        if (!snapshot.hasData) return _serviceLoading();
        return _buildBookingList(
          snapshot.data!
              .map(
                (item) =>
                    _Booking(item.title, item.detail, item.status, id: item.id),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildBookingList(List<_Booking> bookings) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _InfoBanner(
        icon: Icons.event_available_rounded,
        title: 'Rancang penggunaan kemudahan',
        body: 'Semak tempahan supaya tiada pertindihan.',
        color: _lilac,
      ),
      const SizedBox(height: 20),
      _filterChips(['Semua', 'Pending', 'Approved']),
      const SizedBox(height: 13),
      if (bookings.isEmpty)
        const _InfoBanner(
          icon: Icons.inbox_outlined,
          title: 'Belum ada tempahan',
          body: 'Permohonan tempahan baharu akan dipaparkan di sini.',
          color: _peach,
        ),
      for (final booking in bookings.where(
        (item) => _filter == 'Semua' || item.status == _filter,
      ))
        _SwipeToDeleteCard(
          itemKey: 'booking-${booking.id ?? booking.title}',
          title: booking.title,
          enabled:
              (widget.role == 'PK HEM' || widget.role == 'Admin') &&
              widget.user != null &&
              booking.id != null,
          onDelete: () => SchoolServicesRepository(
            firestore: FirebaseFirestore.instance,
            schoolId: schoolIdForName(widget.school),
          ).deleteBooking(booking.id!),
          child: _BookingCard(
            booking: booking,
            canManage: widget.role == 'PK HEM' || widget.role == 'Admin',
            onStatusChanged: (status) => _setEntryStatus(
              isBooking: true,
              itemId: booking.id,
              status: status,
              fallback: () => setState(() => booking.status = status),
            ),
          ),
        ),
      const SizedBox(height: 7),
      Text(
        'Tempahan perlu mendapat kelulusan PK HEM sekolah.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _buildNotices(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.role == 'PK HEM' || widget.role == 'Admin')
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: widget.user == null
                ? null
                : () => _showAnnouncementEditor(
                    context,
                    widget.school,
                    widget.user,
                    isGlobal: widget.role == 'Admin',
                  ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah pengumuman'),
          ),
        ),
      if (_announcementsStream == null)
        const _NoticeTile(
          category: 'PENTING',
          title: 'Jadual peperiksaan pertengahan tahun',
          body:
              'Semua murid diminta menyemak jadual peperiksaan yang telah dikemaskini. Sila hubungi guru kelas jika terdapat sebarang pertanyaan.',
          date: 'Hari ini · 9:30 pagi',
          color: _lilac,
          icon: Icons.menu_book_rounded,
        )
      else
        _SchoolAnnouncementsView(
          stream: _announcementsStream!,
          canDelete:
              (widget.role == 'PK HEM' || widget.role == 'Admin') &&
              widget.user != null,
          canDeleteGlobal: widget.role == 'Admin',
          onDelete: (notice) => SchoolServicesRepository(
            firestore: FirebaseFirestore.instance,
            schoolId: notice.schoolId,
          ).deleteAnnouncement(notice.id),
        ),
    ],
  );

  Widget _serviceLoading() => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _serviceLoadError(String label) => _InfoBanner(
    icon: Icons.error_outline_rounded,
    title: '$label tidak dapat dimuat',
    body: 'Sila semak sambungan atau kebenaran Firestore.',
    color: _peach,
  );

  Future<void> _setEntryStatus({
    required bool isBooking,
    required String? itemId,
    required String status,
    required VoidCallback fallback,
  }) async {
    final user = widget.user;
    if (user == null || itemId == null) {
      fallback();
      return;
    }
    try {
      final repository = SchoolServicesRepository(
        firestore: FirebaseFirestore.instance,
        schoolId: schoolIdForName(widget.school),
      );
      if (isBooking) {
        await repository.updateBookingStatus(
          itemId: itemId,
          status: status,
          userId: user.uid,
        );
      } else {
        await repository.updateFacilityReportStatus(
          itemId: itemId,
          status: status,
          userId: user.uid,
        );
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status gagal dikemas kini (${error.code}).')),
      );
    }
  }

  Widget _filterChips(List<String> labels) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: labels.map((label) {
        final selected = _filter == label;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => setState(() => _filter = label),
            labelStyle: TextStyle(
              color: selected ? Colors.white : _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: Colors.white,
            selectedColor: _purple,
            side: BorderSide(
              color: selected ? _purple : const Color(0xFFE7DDD2),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Future<void> _createEntry(
    BuildContext context,
    bool isLost,
    bool isReport,
  ) async {
    final result = await showModalBottomSheet<_EntryResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => SafeArea(
        top: false,
        child: _EntrySheet(isLost: isLost, isReport: isReport),
      ),
    );
    if (!context.mounted || result == null) return;
    final user = widget.user;
    if (isLost && user != null) {
      try {
        await LostFoundRepository(
          firestore: FirebaseFirestore.instance,
          schoolId: schoolIdForName(widget.school),
        ).addItem(
          title: result.title,
          description: result.description,
          location: result.location,
          userId: user.uid,
          imageBytes: result.imageBytes,
        );
      } on FirebaseException catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan tidak dapat disimpan (${error.code}).'),
          ),
        );
        return;
      }
    }
    if (user != null && !isLost) {
      try {
        final repository = SchoolServicesRepository(
          firestore: FirebaseFirestore.instance,
          schoolId: schoolIdForName(widget.school),
        );
        if (isReport) {
          await repository.addFacilityReport(
            title: result.title,
            location: result.location,
            userId: user.uid,
          );
        } else {
          await repository.addBooking(
            title: result.title,
            date: result.location,
            startTime: result.startTime!,
            endTime: result.endTime!,
            userId: user.uid,
          );
        }
      } on FirebaseException catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permohonan tidak dapat disimpan (${error.code}).'),
          ),
        );
        return;
      }
    }

    if (user == null) {
      setState(() {
        if (isLost) {
          _lostItems.insert(
            0,
            _LostItem(
              result.title,
              result.location,
              'Baru sahaja',
              Icons.inventory_2_rounded,
              _peach,
              description: result.description,
              imageBytes: result.imageBytes,
            ),
          );
        } else if (isReport) {
          _reports.insert(
            0,
            _Report(result.title, result.location, 'Reported'),
          );
        } else {
          _bookings.insert(
            0,
            _Booking(
              result.title,
              '${result.location} · ${result.startTime} – ${result.endTime}',
              'Pending',
            ),
          );
        }
      });
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBookingText(isLost, isReport)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String isBookingText(bool isLost, bool isReport) => isLost
      ? 'Barang berjaya ditambah.'
      : isReport
      ? 'Aduan berjaya dihantar.'
      : 'Permohonan tempahan dihantar.';

  void _showSearch(BuildContext context) {
    showSearch<void>(context: context, delegate: _SchoolSearchDelegate());
  }
}

class _LostItem {
  _LostItem(
    this.title,
    this.location,
    this.date,
    this.icon,
    this.color, {
    this.description = '',
    this.id,
    this.claimed = false,
    this.imageBytes,
  });
  final String? id;
  final String title;
  final String description;
  final String location;
  final String date;
  final IconData icon;
  final Color color;
  bool claimed = false;
  final Uint8List? imageBytes;
}

class _Report {
  _Report(this.title, this.location, this.status, {this.id});
  final String? id;
  final String title;
  final String location;
  String status;
}

class _Booking {
  _Booking(this.title, this.date, this.status, {this.id});
  final String? id;
  final String title;
  final String date;
  String status;
}

class _SwipeToDeleteCard extends StatelessWidget {
  const _SwipeToDeleteCard({
    required this.itemKey,
    required this.title,
    required this.enabled,
    required this.onDelete,
    required this.child,
  });

  final String itemKey;
  final String title;
  final bool enabled;
  final Future<void> Function() onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(itemKey),
    direction: enabled ? DismissDirection.endToStart : DismissDirection.none,
    background: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(21),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white),
          SizedBox(height: 4),
          Text('Padam', style: TextStyle(color: Colors.white)),
        ],
      ),
    ),
    confirmDismiss: (_) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Are you sure to delete?'),
          content: Text(
            '“$title” akan dipadam. Tindakan ini tidak boleh dibuat asal.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Padam'),
            ),
          ],
        ),
      );
      if (confirmed != true) return false;
      try {
        await onDelete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berjaya dipadam.')),
          );
        }
        return true;
      } on FirebaseException catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data tidak dapat dipadam (${error.code}).'),
            ),
          );
        }
        return false;
      }
    },
    child: child,
  );
}

class _LostItemDetailsDialog extends StatefulWidget {
  const _LostItemDetailsDialog({
    required this.item,
    required this.repository,
    required this.user,
  });

  final _LostItem item;
  final LostFoundRepository? repository;
  final User? user;

  @override
  State<_LostItemDetailsDialog> createState() => _LostItemDetailsDialogState();
}

class _LostItemDetailsDialogState extends State<_LostItemDetailsDialog> {
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item.title),
    content: SizedBox(
      width: double.maxFinite,
      height: MediaQuery.sizeOf(context).height * 0.62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.imageBytes case final imageBytes?)
                    GestureDetector(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (dialogContext) => Dialog.fullscreen(
                          backgroundColor: Colors.black,
                          child: Stack(
                            children: [
                              Center(
                                child: InteractiveViewer(
                                  minScale: 0.7,
                                  maxScale: 5,
                                  child: Image.memory(imageBytes),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: IconButton(
                                  tooltip: 'Tutup gambar',
                                  onPressed: () => Navigator.pop(dialogContext),
                                  color: Colors.white,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          imageBytes,
                          width: double.infinity,
                          height: 190,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (widget.item.imageBytes != null)
                    const SizedBox(height: 12),
                  Text(
                    'Penerangan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.description.isEmpty
                        ? widget.item.title
                        : widget.item.description,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Lokasi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(widget.item.location),
                  const SizedBox(height: 6),
                  Text(
                    widget.item.date,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  _buildComments(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.user != null && widget.item.id != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lilac.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _commentController,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          'Kenal pemilik barang ini? Tulis komen di sini...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _sending ? null : _submitComment,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Hantar komen'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Text('Log masuk untuk meninggalkan komen.'),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Tutup'),
      ),
    ],
  );

  Widget _buildComments() {
    final itemId = widget.item.id;
    final repository = widget.repository;
    if (itemId == null || repository == null) {
      return _commentsPanel(
        context,
        message: 'Log masuk untuk melihat komen bagi barang ini.',
      );
    }
    return StreamBuilder<List<LostFoundComment>>(
      stream: repository.watchComments(itemId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _commentsPanel(
            context,
            message: 'Komen tidak dapat dimuat. Cuba lagi kemudian.',
          );
        }
        if (!snapshot.hasData) {
          return _commentsPanel(
            context,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(color: _purple),
              ),
            ),
          );
        }
        final comments = snapshot.data!;
        return _commentsPanel(
          context,
          count: comments.length,
          child: comments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.forum_outlined, size: 28, color: _purple),
                        SizedBox(height: 7),
                        Text('Belum ada komen. Mulakan perbualan!'),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final comment in comments)
                      _LostFoundCommentTile(comment: comment),
                  ],
                ),
        );
      },
    );
  }

  Widget _commentsPanel(
    BuildContext context, {
    int? count,
    String? message,
    Widget? child,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _lilac.withValues(alpha: 0.65)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.forum_rounded, color: _purple, size: 20),
            const SizedBox(width: 8),
            Text('Komen', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (count != null) _StatusPill(label: '$count', color: _lilac),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Komen ini boleh dilihat oleh warga sekolah yang sama.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (message != null)
          Text(message, style: Theme.of(context).textTheme.bodySmall)
        else
          child!,
      ],
    ),
  );

  Future<void> _submitComment() async {
    final user = widget.user;
    final itemId = widget.item.id;
    final repository = widget.repository;
    final message = _commentController.text.trim();
    if (user == null ||
        itemId == null ||
        repository == null ||
        message.isEmpty ||
        _sending) {
      return;
    }

    setState(() => _sending = true);
    try {
      final displayName = user.displayName?.trim();
      await repository.addComment(
        itemId: itemId,
        userId: user.uid,
        authorName: displayName?.isNotEmpty == true
            ? displayName!
            : 'Pengguna sekolah',
        message: message,
      );
      if (!mounted) return;
      _commentController.clear();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Komen gagal dihantar (${error.code}).')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _LostFoundCommentTile extends StatelessWidget {
  const _LostFoundCommentTile({required this.comment});

  final LostFoundComment comment;

  @override
  Widget build(BuildContext context) {
    final author = comment.authorName.trim().isEmpty
        ? 'Pengguna sekolah'
        : comment.authorName.trim();
    final initial = author.substring(0, 1).toUpperCase();
    final date = comment.createdAt.millisecondsSinceEpoch == 0
        ? 'Baru sahaja'
        : '${comment.createdAt.day}/${comment.createdAt.month}/${comment.createdAt.year} · '
              '${comment.createdAt.hour.toString().padLeft(2, '0')}:'
              '${comment.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _lilac.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: _lilac,
            child: Text(
              initial,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        author,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _ink.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(comment.message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LostItemCard extends StatelessWidget {
  const _LostItemCard({
    required this.item,
    required this.onClaim,
    required this.canClaim,
    required this.onOpen,
  });
  final _LostItem item;
  final Future<void> Function() onClaim;
  final bool canClaim;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(17),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                width: 58,
                height: 58,
                child: item.imageBytes == null
                    ? ColoredBox(
                        color: item.color,
                        child: Icon(item.icon, color: _ink, size: 27),
                      )
                    : Image.memory(item.imageBytes!, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  item.location,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(item.date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.claimed)
                const _StatusPill(label: 'Dituntut', color: _mint)
              else if (canClaim)
                TextButton(
                  onPressed: () => _confirmClaim(context),
                  child: const Text('Tuntut'),
                ),
              TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Komen'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _confirmClaim(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tuntut barang ini?'),
        content: const Text(
          'Sila ambil barang di pejabat sekolah dan tunjukkan makluman ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, tuntut'),
          ),
        ],
      ),
    );
    if (yes == true) await onClaim();
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.canManage,
    required this.onStatusChanged,
  });
  final _Report report;
  final bool canManage;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.handyman_rounded, color: _ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  report.location,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _StatusPill(
                  label: report.status,
                  color: _statusColor(report.status),
                ),
              ],
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: _muted),
              onSelected: onStatusChanged,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Reported', child: Text('Reported')),
                PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
                PopupMenuItem(value: 'Done', child: Text('Done')),
              ],
            ),
        ],
      ),
    ),
  );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.canManage,
    required this.onStatusChanged,
  });
  final _Booking booking;
  final bool canManage;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: _lilac,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: _purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  booking.date,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _StatusPill(
                  label: booking.status,
                  color: _statusColor(booking.status),
                ),
              ],
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: _muted),
              onSelected: onStatusChanged,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Pending', child: Text('Pending')),
                PopupMenuItem(value: 'Approved', child: Text('Approved')),
              ],
            ),
        ],
      ),
    ),
  );
}

class _EntrySheet extends StatefulWidget {
  const _EntrySheet({required this.isLost, required this.isReport});
  final bool isLost;
  final bool isReport;

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Uint8List? _imageBytes;

  String get _title => widget.isLost
      ? 'Laporkan barang dijumpai'
      : widget.isReport
      ? 'Buat aduan fasiliti'
      : 'Tempahan baharu';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      padding: const EdgeInsets.fromLTRB(21, 12, 21, 24),
      decoration: const BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDED5CA),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 19),
            Text(_title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 17),
            _FormLabel(
              label: widget.isLost
                  ? 'Nama barang'
                  : widget.isReport
                  ? 'Apa yang rosak?'
                  : 'Ruang atau peralatan',
            ),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                widget.isLost
                    ? 'Contoh: Botol air warna biru'
                    : widget.isReport
                    ? 'Contoh: Kipas kelas rosak'
                    : 'Contoh: Makmal Komputer',
              ),
            ),
            if (widget.isLost) ...[
              const SizedBox(height: 14),
              const _FormLabel(label: 'Penerangan barang (pilihan)'),
              TextField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                maxLength: 300,
                decoration: _inputDecoration(
                  'Contoh: Gam warna biru, masih penuh',
                ),
              ),
            ],
            const SizedBox(height: 14),
            _FormLabel(
              label: widget.isLost
                  ? 'Lokasi dijumpai'
                  : widget.isReport
                  ? 'Lokasi kerosakan'
                  : 'Tarikh tempahan',
            ),
            TextField(
              controller: _locationController,
              textCapitalization: TextCapitalization.sentences,
              onTap: !widget.isLost && !widget.isReport
                  ? () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                        initialDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(
                          () => _selectedDate =
                              '${date.day}/${date.month}/${date.year}',
                        );
                      }
                    }
                  : null,
              readOnly: !widget.isLost && !widget.isReport,
              decoration:
                  _inputDecoration(
                    widget.isLost
                        ? 'Contoh: Kantin sekolah'
                        : widget.isReport
                        ? 'Contoh: Blok A, tingkat 2'
                        : _selectedDate ?? 'Pilih tarikh',
                  ).copyWith(
                    suffixIcon: !widget.isLost && !widget.isReport
                        ? const Icon(Icons.calendar_month_outlined)
                        : null,
                  ),
            ),
            if (!widget.isLost && !widget.isReport) ...[
              const SizedBox(height: 14),
              const _FormLabel(label: 'Masa tempahan'),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectBookingTime(isStart: true),
                      child: Text(
                        'Dari ${_timeLabel(_startTime) ?? 'Pilih masa'}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectBookingTime(isStart: false),
                      child: Text(
                        'Sampai ${_timeLabel(_endTime) ?? 'Pilih masa'}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (widget.isLost) ...[
              const SizedBox(height: 14),
              const _FormLabel(label: 'Gambar barang (pilihan)'),
              if (_imageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      _imageBytes!,
                      width: double.infinity,
                      height: 170,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _chooseImageSource,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  _imageBytes == null
                      ? 'Ambil gambar / pilih foto'
                      : 'Tukar foto',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: Color(0xFFD9C8B8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  minimumSize: const Size(double.infinity, 47),
                ),
              ),
            ],
            const SizedBox(height: 19),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 51),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                widget.isLost
                    ? 'Hantar laporan'
                    : widget.isReport
                    ? 'Hantar aduan'
                    : 'Hantar tempahan',
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _paper,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil gambar dengan kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih daripada galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 55,
      );
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxLostItemImageBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Saiz gambar masih terlalu besar. Sila pilih gambar yang lebih kecil.',
            ),
          ),
        );
        return;
      }
      setState(() => _imageBytes = bytes);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar tidak dapat dibuka. Cuba lagi.')),
      );
    }
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila isi maklumat yang diperlukan.')),
      );
      return;
    }
    if ((widget.isLost || widget.isReport) &&
        _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila isi lokasi yang berkaitan.')),
      );
      return;
    }
    if (!widget.isLost && !widget.isReport && _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila pilih tarikh tempahan.')),
      );
      return;
    }
    if (!widget.isLost &&
        !widget.isReport &&
        (_startTime == null || _endTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila pilih masa mula dan masa tamat.')),
      );
      return;
    }
    if (!widget.isLost &&
        !widget.isReport &&
        _minutesSinceMidnight(_endTime!) <=
            _minutesSinceMidnight(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masa tamat mesti selepas masa mula.')),
      );
      return;
    }
    Navigator.pop(
      context,
      _EntryResult(
        _titleController.text.trim(),
        widget.isLost || widget.isReport
            ? _locationController.text.trim()
            : _selectedDate!,
        startTime: _timeLabel(_startTime),
        endTime: _timeLabel(_endTime),
        description: widget.isLost ? _descriptionController.text.trim() : '',
        imageBytes: widget.isLost ? _imageBytes : null,
      ),
    );
  }

  Future<void> _selectBookingTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart
          ? _startTime ?? const TimeOfDay(hour: 9, minute: 0)
          : _endTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
    });
  }
}

class _EntryResult {
  const _EntryResult(
    this.title,
    this.location, {
    this.startTime,
    this.endTime,
    this.description = '',
    this.imageBytes,
  });
  final String title;
  final String location;
  final String? startTime;
  final String? endTime;
  final String description;
  final Uint8List? imageBytes;
}

String? _timeLabel(TimeOfDay? time) => time == null
    ? null
    : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

int _minutesSinceMidnight(TimeOfDay time) => time.hour * 60 + time.minute;

class _TransferRequestDraft {
  const _TransferRequestDraft({
    required this.school,
    required this.role,
    required this.reason,
  });

  final String school;
  final String role;
  final String reason;
}

class _TransferRequestSheet extends StatefulWidget {
  const _TransferRequestSheet({
    required this.currentSchool,
    required this.currentRole,
  });

  final String currentSchool;
  final String currentRole;

  @override
  State<_TransferRequestSheet> createState() => _TransferRequestSheetState();
}

class _TransferRequestSheetState extends State<_TransferRequestSheet> {
  late String _school;
  late String _role;
  final _reasonController = TextEditingController();

  List<String> get _availableSchools => supportedSchools;

  @override
  void initState() {
    super.initState();
    _school = supportedSchools.contains(widget.currentSchool)
        ? widget.currentSchool
        : _availableSchools.first;
    _role = widget.currentRole;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sila nyatakan sebab pertukaran sekolah.'),
        ),
      );
      return;
    }
    if (_school == widget.currentSchool && _role == widget.currentRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih sekolah atau jawatan yang berbeza.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _TransferRequestDraft(school: _school, role: _role, reason: reason),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      padding: const EdgeInsets.fromLTRB(21, 12, 21, 24),
      decoration: const BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDED5CA),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Permohonan tukar sekolah atau jawatan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 15),
            const _FormLabel(label: 'Sekolah baharu'),
            DropdownButtonFormField<String>(
              initialValue: _school,
              isExpanded: true,
              decoration: _inputDecoration('Pilih sekolah'),
              items: [
                for (final school in _availableSchools)
                  DropdownMenuItem(value: school, child: Text(school)),
              ],
              onChanged: (school) {
                if (school != null) setState(() => _school = school);
              },
            ),
            const SizedBox(height: 14),
            const _FormLabel(label: 'Jawatan baharu'),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: _inputDecoration('Pilih jawatan'),
              items: const [
                DropdownMenuItem(value: 'Guru', child: Text('Guru')),
                DropdownMenuItem(value: 'Ibu bapa', child: Text('Ibu bapa')),
                DropdownMenuItem(value: 'PK HEM', child: Text('PK HEM')),
              ],
              onChanged: (role) {
                if (role != null) setState(() => _role = role);
              },
            ),
            const SizedBox(height: 14),
            const _FormLabel(label: 'Sebab permohonan'),
            TextField(
              controller: _reasonController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              maxLength: 500,
              decoration: _inputDecoration('Nyatakan sebab pertukaran...'),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 51),
              ),
              child: const Text('Hantar permohonan'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TransferRequestCard extends StatelessWidget {
  const _TransferRequestCard({
    required this.request,
    this.onApprove,
    this.onReject,
  });

  final SchoolTransferRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.teacherName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (request.teacherEmail.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              '${request.requesterRole}${request.teacherEmail.isEmpty ? '' : ' · ${request.teacherEmail}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
          Text('Jawatan: ${request.requesterRole} → ${request.toRole}'),
          const SizedBox(height: 4),
          Text('Dari: ${request.fromSchoolName}'),
          const SizedBox(height: 4),
          Text('Ke: ${request.toSchoolName}'),
          const SizedBox(height: 8),
          Text(
            request.reason,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _ink),
          ),
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onReject, child: const Text('Tolak')),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Luluskan'),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            _StatusPill(
              label: switch (request.status) {
                'approved' => 'Diluluskan',
                'rejected' => 'Ditolak',
                _ => 'Menunggu kelulusan',
              },
              color: request.status == 'approved'
                  ? _mint
                  : request.status == 'rejected'
                  ? _pink
                  : _peach,
            ),
          ],
        ],
      ),
    ),
  );
}

class _AllModules extends StatelessWidget {
  const _AllModules({required this.onTap, required this.role});
  final ValueChanged<String> onTap;
  final String role;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ModuleListTile(
        icon: Icons.backpack_rounded,
        color: _peach,
        title: 'Lost & Found',
        subtitle: 'Cari atau laporkan barang tercicir',
        onTap: () => onTap('Lost & Found'),
      ),
      if (role != 'Ibu bapa')
        _ModuleListTile(
          icon: Icons.handyman_rounded,
          color: _mint,
          title: 'Aduan fasiliti',
          subtitle: 'Laporkan kerosakan di sekolah',
          onTap: () => onTap('Aduan fasiliti'),
        ),
      if (role != 'Ibu bapa')
        _ModuleListTile(
          icon: Icons.calendar_month_rounded,
          color: _lilac,
          title: 'Tempahan',
          subtitle: 'Tempah ruang atau peralatan',
          onTap: () => onTap('Tempahan'),
        ),
      _ModuleListTile(
        icon: Icons.campaign_rounded,
        color: _pink,
        title: 'Pengumuman',
        subtitle: 'Baca makluman rasmi sekolah',
        onTap: () => onTap('Pengumuman'),
      ),
    ],
  );
}

class _SchoolScope extends StatelessWidget {
  const _SchoolScope({required this.school});
  final String school;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _mint.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.shield_rounded, color: Color(0xFF71836C), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            school,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF5F725A),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF71836C)),
      ],
    ),
  );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 49,
        height: 49,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Icon(icon, color: _ink, size: 24),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 3),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}

class _ModuleListTile extends StatelessWidget {
  const _ModuleListTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: _ink, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.locked = false,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 20, color: _ink),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
              color: _muted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.67),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _ink, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _ink.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TinyLabel extends StatelessWidget {
  const _TinyLabel({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 7, color: color),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.45,
        ),
      ),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _ink,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFF0EAE2)),
          ),
          child: Icon(icon, color: _ink, size: 22),
        ),
        if (badge)
          Positioned(
            top: 7,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFC78978),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    ),
  );
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
    ),
  );
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    onTapDown: widget.onTap == null
        ? null
        : (_) => setState(() => _pressed = true),
    onTapCancel: widget.onTap == null
        ? null
        : () => setState(() => _pressed = false),
    onTapUp: widget.onTap == null
        ? null
        : (_) => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final desktop = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final bottomClearance = desktop
        ? 40.0
        : 152 + MediaQuery.viewPaddingOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          desktop ? 34 : 20,
          desktop ? 28 : 17,
          desktop ? 34 : 20,
          bottomClearance,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: desktop ? 1220 : 620),
            child: child,
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: const Color(0xFFF0EAE2)),
);

Color _statusColor(String status) {
  switch (status) {
    case 'Approved':
    case 'Done':
    case 'Dituntut':
      return _mint;
    case 'In Progress':
      return _lilac;
    case 'Reported':
      return _peach;
    default:
      return _peach;
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE7DDD2)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE7DDD2)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: _purple, width: 1.4),
  ),
);

class _SchoolSearchDelegate extends SearchDelegate<void> {
  @override
  String get searchFieldLabel => 'Cari barang, notis...';

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: _paper,
      foregroundColor: _ink,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: _muted),
      border: InputBorder.none,
    ),
  );

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      onPressed: () => query = '',
      icon: const Icon(Icons.close_rounded),
    ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back_rounded),
  );

  @override
  Widget buildResults(BuildContext context) => _searchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _searchResults(context);

  Widget _searchResults(BuildContext context) {
    const all = [
      ('Lost & Found', 'Barang hilang dan dijumpai', Icons.backpack_rounded),
      (
        'Aduan fasiliti',
        'Kerosakan di kawasan sekolah',
        Icons.handyman_rounded,
      ),
      ('Tempahan', 'Bilik dan peralatan sekolah', Icons.calendar_month_rounded),
      ('Pengumuman', 'Makluman rasmi sekolah', Icons.campaign_rounded),
    ];
    final results = all
        .where(
          (entry) =>
              query.isEmpty ||
              entry.$1.toLowerCase().contains(query.toLowerCase()) ||
              entry.$2.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    if (results.isEmpty) {
      return const Center(child: Text('Tiada hasil carian.'));
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        for (final result in results)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _lilac,
              child: Icon(result.$3, color: _purple),
            ),
            title: Text(result.$1),
            subtitle: Text(result.$2),
          ),
      ],
    );
  }
}

void _showMessage(BuildContext context, String title, String message) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.auto_awesome_rounded, color: _purple),
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Faham'),
        ),
      ],
    ),
  );
}
