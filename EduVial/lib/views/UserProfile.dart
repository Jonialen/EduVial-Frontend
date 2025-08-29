import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:eduvial/models/user.dart';
import 'package:eduvial/controllers/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool cargando = true;
  String? error;
  User? _user;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      // 1) Cargar cache
      final raw = await auth_controller.loadCachedUserJson();
      if (raw != null) {
        try {
          final cached = User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          if (mounted) setState(() => _user = cached);
        } catch (_) {}
      }

      // 2) Refrescar desde backend
      final me = await auth_controller.getMeBasic()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        return {'success': false, 'error': 'Timeout al consultar el perfil'};
      });

      if (me['success'] == true && me['user'] != null) {
        final fresh = User.fromJson(me['user'] as Map<String, dynamic>);
        await auth_controller.saveCachedUserJson(jsonEncode(fresh.toJson()));
        if (mounted) setState(() => _user = fresh);
      } else if (me['error'] != null && mounted) {
        setState(() => error = me['error'].toString());
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Error: $e');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando && _user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final nombre = _user?.name ?? '—';
    final correo = _user?.email ?? '—';
    final rol    = (_user?.role?.isNotEmpty ?? false) ? _user!.role : '—';
    final puntos = _user?.points?.toString() ?? '—'; // puede venir null en login

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _initUser,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                color: const Color(0xFF1976D2),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Perfil de Usuario',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Datos personales',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),

              // Contenido
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 60, color: Color(0xFF1976D2)),
                    ),
                    const SizedBox(height: 20),

                    if (error != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(error!, style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Nombre
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Nombre:',
                        style: TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        nombre,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Divider(),

                    // Correo
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Correo:',
                        style: TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        correo,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: cargando
                          ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : null,
                    ),
                    const Divider(),

                    // Puntos
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Puntos:',
                        style: TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        puntos,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Divider(),

                    // Rol (si no viene en /me/basic quedará "—")
                    /*ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Rol:',
                        style: TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        rol,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Divider(),*/
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
