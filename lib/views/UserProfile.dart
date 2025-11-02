// lib/views/UserProfile.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:eduvial/models/user.dart';
import 'package:eduvial/config/constants.dart';
import 'package:eduvial/controllers/auth_controller.dart' as authc;
import 'package:eduvial/utils/page_transitions.dart';
import 'package:eduvial/views/login.dart';

/// =====================
/// MODELO LOCAL (Avatar)
/// =====================
class AvatarItem {
  final int id;
  final String url;
  AvatarItem({required this.id, required this.url});

  factory AvatarItem.fromJson(Map<String, dynamic> j) {
    final rawUrl = (j['url'] ?? j['avatarUrl']) as String;
    final url = rawUrl.startsWith('http')
        ? rawUrl
        : '${ApiConstants.apiBaseUrl}$rawUrl';
    final id = (j['avatar_id'] ?? j['id']) as int;
    return AvatarItem(id: id, url: url);
  }
}

/// Proxy seguro con CORS abierto (weserv.nl)
String _proxify(String url) {
  final withoutScheme = url.replaceFirst(RegExp(r'^https?://'), '');
  return 'https://images.weserv.nl/?url=${Uri.encodeComponent(withoutScheme)}';
}

/// =====================
/// HEADERS AUTENTICADOS
/// =====================
Future<Map<String, String>> _hdr({bool json = false}) async {
  final token = await authc.auth_controller.loadToken();
  return {
    if (json) 'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}

/// =====================
/// LLAMADAS API AVATAR
/// =====================
Future<List<AvatarItem>> _fetchAvatars() async {
  final r = await http.get(
    Uri.parse(ApiConstants.avatarListEndpoint),
    headers: await _hdr(),
  );

  if (r.statusCode >= 200 && r.statusCode < 300) {
    final body = jsonDecode(r.body);
    List items;
    if (body is List) {
      items = body;
    } else if (body is Map && body['data'] is List) {
      items = body['data'];
    } else if (body is Map && body['avatars'] is List) {
      items = body['avatars'];
    } else {
      items = const [];
    }
    return items
        .map((e) => AvatarItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  throw Exception('GET /api/avatar ${r.statusCode}: ${r.body}');
}

Future<String?> _fetchMyAvatarUrl() async {
  final r = await http.get(
    Uri.parse(ApiConstants.myAvatarEndpoint),
    headers: await _hdr(),
  );

  if (r.statusCode == 404) return null;
  if (r.statusCode >= 200 && r.statusCode < 300) {
    final body = jsonDecode(r.body);
    String? raw;
    if (body is Map && body['avatarUrl'] is String) raw = body['avatarUrl'];
    if (raw == null && body is Map && body['url'] is String) raw = body['url'];
    if (raw == null &&
        body is Map &&
        body['data'] is Map &&
        body['data']['url'] is String) {
      raw = body['data']['url'];
    }
    if (raw != null) {
      return raw.startsWith('http')
          ? raw
          : '${ApiConstants.apiBaseUrl}$raw';
    }
  }
  return null;
}

Future<void> _putMyAvatar(int avatarId) async {
  final r = await http.put(
    Uri.parse(ApiConstants.myAvatarEndpoint),
    headers: await _hdr(json: true),
    body: jsonEncode({'avatarId': avatarId}),
  );
  if (r.statusCode < 200 || r.statusCode >= 300) {
    throw Exception('PUT /api/avatar/me ${r.statusCode}: ${r.body}');
  }
}

/// =====================
/// PANTALLA: PROFILE
/// =====================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool cargando = true;
  String? error;
  User? _user;
  bool _loadingAvatars = true;
  String? _myAvatarUrl;
  List<AvatarItem> _options = [];

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
      final raw = await authc.auth_controller.loadCachedUserJson();
      if (raw != null) {
        try {
          final cached = User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          if (mounted) setState(() => _user = cached);
        } catch (_) {}
      }

      final me = await authc.auth_controller.getMeBasic();
      if (me['success'] == true && me['user'] != null) {
        final fresh = User.fromJson(me['user'] as Map<String, dynamic>);
        await authc.auth_controller
            .saveCachedUserJson(jsonEncode(fresh.toJson()));
        if (mounted) setState(() => _user = fresh);
      }

      await _loadAvatarsAndMine();
    } catch (e) {
      if (mounted) setState(() => error = 'Error: $e');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _loadAvatarsAndMine() async {
    setState(() => _loadingAvatars = true);
    try {
      final opts = await _fetchAvatars();
      final mine = await _fetchMyAvatarUrl();
      if (mounted) {
        setState(() {
          _options = opts;
          _myAvatarUrl = mine;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Avatar: $e');
    } finally {
      if (mounted) setState(() => _loadingAvatars = false);
    }
  }

  Future<void> _pickAvatar(AvatarItem it) async {
    final prev = _myAvatarUrl;
    setState(() => _myAvatarUrl = it.url);
    try {
      await _putMyAvatar(it.id);
      final mine = await _fetchMyAvatarUrl();
      if (mounted) setState(() => _myAvatarUrl = mine);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Avatar actualizado ')));
    } catch (e) {
      setState(() => _myAvatarUrl = prev);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo actualizar: $e')));
    }
  }

  Future<void> _confirmAndLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await authc.auth_controller.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
    Navigator.of(context)
        .pushAndRemoveUntil(fadeRoute(const LoginScreen()), (_) => false);
  }

  void _openPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _AvatarPickerGrid(
              items: _options,
              loading: _loadingAvatars,
              onRefresh: _loadAvatarsAndMine,
              onSelect: _pickAvatar,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando && _user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nombre = _user?.name ?? '—';
    final correo = _user?.email ?? '—';
    final puntos = _user?.points?.toString() ?? '—';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _initUser,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
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
                    const Text('Datos personales',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar principal
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: (_myAvatarUrl != null)
                              ? NetworkImage(_proxify(_myAvatarUrl!))
                              : null,
                          child: (_myAvatarUrl == null)
                              ? const Icon(Icons.person,
                              size: 60, color: Color(0xFF1976D2))
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: const Color(0xFF1976D2),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _openPicker,
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.edit,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 🔹 Nuevo: Mensaje si no tiene avatar
                    if (_myAvatarUrl == null)
                      const Text(
                        'Elige tu foto de perfil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1976D2),
                        ),
                      ),

                    const SizedBox(height: 20),
                    if (error != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(error!,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    ListTile(
                      title: const Text('Nombre:',
                          style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      subtitle:
                      Text(nombre, style: const TextStyle(fontSize: 16)),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Correo:',
                          style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      subtitle:
                      Text(correo, style: const TextStyle(fontSize: 16)),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Puntos:',
                          style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      subtitle:
                      Text(puntos, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _confirmAndLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
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

/// =====================
/// GRID DE AVATARES
/// =====================
class _AvatarPickerGrid extends StatelessWidget {
  final List<AvatarItem> items;
  final bool loading;
  final Future<void> Function() onRefresh;
  final void Function(AvatarItem) onSelect;

  const _AvatarPickerGrid({
    required this.items,
    required this.loading,
    required this.onRefresh,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * .75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Elige tu avatar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : (items.isEmpty
                ? const Center(
              child: Text(
                'No hay avatares disponibles.\nDesliza hacia abajo para recargar.',
                textAlign: TextAlign.center,
              ),
            )
                : RefreshIndicator(
              onRefresh: onRefresh,
              child: GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final it = items[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(it);
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Theme.of(context).dividerColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _proxify(it.url),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const Icon(
                                Icons.image_not_supported,
                                size: 36,
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4),
                                child: const Text('Elegir',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )),
          ),
        ],
      ),
    );
  }
}
