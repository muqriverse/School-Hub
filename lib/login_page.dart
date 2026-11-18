import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

const _loginInk = Color(0xFF4A4038);
const _loginMuted = Color(0xFF8A7E74);
const _loginPurple = Color(0xFF9A7E68);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.firebaseConfigured});

  final bool firebaseConfigured;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigningIn = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF0E6D9), Color(0xFFE8D8CB)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: _loginPurple,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 21),
                    const Text(
                      'SchoolHub',
                      style: TextStyle(
                        color: _loginPurple,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Semua urusan sekolah, kini lebih mudah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _loginMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xFFF0EAE2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat datang 🌷',
                            style: TextStyle(
                              color: _loginInk,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Log masuk untuk melihat maklumat sekolah anda.',
                            style: TextStyle(
                              color: _loginMuted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 21),
                          if (_errorMessage != null) ...[
                            _MessageBox(
                              icon: Icons.error_outline_rounded,
                              text: _errorMessage!,
                              isError: true,
                            ),
                            const SizedBox(height: 13),
                          ],
                          if (!widget.firebaseConfigured) ...[
                            const _MessageBox(
                              icon: Icons.info_outline_rounded,
                              text:
                                  'Sambungan Google belum disediakan. Ikut langkah setup Firebase dalam README projek ini.',
                            ),
                            const SizedBox(height: 15),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed:
                                  widget.firebaseConfigured && !_isSigningIn
                                  ? _signInWithGoogle
                                  : null,
                              icon: _isSigningIn
                                  ? const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'G',
                                      style: TextStyle(
                                        color: Color(0xFF4285F4),
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                              label: Text(
                                widget.firebaseConfigured
                                    ? _isSigningIn
                                          ? 'Sedang log masuk...'
                                          : 'Teruskan dengan Google'
                                    : 'Google belum disambungkan',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _loginInk,
                                side: const BorderSide(
                                  color: Color(0xFFE7DDD2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: _loginMuted,
                              ),
                              SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'Maklumat dipaparkan mengikut sekolah yang dipautkan kepada akaun anda.',
                                  style: TextStyle(
                                    color: _loginMuted,
                                    fontSize: 11,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'SchoolHub · Untuk komuniti sekolah',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _loginMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final account = await GoogleSignIn.instance.authenticate();
        final idToken = account.authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          setState(() {
            _errorMessage =
                'Google tidak memulangkan token log masuk. Semak konfigurasi Google Sign-In dalam Firebase.';
          });
          return;
        }
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorMessage =
            error.message ??
            'Log masuk gagal (${error.code}). Semak tetapan Google dalam Firebase.';
      });
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return;
      setState(() {
        _errorMessage =
            error.description ??
            'Log masuk Google gagal (${error.code.name}). Semak konfigurasi aplikasi.';
      });
    } on PlatformException catch (error) {
      setState(() {
        _errorMessage =
            error.message ??
            'Log masuk Google gagal. Semak konfigurasi platform aplikasi.';
      });
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isError ? const Color(0xFFFFEEEE) : const Color(0xFFF0E8DE),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isError ? const Color(0xFFAD5050) : _loginPurple,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isError
                  ? const Color(0xFF8F3D3D)
                  : const Color(0xFF665447),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}
