import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme.dart';

void main() => runApp(const CasaOscarApp());

class CasaOscarApp extends StatelessWidget {
  const CasaOscarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Casa Oscar',
      theme: buildAppTheme(),
      home: const Shell(),
    );
  }
}

class Api {
  // Teléfono real: reemplaza por la IP LAN del servidor FastAPI.
  static const baseUrl = 'http://127.0.0.1:8000';

  static Future<dynamic> getJson(String path) async {
    final r = await http.get(Uri.parse('$baseUrl$path'));
    if (r.statusCode != 200) throw Exception(r.body);
    return jsonDecode(r.body);
  }

  static Future<void> post(String path, [Map<String, dynamic>? body]) async {
    final r = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: body == null ? null : jsonEncode(body),
    );
    if (r.statusCode != 200) throw Exception(r.body);
  }
}

// ---------------------------------------------------------------------------
// Shell: fondo con resplandor superior + navegación inferior flotante.
// ---------------------------------------------------------------------------

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;
  bool navOpen = true;
  final pages = const [HomeScreen(), RoomsScreen(), ScenesScreen(), EnergyScreen()];
  final _navItems = const [
    (icon: Icons.home_rounded, label: 'Inicio'),
    (icon: Icons.grid_view_rounded, label: 'Cuartos'),
    (icon: Icons.auto_awesome_rounded, label: 'Escenas'),
    (icon: Icons.bolt_rounded, label: 'Energía'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Resplandor ambiental fijo detrás del contenido.
          Positioned(
            top: -140,
            left: -80,
            child: IgnorePointer(child: Blob(size: 340, color: AppColors.primary, opacity: 0.22)),
          ),
          Positioned(
            top: -60,
            right: -120,
            child: IgnorePointer(child: Blob(size: 280, color: AppColors.violet, opacity: 0.16)),
          ),
          SafeArea(
            bottom: false,
            child: MobileFrame(
              child: IndexedStack(index: index, children: pages),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: MobileFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tirador: toca para ocultar/mostrar la barra cuando estorbe.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => navOpen = !navOpen),
                      child: Container(
                        width: 64,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderStrong),
                          boxShadow: const [
                            BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Icon(
                          navOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  child: navOpen ? _NavBar(items: _navItems, index: index, onSelect: (i) => setState(() => index = i)) : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final List<({IconData icon, String label})> items;
  final int index;
  final ValueChanged<int> onSelect;
  const _NavBar({required this.items, required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withValues(alpha: 0.16) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 22, color: selected ? AppColors.primaryLight : AppColors.textFaint),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(item.label,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryLight)),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> rooms;
  late Future<List<dynamic>> scenes;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    rooms = Api.getJson('/api/rooms').then((v) => List<dynamic>.from(v));
    scenes = Api.getJson('/api/scenes').then((v) => List<dynamic>.from(v));
  }

  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () async {
        setState(refresh);
        await Future.wait([rooms, scenes]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Casa Oscar',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    SizedBox(height: 2),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, size: 20, color: Colors.white),
              ),
            ],
          ),
          Text(greeting, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14.5)),
          const SizedBox(height: 22),
          const _StatusHero(),
          const SizedBox(height: 28),
          sectionTitle('Escenas rápidas'),
          FutureBuilder<List<dynamic>>(
            future: scenes,
            builder: (context, s) {
              if (!s.hasData) return const _LoadingStrip();
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: s.data!.map((e) => SceneCard(scene: e)).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          sectionTitle('Habitaciones'),
          FutureBuilder<List<dynamic>>(
            future: rooms,
            builder: (context, s) {
              if (!s.hasData) return const _LoadingStrip();
              return Column(
                children: s.data!.map((room) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RoomCard(room: room),
                    )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LoadingStrip extends StatelessWidget {
  const _LoadingStrip();
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: const LinearProgressIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        minHeight: 3,
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero();
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            Positioned(top: -40, right: -30, child: Blob(size: 160, color: Colors.white, opacity: 0.14)),
            Positioned(bottom: -50, left: -20, child: Blob(size: 140, color: Colors.black, opacity: 0.18)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.home_rounded, size: 26, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Casa conectada',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                        SizedBox(height: 3),
                        Text('Servidor local activo',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        const Text('ONLINE',
                            style: TextStyle(
                                color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData sceneIcon(String id) => switch (id) {
      'llegar' => Icons.home_rounded,
      'salir' => Icons.directions_car_filled_rounded,
      'cine' => Icons.movie_rounded,
      'buenas_noches' => Icons.bedtime_rounded,
      _ => Icons.auto_awesome_rounded,
    };

class SceneCard extends StatefulWidget {
  final dynamic scene;
  const SceneCard({super.key, required this.scene});
  @override
  State<SceneCard> createState() => _SceneCardState();
}

class _SceneCardState extends State<SceneCard> {
  bool _pressed = false;
  bool _justRan = false;

  Future<void> _run() async {
    await Api.post('/api/scenes/${widget.scene['id']}');
    if (!mounted) return;
    setState(() => _justRan = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        content: Text('${widget.scene['name']} activada'),
      ),
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _justRan = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forScene(widget.scene['id']);
    final icon = sceneIcon(widget.scene['id']);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _run,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: _justRan ? color : AppColors.border, width: _justRan ? 1.6 : 1),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Stack(
              children: [
                // Ilustración decorativa de fondo, propia de cada escena.
                Positioned(
                  right: -18,
                  bottom: -18,
                  child: Transform.rotate(
                    angle: -0.35,
                    child: Icon(icon, size: 92, color: color.withValues(alpha: 0.12)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconBadge(icon: icon, color: color, size: 38),
                      const SizedBox(height: 10),
                      Text(widget.scene['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                      const SizedBox(height: 3),
                      Text(
                        widget.scene['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.25),
                      ),
                    ],
                  ),
                ),
                if (_justRan)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Icon(Icons.check_circle_rounded, color: color, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final dynamic room;
  const RoomCard({super.key, required this.room});
  IconData get icon => switch (room['icon']) {
        'living' => Icons.weekend_rounded,
        'kitchen' => Icons.kitchen_rounded,
        'deck' => Icons.deck_rounded,
        'bed' => Icons.bed_rounded,
        _ => Icons.meeting_room_rounded,
      };
  @override
  Widget build(BuildContext context) {
    final color = AppColors.forRoomIcon(room['icon']);
    final total = (room['device_count'] ?? 0) as int;
    final active = (room['active_count'] ?? 0) as int;
    final ratio = total == 0 ? 0.0 : active / total;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => RoomDetail(roomName: room['name']))),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 3),
                Text('$active activos · $total dispositivos',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ratio == 0 ? 1 : ratio,
                  strokeWidth: 3,
                  color: ratio == 0 ? AppColors.border : color,
                  backgroundColor: AppColors.border,
                ),
                Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textFaint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rooms
// ---------------------------------------------------------------------------

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: Api.getJson('/api/rooms'),
      builder: (context, s) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
        children: [
          const Text('Habitaciones', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Control por zona de la casa', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.5)),
          const SizedBox(height: 22),
          if (!s.hasData)
            const _LoadingStrip()
          else
            ...List<dynamic>.from(s.data).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RoomCard(room: r),
                ))
        ],
      ),
    );
  }
}

class RoomDetail extends StatefulWidget {
  final String roomName;
  const RoomDetail({super.key, required this.roomName});
  @override
  State<RoomDetail> createState() => _RoomDetailState();
}

class _RoomDetailState extends State<RoomDetail> {
  late Future<List<dynamic>> devices;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    devices = Api.getJson('/api/devices?room=${Uri.encodeComponent(widget.roomName)}')
        .then((v) => List<dynamic>.from(v));
  }

  Future<void> act(dynamic d, String service, {Map<String, dynamic>? data}) async {
    await Api.post('/api/service', {'entity_id': d['entity_id'], 'domain': d['type'], 'service': service, 'data': data});
    setState(refresh);
  }

  IconData iconFor(String t) => switch (t) {
        'light' => Icons.lightbulb_rounded,
        'climate' => Icons.ac_unit_rounded,
        'cover' => Icons.blinds_rounded,
        'camera' => Icons.videocam_rounded,
        'media_player' => Icons.tv_rounded,
        'switch' => Icons.power_rounded,
        _ => Icons.device_unknown_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: MobileFrame(
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bg,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            title: Text(widget.roomName, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
            sliver: FutureBuilder<List<dynamic>>(
              future: devices,
              builder: (context, s) {
                if (!s.hasData) {
                  return const SliverToBoxAdapter(
                      child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ));
                }
                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.92,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final d = s.data![i];
                      return DeviceCard(device: d, icon: iconFor(d['type']), onAction: (svc, {data}) => act(d, svc, data: data));
                    },
                    childCount: s.data!.length,
                  ),
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final dynamic device;
  final IconData icon;
  final void Function(String service, {Map<String, dynamic>? data}) onAction;
  const DeviceCard({super.key, required this.device, required this.icon, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final type = device['type'];
    final color = AppColors.forDeviceType(type);
    final active = ['on', 'cool', 'streaming', 'open'].contains(device['state']);
    final togglable = ['light', 'switch', 'media_player'].contains(type);

    return AppCard(
      padding: const EdgeInsets.all(14),
      color: active ? AppColors.surfaceElevated : AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: color, size: 38),
              const Spacer(),
              if (togglable)
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: active,
                    onChanged: (_) => onAction(active ? 'turn_off' : 'turn_on'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(device['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            device['state'].toString().toUpperCase(),
            style: TextStyle(color: active ? color : AppColors.textFaint, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.4),
          ),
          const Spacer(),
          if (type == 'light' && active) ...[
            _BrightnessSlider(
              color: color,
              value: ((device['brightness'] ?? 50) as num).toDouble().clamp(0, 100),
              onChangedEnd: (v) => onAction('turn_on', data: {'brightness': v.round()}),
            ),
          ],
          if (type == 'climate') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepperButton(
                  icon: Icons.remove_rounded,
                  color: color,
                  onTap: () => onAction('set_temperature', data: {'temperature': (device['temperature'] ?? 24) - 1}),
                ),
                Text('${device['temperature'] ?? 24}°', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                _StepperButton(
                  icon: Icons.add_rounded,
                  color: color,
                  onTap: () => onAction('set_temperature', data: {'temperature': (device['temperature'] ?? 24) + 1}),
                ),
              ],
            ),
          ],
          if (type == 'cover') ...[
            Row(
              children: [
                Expanded(
                  child: _MiniButton(label: 'Cerrar', filled: false, color: color, onTap: () => onAction('close_cover')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniButton(label: 'Abrir', filled: true, color: color, onTap: () => onAction('open_cover')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BrightnessSlider extends StatefulWidget {
  final Color color;
  final double value;
  final ValueChanged<double> onChangedEnd;
  const _BrightnessSlider({required this.color, required this.value, required this.onChangedEnd});
  @override
  State<_BrightnessSlider> createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends State<_BrightnessSlider> {
  late double _local = widget.value;

  @override
  void didUpdateWidget(covariant _BrightnessSlider old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _local = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.wb_sunny_rounded, size: 14, color: widget.color),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: widget.color, thumbColor: widget.color),
            child: Slider(
              value: _local,
              min: 0,
              max: 100,
              onChanged: (v) => setState(() => _local = v),
              onChangeEnd: widget.onChangedEnd,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final bool filled;
  final Color color;
  final VoidCallback onTap;
  const _MiniButton({required this.label, required this.filled, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.85) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: filled ? 0 : 0.4)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: filled ? Colors.black : color)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scenes
// ---------------------------------------------------------------------------

class ScenesScreen extends StatelessWidget {
  const ScenesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: Api.getJson('/api/scenes'),
      builder: (context, s) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
        children: [
          const Text('Escenas', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Rutinas de un toque', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.5)),
          const SizedBox(height: 22),
          if (!s.hasData)
            const _LoadingStrip()
          else
            ...List<dynamic>.from(s.data).map((e) {
              final color = AppColors.forScene(e['id']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () async {
                    await Api.post('/api/scenes/${e['id']}');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.surfaceElevated,
                        content: Text('${e['name']} ejecutada'),
                      ));
                    }
                  },
                  child: Row(
                    children: [
                      IconBadge(icon: sceneIcon(e['id']), color: color),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                            const SizedBox(height: 3),
                            Text(e['description'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.85), shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                      ),
                    ],
                  ),
                ),
              );
            })
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Energy
// ---------------------------------------------------------------------------

class EnergyScreen extends StatelessWidget {
  const EnergyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: Api.getJson('/api/energy'),
      builder: (context, s) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
        children: [
          const Text('Energía', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Monitoreo de consumo residencial', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.5)),
          const SizedBox(height: 22),
          if (!s.hasData)
            const _LoadingStrip()
          else ...[
            _EnergyHero(data: s.data),
            const SizedBox(height: 20),
            sectionTitle('Detalle'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _MetricCard(label: 'Hoy', value: '${s.data['today_kwh']} kWh', icon: Icons.today_rounded, color: AppColors.cyan),
                _MetricCard(label: 'Este mes', value: '${s.data['month_kwh']} kWh', icon: Icons.calendar_month_rounded, color: AppColors.violet),
                _MetricCard(label: 'Costo estimado', value: '\$${s.data['month_cost_mxn']} MXN', icon: Icons.payments_rounded, color: AppColors.green),
                _MetricCard(label: 'Red eléctrica', value: '${s.data['grid_kw']} kW', icon: Icons.electrical_services_rounded, color: AppColors.amber),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

class _EnergyHero extends StatelessWidget {
  final dynamic data;
  const _EnergyHero({required this.data});
  @override
  Widget build(BuildContext context) {
    final instant = (data['instant_kw'] as num).toDouble();
    final capacity = 6.0;
    final ratio = (instant / capacity).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        padding: const EdgeInsets.all(22),
        child: Stack(
          children: [
            Positioned(bottom: -60, right: -40, child: Blob(size: 180, color: Colors.white, opacity: 0.12)),
            Row(
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 7,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        strokeCap: StrokeCap.round,
                      ),
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Consumo actual', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('${data['instant_kw']} kW',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, size: 38),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        ],
      ),
    );
  }
}
