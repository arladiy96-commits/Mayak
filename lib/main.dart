import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color background = Color(0xFF08121E);
const Color panel = Color(0xFF102235);
const Color elevatedPanel = Color(0xFF182C42);
const Color beaconBlue = Color(0xFF1689FF);
const Color softText = Color(0xFF9DB1C8);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MayakApp());
}

/// Local-first beta. User-generated plans are stored on this device only.
/// No mock drivers or fabricated availability are presented as live data.
class TripPlan {
  final String id;
  final bool isDriver;
  final String from;
  final String to;
  final DateTime departure;
  final int seats;
  final int? price;
  final String note;

  const TripPlan({
    required this.id,
    required this.isDriver,
    required this.from,
    required this.to,
    required this.departure,
    required this.seats,
    this.price,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'isDriver': isDriver,
        'from': from,
        'to': to,
        'departure': departure.toIso8601String(),
        'seats': seats,
        'price': price,
        'note': note,
      };

  factory TripPlan.fromJson(Map<String, dynamic> json) => TripPlan(
        id: json['id'] as String,
        isDriver: json['isDriver'] as bool,
        from: json['from'] as String,
        to: json['to'] as String,
        departure: DateTime.parse(json['departure'] as String),
        seats: (json['seats'] as num).toInt(),
        price: (json['price'] as num?)?.toInt(),
        note: (json['note'] as String?) ?? '',
      );
}

String dateText(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(value.year, value.month, value.day);
  final diff = target.difference(today).inDays;
  final day = diff == 0
      ? 'Сегодня'
      : diff == 1
          ? 'Завтра'
          : '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}';
  return '$day · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class MayakApp extends StatefulWidget {
  const MayakApp({super.key});

  @override
  State<MayakApp> createState() => _MayakAppState();
}

class _MayakAppState extends State<MayakApp> {
  int tab = 0;
  List<TripPlan> plans = [];
  bool loading = true;
  static const storageKey = 'mayak_plans_v1';

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        plans = list
            .map((item) => TripPlan.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // A malformed device cache must not block the application from opening.
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _savePlans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(plans.map((plan) => plan.toJson()).toList()),
    );
  }

  Future<void> _createPlan() async {
    final plan = await Navigator.of(context).push<TripPlan>(
      MaterialPageRoute(builder: (_) => const PlanEditor()),
    );
    if (plan == null || !mounted) return;
    setState(() {
      plans.insert(0, plan);
      tab = 1;
    });
    await _savePlans();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Маяк сохранён на этом телефоне')),
      );
    }
  }

  Future<void> _deletePlan(TripPlan plan) async {
    setState(() => plans.removeWhere((p) => p.id == plan.id));
    await _savePlans();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Маяк',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: beaconBlue,
          surface: panel,
          secondary: Color(0xFF7EC7FF),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(17),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF233B54)),
            borderRadius: BorderRadius.circular(17),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: beaconBlue),
            borderRadius: BorderRadius.circular(17),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          hintStyle: const TextStyle(color: softText),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: elevatedPanel,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(
                  index: tab,
                  children: [
                    _homePage(),
                    _myPlansPage(),
                    _profilePage(),
                  ],
                ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) => setState(() => tab = value),
          backgroundColor: const Color(0xFF0B1928),
          indicatorColor: const Color(0xFF154F83),
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Главная',
            ),
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route_rounded),
              label: 'Мои маяки',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }

  Widget _homePage() {
    final upcoming = [...plans]
      ..sort((a, b) => a.departure.compareTo(b.departure));
    final next = upcoming
        .where((item) => item.departure.isAfter(
              DateTime.now().subtract(const Duration(hours: 3)),
            ))
        .take(2)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        _masthead(),
        const SizedBox(height: 25),
        _hero(),
        const SizedBox(height: 22),
        PrimaryAction(
          label: 'Оставить маяк',
          subtitle: 'Расскажи, куда собираешься',
          onTap: _createPlan,
          icon: Icons.add_rounded,
        ),
        const SizedBox(height: 28),
        _sectionHeader(
          'Мои ближайшие планы',
          'Все',
          () => setState(() => tab = 1),
        ),
        const SizedBox(height: 12),
        if (next.isEmpty)
          _emptyCard(
            icon: Icons.near_me_outlined,
            title: 'Пока ни одного маяка',
            subtitle: 'Планируешь поездку? Добавь её за несколько секунд.',
          )
        else
          ...next.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PlanCard(plan: item, onTap: () => _showDetails(item)),
            ),
          ),
        const SizedBox(height: 28),
        _sectionHeader('Как это работает', '', null),
        const SizedBox(height: 12),
        const _HintCard(
          number: '01',
          title: 'Обозначь планы',
          subtitle: 'Куда и когда едешь или ищешь место.',
        ),
        const SizedBox(height: 9),
        const _HintCard(
          number: '02',
          title: 'Найди совпадение',
          subtitle: 'После запуска общей базы люди увидят подходящие планы.',
        ),
        const SizedBox(height: 20),
        const _LocalNotice(),
      ],
    );
  }

  Widget _masthead() => Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/brand/mayak_icon.png',
              height: 48,
              width: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.explore_rounded,
                color: beaconBlue,
                size: 40,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('МАЯК',
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5)),
                Text('Люди. Дороги. Возможности.',
                    style: TextStyle(color: softText, fontSize: 11)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(13),
            ),
            child: IconButton(
              tooltip: 'Мои маяки',
              onPressed: () => setState(() => tab = 1),
              icon: const Icon(Icons.bookmark_border_rounded),
            ),
          ),
        ],
      );

  Widget _hero() => Container(
        height: 211,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF173F68),
              Color(0xFF102A47),
              Color(0xFF0A1B2B),
            ],
          ),
          border: Border.all(color: const Color(0xFF315A7D)),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _RoutePainter())),
            const Positioned(
              left: 21,
              top: 22,
              right: 55,
              child: Text(
                'Найди тех,\nкто по пути',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  height: 1.13,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const Positioned(
              left: 22,
              bottom: 23,
              right: 76,
              child: Text(
                'Твои планы — сигнал для попутчиков.\nОдин маршрут может объединить людей.',
                style: TextStyle(fontSize: 12, color: Color(0xFFC0D4E9), height: 1.5),
              ),
            ),
          ],
        ),
      );

  Widget _sectionHeader(
    String title,
    String action,
    VoidCallback? onTap,
  ) =>
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          if (onTap != null)
            TextButton(onPressed: onTap, child: Text(action)),
        ],
      );

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: const Color(0xFF23394F)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF7FC9FF), size: 28),
            const SizedBox(height: 13),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(color: softText, height: 1.45)),
          ],
        ),
      );

  Widget _myPlansPage() {
    final sorted = [...plans]
      ..sort((a, b) => a.departure.compareTo(b.departure));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      children: [
        const Text('Мои маяки',
            style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        const Text(
          'Твои поездки и заявки в одном месте.',
          style: TextStyle(color: softText),
        ),
        const SizedBox(height: 22),
        PrimaryAction(
          label: 'Новый маяк',
          subtitle: 'Еду сам или ищу место',
          icon: Icons.add_rounded,
          onTap: _createPlan,
        ),
        const SizedBox(height: 19),
        if (sorted.isEmpty)
          _emptyCard(
            icon: Icons.route_rounded,
            title: 'Список пока пуст',
            subtitle: 'Создай первый план — он останется на телефоне даже без интернета.',
          )
        else
          ...sorted.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: PlanCard(plan: item, onTap: () => _showDetails(item)),
            ),
          ),
        const SizedBox(height: 20),
        const _LocalNotice(),
      ],
    );
  }

  Widget _profilePage() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        children: [
          const Text('Профиль',
              style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800)),
          const SizedBox(height: 23),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 29,
                  backgroundColor: Color(0xFF154D7A),
                  child: Icon(Icons.person_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 14),
                const Text('Добро пожаловать в Маяк',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                const Text('Локальная бета-версия · 0.1.0',
                    style: TextStyle(color: softText)),
                const Divider(height: 34, color: Color(0xFF2B4053)),
                Text('Моих маяков: ${plans.length}',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _LocalNotice(),
          const SizedBox(height: 22),
          const Text('Скоро появятся',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _HintCard(
            number: '↗',
            title: 'Общая лента поездок',
            subtitle: 'Реальные водители и пассажиры со всех подключённых сёл.',
          ),
          const SizedBox(height: 10),
          const _HintCard(
            number: '↗',
            title: 'Совпадения и уведомления',
            subtitle: 'Маяк будет сообщать, когда планы людей совпадут.',
          ),
        ],
      );

  Future<void> _showDetails(TripPlan plan) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: panel,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(23, 8, 23, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.isDriver ? 'Еду на машине' : 'Ищу место',
                  style: const TextStyle(color: Color(0xFF71C6FF))),
              const SizedBox(height: 14),
              Text('${plan.from} → ${plan.to}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 11),
              Text(dateText(plan.departure),
                  style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 9),
              Text(
                plan.isDriver
                    ? 'Свободных мест: ${plan.seats}'
                    : 'Нужно мест: ${plan.seats}',
                style: const TextStyle(color: softText),
              ),
              if (plan.price != null) ...[
                const SizedBox(height: 8),
                Text('Стоимость места: ${plan.price} ₸',
                    style: const TextStyle(color: softText)),
              ],
              if (plan.note.isNotEmpty) ...[
                const SizedBox(height: 11),
                Text(plan.note),
              ],
              const SizedBox(height: 23),
              const _LocalNotice(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await _deletePlan(plan);
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Удалить маяк'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF9A9A),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryAction extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const PrimaryAction({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: beaconBlue,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
            child: Row(
              children: [
                Icon(icon, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Color(0xFFE1F1FF), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        ),
      );
}

class PlanCard extends StatelessWidget {
  final TripPlan plan;
  final VoidCallback onTap;
  const PlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF24394E)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF173D61),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    plan.isDriver
                        ? Icons.directions_car_filled_rounded
                        : Icons.person_search_rounded,
                    color: const Color(0xFF70C4FF),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateText(plan.departure),
                          style: const TextStyle(
                              color: Color(0xFF81C9FF), fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('${plan.from} → ${plan.to}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 5),
                      Text(
                        '${plan.isDriver ? 'Еду' : 'Ищу машину'} · ${plan.seats} мест.',
                        style: const TextStyle(
                            color: softText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: softText),
              ],
            ),
          ),
        ),
      );
}

class _HintCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  const _HintCard({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Text(number,
                style: const TextStyle(
                    color: Color(0xFF80C7FF),
                    fontSize: 21,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: softText, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LocalNotice extends StatelessWidget {
  const _LocalNotice();

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF7095B5), size: 17),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Тестовая версия: маяки сохраняются только на этом устройстве. '
              'Общий сервер и поиск людей ещё не подключены.',
              style: TextStyle(color: softText, fontSize: 11, height: 1.5),
            ),
          ),
        ],
      );
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final route = Path()
      ..moveTo(size.width * .52, size.height * .86)
      ..cubicTo(
        size.width * .66,
        size.height * .78,
        size.width * .54,
        size.height * .49,
        size.width * .76,
        size.height * .51,
      )
      ..cubicTo(
        size.width * .99,
        size.height * .51,
        size.width * .77,
        size.height * .14,
        size.width * 1.06,
        size.height * .14,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = beaconBlue.withValues(alpha: .13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF62C3FF).withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    for (final point in [
      Offset(size.width * .52, size.height * .86),
      Offset(size.width * .76, size.height * .51),
    ]) {
      canvas.drawCircle(point, 9, Paint()..color = beaconBlue.withValues(alpha: .2));
      canvas.drawCircle(point, 4, Paint()..color = const Color(0xFFE9F8FF));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlanEditor extends StatefulWidget {
  const PlanEditor({super.key});

  @override
  State<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<PlanEditor> {
  bool isDriver = true;
  final from = TextEditingController();
  final to = TextEditingController();
  final price = TextEditingController();
  final note = TextEditingController();
  DateTime departure = DateTime.now().add(const Duration(days: 1));
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);
  int seats = 1;

  @override
  void dispose() {
    from.dispose();
    to.dispose();
    price.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: departure,
      locale: const Locale('ru'),
    );
    if (date == null || !mounted) return;
    setState(() => departure = date);
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: time);
    if (value == null || !mounted) return;
    setState(() => time = value);
  }

  void _publish() {
    final origin = from.text.trim();
    final target = to.text.trim();
    if (origin.isEmpty || target.isEmpty || origin.toLowerCase() == target.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажи разные пункты отправления и назначения')),
      );
      return;
    }
    final timestamp = DateTime(
      departure.year,
      departure.month,
      departure.day,
      time.hour,
      time.minute,
    );
    if (timestamp.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выбери время в будущем')),
      );
      return;
    }
    final parsedPrice = int.tryParse(price.text.trim());
    Navigator.of(context).pop(
      TripPlan(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        isDriver: isDriver,
        from: origin,
        to: target,
        departure: timestamp,
        seats: seats,
        price: isDriver && parsedPrice != null && parsedPrice > 0
            ? parsedPrice
            : null,
        note: note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: background,
          title: const Text('Новый маяк'),
          centerTitle: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 38),
            children: [
              const Text('Какой у тебя план?',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Всего несколько деталей — и план готов.',
                  style: TextStyle(color: softText)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _modeButton(
                      'Еду сам',
                      Icons.directions_car_rounded,
                      isDriver,
                      () => setState(() => isDriver = true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _modeButton(
                      'Ищу место',
                      Icons.people_outline_rounded,
                      !isDriver,
                      () => setState(() => isDriver = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 21),
              _field('Откуда', from, 'Например, Бесколь', Icons.trip_origin_rounded),
              const SizedBox(height: 14),
              _field('Куда', to, 'Например, Петропавловск', Icons.location_on_outlined),
              const SizedBox(height: 16),
              const Text('Дата и время',
                  style: TextStyle(color: softText, fontSize: 12)),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _pickerButton(
                      Icons.calendar_month_outlined,
                      '${departure.day.toString().padLeft(2, '0')}.${departure.month.toString().padLeft(2, '0')}.${departure.year}',
                      _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _pickerButton(
                      Icons.schedule_rounded,
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isDriver ? 'Свободные места' : 'Сколько нужно мест',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: seats > 1 ? () => setState(() => seats--) : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    child: Text('$seats',
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w700)),
                  ),
                  IconButton.filledTonal(
                    onPressed: seats < 8 ? () => setState(() => seats++) : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              if (isDriver) ...[
                const SizedBox(height: 17),
                _field('Цена за место (необязательно)', price, '₸',
                    Icons.payments_outlined,
                    keyboard: TextInputType.number),
              ],
              const SizedBox(height: 17),
              _field(
                'Комментарий (необязательно)',
                note,
                'Например, могу заехать по пути',
                Icons.edit_note_rounded,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _publish,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: beaconBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: const Text('Сохранить маяк',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 13),
              const Center(
                child: Text(
                  'Пока только на твоём устройстве',
                  style: TextStyle(color: softText, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _field(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: softText, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF73BFFF)),
              hintText: hint,
            ),
          ),
        ],
      );

  Widget _modeButton(
    String text,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) =>
      Material(
        color: selected ? const Color(0xFF1266B8) : panel,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? Colors.white : softText),
                const SizedBox(height: 7),
                Text(text,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : softText)),
              ],
            ),
          ),
        ),
      );

  Widget _pickerButton(IconData icon, String text, VoidCallback onTap) =>
      Material(
        color: panel,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: const Color(0xFF78C5FF)),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(text,
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );
}
