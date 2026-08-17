// ملتزم v3 — شعار التطبيق + بدء تشغيل + ورد + مصحف + صلاة + أذكار + نقاط
// ملتزم v2 — تطوير الورد والمصحف والصلاة والأذكار والاستمرارية
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MoltazemApp());

class AppLogo extends StatelessWidget {
  final double size;
  final bool rounded;

  const AppLogo({super.key, this.size = 110, this.rounded = true});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/logo.jpg',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
    return rounded
        ? ClipRRect(
            borderRadius: BorderRadius.circular(size * .18),
            child: image,
          )
        : image;
  }
}


class MoltazemApp extends StatelessWidget {
  const MoltazemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ملتزم',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF7FAF7),
      ),
      home: const StartupScreen(),
    );
  }
}


/* ========================= OFFLINE QURAN ========================= */

class QuranVerse {
  final int ayah;
  final String text;
  const QuranVerse({required this.ayah, required this.text});

  factory QuranVerse.fromJson(Map<String, dynamic> json) => QuranVerse(
        ayah: json['ayah'] as int,
        text: json['text'] as String,
      );
}

class QuranSurah {
  final int id;
  final String name;
  final int ayahCount;
  final List<QuranVerse> verses;
  const QuranSurah({required this.id, required this.name, required this.ayahCount, required this.verses});

  factory QuranSurah.fromJson(Map<String, dynamic> json) => QuranSurah(
        id: json['id'] as int,
        name: json['name'] as String,
        ayahCount: json['ayahCount'] as int,
        verses: (json['verses'] as List).map((e) => QuranVerse.fromJson(e)).toList(),
      );
}

class QuranRepository {
  static List<QuranSurah>? _cache;

  static Future<List<QuranSurah>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/quran/quran.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (data['surahs'] as List)
        .map((e) => QuranSurah.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  static Future<List<QuranSurah>> search(String query) async {
    final surahs = await load();
    final q = _normalizeArabic(query.trim());
    if (q.isEmpty) return [];
    final result = <QuranSurah>[];
    for (final surah in surahs) {
      final matching = surah.verses.where((v) => _normalizeArabic(v.text).contains(q)).toList();
      if (matching.isNotEmpty) {
        result.add(QuranSurah(
          id: surah.id,
          name: surah.name,
          ayahCount: matching.length,
          verses: matching,
        ));
      }
    }
    return result;
  }

  static String _normalizeArabic(String s) => s
      .replaceAll(RegExp(r'[ًٌٍَُِّْـٰٱ]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .trim();
}

const List<Map<String, int>> juzStarts = [
  {'surah': 1, 'ayah': 1}, {'surah': 2, 'ayah': 142}, {'surah': 2, 'ayah': 253},
  {'surah': 3, 'ayah': 93}, {'surah': 4, 'ayah': 24}, {'surah': 4, 'ayah': 148},
  {'surah': 5, 'ayah': 82}, {'surah': 6, 'ayah': 111}, {'surah': 7, 'ayah': 88},
  {'surah': 8, 'ayah': 41}, {'surah': 9, 'ayah': 93}, {'surah': 11, 'ayah': 6},
  {'surah': 12, 'ayah': 53}, {'surah': 15, 'ayah': 1}, {'surah': 17, 'ayah': 1},
  {'surah': 18, 'ayah': 75}, {'surah': 21, 'ayah': 1}, {'surah': 23, 'ayah': 1},
  {'surah': 25, 'ayah': 21}, {'surah': 27, 'ayah': 56}, {'surah': 29, 'ayah': 46},
  {'surah': 33, 'ayah': 31}, {'surah': 36, 'ayah': 28}, {'surah': 39, 'ayah': 32},
  {'surah': 41, 'ayah': 47}, {'surah': 46, 'ayah': 1}, {'surah': 51, 'ayah': 31},
  {'surah': 58, 'ayah': 1}, {'surah': 67, 'ayah': 1}, {'surah': 78, 'ayah': 1},
];

/* ========================= DATA ========================= */

class RankSystem {
  static String getRank(int points) {
    if (points >= 1000) return '💎 أسطورة الالتزام';
    if (points >= 700) return '🏆 نجم الالتزام';
    if (points >= 500) return '👑 قدوة';
    if (points >= 300) return '🥇 ملتزم مثالي';
    if (points >= 150) return '🏅 ملتزم متقدم';
    if (points >= 50) return '💪 ملتزم مميز';
    if (points >= 10) return '⭐ ملتزم';
    return '🌱 بداية الالتزام';
  }

  static int nextTarget(int points) {
    for (final n in [10, 50, 150, 300, 500, 700, 1000]) {
      if (points < n) return n;
    }
    return 1000;
  }
}

class BadgeSystem {
  static List<String> earned(int points, int streak) {
    final b = <String>[];
    if (points >= 10) b.add('⭐ أول خطوة');
    if (points >= 50) b.add('💪 ملتزم مميز');
    if (points >= 150) b.add('🏅 ملتزم متقدم');
    if (points >= 300) b.add('🥇 ملتزم مثالي');
    if (points >= 500) b.add('👑 قدوة');
    if (points >= 700) b.add('🏆 نجم الالتزام');
    if (points >= 1000) b.add('💎 أسطورة');
    if (streak >= 3) b.add('🔥 3 أيام');
    if (streak >= 7) b.add('🔥 أسبوع كامل');
    if (streak >= 30) b.add('🔥 30 يوم');
    return b;
  }
}


class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final p = await SharedPreferences.getInstance();
    final loggedIn = p.getBool('loggedIn') ?? false;
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => loggedIn ? const MainScreen() : const AuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 145),
              SizedBox(height: 18),
              Text(
                'ملتزم',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text('الالتزام .. يصنعك'),
              SizedBox(height: 24),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ========================= AUTH ========================= */

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final nameController = TextEditingController();
  String gender = 'ذكر';

  Future<void> _saveUser() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب اسمك أولًا')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', nameController.text.trim());
    await prefs.setString('gender', gender);
    await prefs.setInt('points', 0);
    await prefs.setBool('isVip', false);
    await prefs.setBool('loggedIn', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const AppLogo(size: 150),
                  const SizedBox(height: 18),
                  const Text(
                    'أهلاً بك في ملتزم',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('خطوة صغيرة كل يوم تصنع فرقًا كبيرًا'),
                  const SizedBox(height: 30),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: gender,
                    items: ['ذكر', 'أنثى']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => gender = v ?? 'ذكر'),
                    decoration: const InputDecoration(
                      labelText: 'الجنس',
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saveUser,
                      child: const Padding(
                        padding: EdgeInsets.all(13),
                        child: Text('ابدأ مجاني', style: TextStyle(fontSize: 17)),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VipRegisterScreen(),
                      ),
                    ),
                    child: const Text('تسجيل VIP 👑'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================= VIP ========================= */

class VipRegisterScreen extends StatefulWidget {
  const VipRegisterScreen({super.key});
  @override
  State<VipRegisterScreen> createState() => _VipRegisterScreenState();
}

class _VipRegisterScreenState extends State<VipRegisterScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  String gender = 'ذكر';

  Future<void> _registerVip() async {
    if (nameController.text.trim().split(RegExp(r'\s+')).length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك ادخل الاسم الثلاثي')),
      );
      return;
    }
    if (phoneController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك ادخل رقم هاتف صحيح')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', nameController.text.trim());
    await prefs.setString('phone', phoneController.text.trim());
    await prefs.setString('gender', gender);
    await prefs.setInt('points', 50);
    await prefs.setBool('isVip', true);
    await prefs.setBool('loggedIn', true);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تسجيل VIP 👑')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'انضم لنخبة الملتزمين',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الثلاثي',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: gender,
              items: ['ذكر', 'أنثى']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => gender = v ?? 'ذكر'),
              decoration: const InputDecoration(
                labelText: 'الجنس',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
              ),
              onPressed: _registerVip,
              child: const Text('متابعة تسجيل VIP'),
            ),
            const SizedBox(height: 18),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'مميزات VIP:\n'
                  '• ثيم ذهبي\n'
                  '• تحفيزات يومية\n'
                  '• دخول دوري الجوائز\n'
                  '• مزايا حصرية مستقبلًا\n\n'
                  'الدفع الحقيقي سيُربط لاحقًا عبر بوابة دفع آمنة.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ========================= MAIN ========================= */

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;
  bool isVip = false;
  int points = 0;
  String name = '';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      isVip = p.getBool('isVip') ?? false;
      points = p.getInt('points') ?? 0;
      name = p.getString('name') ?? '';
    });
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  void refresh() => load();

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(name: name, points: points, isVip: isVip, onChanged: refresh),
      TodayScreen(onChanged: refresh),
      LeagueScreen(isVip: isVip),
      SettingsScreen(
        isVip: isVip,
        points: points,
        name: name,
        onChanged: refresh,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: screens[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today),
              label: 'اليوم',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events),
              label: 'الدوري',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}

/* ========================= HOME ========================= */

class HomeScreen extends StatelessWidget {
  final String name;
  final int points;
  final bool isVip;
  final VoidCallback onChanged;

  const HomeScreen({
    super.key,
    required this.name,
    required this.points,
    required this.isVip,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final target = RankSystem.nextTarget(points);
    final progress = target == 0 ? 1.0 : (points / target).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text('مرحبًا ${name.isEmpty ? 'يا ملتزم' : name} 🌱'),
        actions: [
          if (isVip)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('👑 VIP', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => onChanged(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: const AppLogo(size: 82),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RankSystem.getRank(points),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text('$points نقطة'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 6),
                    Text('هدف الرتبة القادمة: $target نقطة'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _HomeTile(
              icon: '📖',
              title: 'الورد',
              subtitle: 'حدد وردك اليومي وادخل للمصحف',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WirdScreen()),
              ),
            ),
            _HomeTile(
              icon: '📚',
              title: 'المصحف',
              subtitle: 'مصحف كامل Offline + فهرس + بحث + حفظ آخر موضع',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MushafScreen()),
              ),
            ),
            _HomeTile(
              icon: '🕌',
              title: 'الصلاة',
              subtitle: 'الفجر والظهر والعصر والمغرب والعشاء',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrayerScreen()),
              ),
            ),
            _HomeTile(
              icon: '🤲',
              title: 'الأذكار',
              subtitle: 'أذكار الصباح وأذكار المساء',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AzkarScreen()),
              ),
            ),
            FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (_, snap) {
                final streak = snap.data?.getInt('streak') ?? 0;
                return Card(
                  child: ListTile(
                    leading: const Text('🔥', style: TextStyle(fontSize: 30)),
                    title: const Text(
                      'الاستمرارية',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('مستمر منذ $streak يوم'),
                  ),
                );
              },
            ),
            _HomeTile(
              icon: '🏅',
              title: 'الأوسمة',
              subtitle: 'شوف أوسمة التزامك',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BadgesScreen()),
              ),
            ),
            _HomeTile(
              icon: '🔥',
              title: 'الاستمرارية',
              subtitle: 'حافظ على إنجازاتك اليومية',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Text(icon, style: const TextStyle(fontSize: 32)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_back_ios_new, size: 17),
        onTap: onTap,
      ),
    );
  }
}

/* ========================= WIRD ========================= */


class WirdScreen extends StatefulWidget {
  const WirdScreen({super.key});
  @override
  State<WirdScreen> createState() => _WirdScreenState();
}

class _WirdScreenState extends State<WirdScreen> {
  int pages = 2;
  int todayRead = 0;
  String mode = 'pages';
  int selectedSurah = 1;
  int selectedJuz = 1;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDay = p.getString('wird_day');
    if (savedDay != today) {
      await p.setString('wird_day', today);
      await p.setInt('wird_today', 0);
      await p.setBool('wird_completed_today', false);
    }
    if (!mounted) return;
    setState(() {
      pages = p.getInt('wird_pages') ?? 2;
      todayRead = p.getInt('wird_today') ?? 0;
      mode = p.getString('wird_mode') ?? 'pages';
      selectedSurah = p.getInt('wird_surah') ?? 1;
      selectedJuz = p.getInt('wird_juz') ?? 1;
    });
  }

  Future<void> saveTarget() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('wird_mode', mode);
    await p.setInt('wird_pages', pages);
    await p.setInt('wird_surah', selectedSurah);
    await p.setInt('wird_juz', selectedJuz);
    if (mounted) setState(() {});
  }

  Future<void> addPage() async {
    if (todayRead >= pages) return;
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    final last = p.getString('streak_last_day');
    final completed = p.getBool('wird_completed_today') ?? false;
    todayRead++;
    await p.setInt('wird_today', todayRead);
    await p.setInt('points', (p.getInt('points') ?? 0) + 2);
    if (todayRead == pages && !completed) {
      await p.setBool('wird_completed_today', true);
      final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      final y = yesterday.toIso8601String().substring(0, 10);
      final oldStreak = p.getInt('streak') ?? 0;
      final next = last == y ? oldStreak + 1 : 1;
      await p.setInt('streak', next);
      await p.setString('streak_last_day', today);
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() { super.initState(); load(); }

  @override
  Widget build(BuildContext context) {
    final progress = pages == 0 ? 0.0 : (todayRead / pages).clamp(0.0, 1.0).toDouble();
    return Scaffold(
      appBar: AppBar(title: const Text('📖 الورد اليومي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text('أنت تحدد وردك بنفسك', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('قرأت $todayRead من $pages صفحة اليوم'),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: mode,
                    items: const [
                      DropdownMenuItem(value: 'pages', child: Text('ورد بعدد الصفحات')),
                      DropdownMenuItem(value: 'surah', child: Text('ورد بسورة')),
                      DropdownMenuItem(value: 'juz', child: Text('ورد بجزء')),
                    ],
                    onChanged: (v) async { if (v != null) { mode = v; await saveTarget(); } },
                    decoration: const InputDecoration(labelText: 'نوع الورد', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  if (mode == 'pages')
                    DropdownButtonFormField<int>(
                      value: pages.clamp(1, 20).toInt(),
                      items: List.generate(20, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} صفحات يوميًا'))),
                      onChanged: (v) { if (v != null) { pages = v; saveTarget(); } },
                      decoration: const InputDecoration(labelText: 'عدد الصفحات', border: OutlineInputBorder()),
                    ),
                  if (mode == 'surah')
                    FutureBuilder<List<QuranSurah>>(
                      future: QuranRepository.load(),
                      builder: (_, snap) => snap.hasData ? DropdownButtonFormField<int>(
                        value: selectedSurah,
                        isExpanded: true,
                        items: snap.data!.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.id}. ${s.name}'))).toList(),
                        onChanged: (v) { if (v != null) { selectedSurah = v; saveTarget(); } },
                        decoration: const InputDecoration(labelText: 'اختر السورة', border: OutlineInputBorder()),
                      ) : const LinearProgressIndicator(),
                    ),
                  if (mode == 'juz')
                    DropdownButtonFormField<int>(
                      value: selectedJuz,
                      items: List.generate(30, (i) => DropdownMenuItem(value: i + 1, child: Text('الجزء ${i + 1}'))),
                      onChanged: (v) { if (v != null) { selectedJuz = v; saveTarget(); } },
                      decoration: const InputDecoration(labelText: 'اختر الجزء', border: OutlineInputBorder()),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.menu_book),
            label: const Text('فتح الورد في المصحف'),
            onPressed: () async {
              if (mode == 'surah') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => MushafScreen(surahId: selectedSurah)));
              } else if (mode == 'juz') {
                final start = juzStarts[selectedJuz - 1];
                Navigator.push(context, MaterialPageRoute(builder: (_) => MushafScreen(surahId: start['surah'], initialAyah: start['ayah']!)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MushafScreen()));
              }
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('سجل صفحة مقروءة +2 نقطة'),
            onPressed: todayRead < pages ? addPage : null,
          ),
          const SizedBox(height: 8),
          const Text('الورد والقرآن يعملان Offline بالكامل داخل التطبيق.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class MushafScreen extends StatefulWidget {
  final int? surahId;
  final int initialAyah;
  const MushafScreen({super.key, this.surahId, this.initialAyah = 1});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  Future<List<QuranSurah>>? future;
  int selectedSurah = 1;
  int selectedAyah = 1;

  @override
  void initState() {
    super.initState();
    selectedSurah = widget.surahId ?? 1;
    selectedAyah = widget.initialAyah;
    future = QuranRepository.load();
    _restorePosition();
  }

  Future<void> _restorePosition() async {
    if (widget.surahId != null) return;
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      selectedSurah = p.getInt('last_quran_surah') ?? 1;
      selectedAyah = p.getInt('last_quran_ayah') ?? 1;
    });
  }

  Future<void> _savePosition(int surah, int ayah) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('last_quran_surah', surah);
    await p.setInt('last_quran_ayah', ayah);
  }

  Future<void> _openSearch() async {
    final q = await showSearch<String?>(context: context, delegate: QuranSearchDelegate());
    if (q == null || !mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 المصحف الشريف'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _openSearch),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SurahIndexScreen())),
          ),
        ],
      ),
      body: FutureBuilder<List<QuranSurah>>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final surahs = snap.data!;
          final surah = surahs.firstWhere((s) => s.id == selectedSurah);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedSurah,
                        isExpanded: true,
                        items: surahs.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.id}. ${s.name}'))).toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() { selectedSurah = v; selectedAyah = 1; });
                          _savePosition(v, 1);
                        },
                        decoration: const InputDecoration(labelText: 'السورة', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'الفهرس',
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SurahIndexScreen())),
                      icon: const Icon(Icons.menu_book),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                  itemCount: surah.verses.length,
                  itemBuilder: (_, i) {
                    final v = surah.verses[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          setState(() => selectedAyah = v.ayah);
                          await _savePosition(surah.id, v.ayah);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            '${v.text} ﴿${v.ayah}﴾',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 23, height: 2.1),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SurahIndexScreen extends StatelessWidget {
  const SurahIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فهرس السور')),
      body: FutureBuilder<List<QuranSurah>>(
        future: QuranRepository.load(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final surahs = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: surahs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final s = surahs[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${s.id}')),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${s.ayahCount} آية'),
                  trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => MushafScreen(surahId: s.id)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class QuranSearchDelegate extends SearchDelegate<String?> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<QuranSurah>>(
      future: QuranRepository.search(query),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final results = snap.data!;
        if (results.isEmpty) return const Center(child: Text('لا توجد نتائج'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: results.length,
          itemBuilder: (_, i) {
            final s = results[i];
            return Card(
              child: ExpansionTile(
                title: Text(s.name),
                subtitle: Text('${s.verses.length} نتيجة'),
                children: s.verses.map((v) => ListTile(
                  title: Text(v.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, height: 1.7)),
                  trailing: Text('${s.id}:${v.ayah}'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MushafScreen(surahId: s.id, initialAyah: v.ayah))),
                )).toList(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => const Center(child: Text('اكتب كلمة للبحث داخل القرآن'));
}


class QuranSourceScreen extends StatelessWidget {
  const QuranSourceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مصدر المصحف')), 
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المصحف يعمل Offline', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 14),
            Text('تم تضمين نص عربي عثماني محلي داخل التطبيق، مع حفظ مصدره وملف الترخيص داخل assets/quran.'),
            SizedBox(height: 14),
            Text('نحتفظ بمعلومات المصدر داخل التطبيق حفاظًا على حقوق وشروط الاستخدام.'),
          ],
        ),
      ),
    );
  }
}

/* ========================= PRAYER ========================= */


class PrayerCity {
  final String name;
  final double lat;
  final double lon;
  const PrayerCity(this.name, this.lat, this.lon);
}

const prayerCities = [
  PrayerCity('القاهرة', 30.0444, 31.2357),
  PrayerCity('الجيزة', 30.0131, 31.2089),
  PrayerCity('الإسكندرية', 31.2001, 29.9187),
  PrayerCity('الأقصر', 25.6872, 32.6396),
  PrayerCity('أسوان', 24.0889, 32.8998),
];

class PrayerTimes {
  final Map<String, DateTime> times;
  const PrayerTimes(this.times);
}

class PrayerCalculator {
  static double _deg(double v) => v * math.pi / 180.0;
  static double _rad(double v) => v * 180.0 / math.pi;

  static PrayerTimes calculate({required DateTime date, required double lat, required double lon, required Duration zone}) {
    final n = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final gamma = 2 * math.pi / 365 * (n - 1);
    final eq = 229.18 * (0.000075 + 0.001868 * math.cos(gamma) - 0.032077 * math.sin(gamma)
        - 0.014615 * math.cos(2 * gamma) - 0.040849 * math.sin(2 * gamma));
    final decl = 0.006918 - 0.399912 * math.cos(gamma) + 0.070257 * math.sin(gamma)
        - 0.006758 * math.cos(2 * gamma) + 0.000907 * math.sin(2 * gamma)
        - 0.002697 * math.cos(3 * gamma) + 0.00148 * math.sin(3 * gamma);
    final tz = zone.inMinutes / 60.0;
    final noon = 720 - 4 * lon - eq + tz * 60;

    double angle(double zenith) {
      final cosH = (math.cos(_deg(zenith)) - math.sin(_deg(lat)) * math.sin(decl)) /
          (math.cos(_deg(lat)) * math.cos(decl));
      final c = cosH.clamp(-1.0, 1.0).toDouble();
      return 4 * _rad(math.acos(c));
    }

    double asrHourAngle() {
      final factor = 1.0;
      final altitude = math.atan(1 / (factor + math.tan((PrayerCalculator._deg(lat) - decl).abs())));
      final zenith = 90 - PrayerCalculator._rad(altitude);
      return angle(zenith);
    }

    DateTime at(double minutes) {
      final total = minutes.round();
      return DateTime(date.year, date.month, date.day).add(Duration(minutes: total));
    }

    final fajr = noon - angle(108);
    final sunrise = noon - angle(90.833);
    final sunset = noon + angle(90.833);
    final isha = noon + angle(108);
    final asr = noon + asrHourAngle();
    return PrayerTimes({
      'الفجر': at(fajr),
      'الشروق': at(sunrise),
      'الظهر': at(noon),
      'العصر': at(asr),
      'المغرب': at(sunset),
      'العشاء': at(isha),
    });
  }
}

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});
  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final prayers = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
  Map<String, bool> done = {};
  PrayerCity city = prayerCities.first;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDay = p.getString('prayer_day');
    if (savedDay != today) {
      for (final x in prayers) await p.setBool('prayer_$x', false);
      await p.setString('prayer_day', today);
    }
    final cityName = p.getString('prayer_city') ?? 'القاهرة';
    final selected = prayerCities.firstWhere((c) => c.name == cityName, orElse: () => prayerCities.first);
    if (!mounted) return;
    setState(() {
      city = selected;
      done = {for (final x in prayers) x: p.getBool('prayer_$x') ?? false};
    });
  }

  Future<void> toggle(String prayer, bool value) async {
    final p = await SharedPreferences.getInstance();
    final old = p.getBool('prayer_$prayer') ?? false;
    await p.setBool('prayer_$prayer', value);
    if (value && !old) await p.setInt('points', (p.getInt('points') ?? 0) + 5);
    if (!value && old) {
      final next = (p.getInt('points') ?? 0) - 5;
      await p.setInt('points', next < 0 ? 0 : next);
    }
    setState(() => done[prayer] = value);
  }

  @override
  void initState() { super.initState(); load(); }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final times = PrayerCalculator.calculate(date: now, lat: city.lat, lon: city.lon, zone: now.timeZoneOffset);
    return Scaffold(
      appBar: AppBar(title: const Text('🕌 مواقيت الصلاة')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: DropdownButtonFormField<PrayerCity>(
                value: city,
                isExpanded: true,
                items: prayerCities.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  final p = await SharedPreferences.getInstance();
                  await p.setString('prayer_city', v.name);
                  setState(() => city = v);
                },
                decoration: const InputDecoration(labelText: 'المدينة لحساب المواقيت', border: OutlineInputBorder()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...prayers.map((prayer) => Card(
            child: CheckboxListTile(
              value: done[prayer] ?? false,
              onChanged: (v) => toggle(prayer, v ?? false),
              title: Text(prayer, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(_formatTime(times.times[prayer]!)),
              secondary: const Icon(Icons.mosque),
            ),
          )),
          const SizedBox(height: 6),
          Card(
            child: ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('الشروق'),
              subtitle: Text(_formatTime(times.times['الشروق']!)),
            ),
          ),
          const SizedBox(height: 6),
          const Text('الحساب يتم على الجهاز بدون إنترنت. دقة المواقيت تعتمد على إعدادات الموقع وطريقة الحساب.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

String _formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour >= 12 ? 'م' : 'ص'}';
}

/* ========================= AZKAR ========================= */

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🤲 الأذكار')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AzkarCard(
            icon: '🌅',
            title: 'أذكار الصباح',
            subtitle: 'افتح أذكار الصباح كاملة',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AzkarListScreen(
                  title: 'أذكار الصباح',
                  morning: true,
                ),
              ),
            ),
          ),
          _AzkarCard(
            icon: '🌙',
            title: 'أذكار المساء',
            subtitle: 'افتح أذكار المساء كاملة',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AzkarListScreen(
                  title: 'أذكار المساء',
                  morning: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AzkarCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AzkarCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 34)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_back),
        onTap: onTap,
      ),
    );
  }
}

class AzkarListScreen extends StatefulWidget {
  final String title;
  final bool morning;

  const AzkarListScreen({
    super.key,
    required this.title,
    required this.morning,
  });

  @override
  State<AzkarListScreen> createState() => _AzkarListScreenState();
}

class _AzkarListScreenState extends State<AzkarListScreen> {
  final items = [
    'آية الكرسي',
    'سورة الإخلاص',
    'سورة الفلق',
    'سورة الناس',
    'أصبحنا وأصبح الملك لله، والحمد لله.',
    'اللهم بك أصبحنا وبك أمسينا وإليك النشور.',
    'رضيت بالله ربًا وبالإسلام دينًا وبمحمد ﷺ نبيًا.',
    'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.',
    'سبحان الله وبحمده.',
    'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
  ];

  final Map<int, bool> checked = {};

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final prefix = widget.morning ? 'morning_' : 'evening_';
      for (var i = 0; i < items.length; i++) {
        checked[i] = p.getBool('azkar_${prefix}$i') ?? false;
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> toggleZikr(int i, bool value) async {
    final p = await SharedPreferences.getInstance();
    final prefix = widget.morning ? 'morning_' : 'evening_';
    final key = 'azkar_${prefix}$i';
    final old = p.getBool(key) ?? false;
    await p.setBool(key, value);
    if (value && !old) {
      await p.setInt('points', (p.getInt('points') ?? 0) + 1);
    } else if (!value && old) {
      final next = (p.getInt('points') ?? 0) - 1;
      await p.setInt('points', next < 0 ? 0 : next);
    }
    setState(() => checked[i] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) {
          return Card(
            child: CheckboxListTile(
              value: checked[i] ?? false,
              onChanged: (v) => toggleZikr(i, v ?? false),
              title: Text(items[i], style: const TextStyle(fontSize: 17, height: 1.6)),
              secondary: CircleAvatar(child: Text('${i + 1}')),
            ),
          );
        },
      ),
    );
  }
}

/* ========================= BADGES ========================= */

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});
  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  int points = 0;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      points = p.getInt('points') ?? 0;
      streak = p.getInt('streak') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final badges = BadgeSystem.earned(points, streak);
    return Scaffold(
      appBar: AppBar(title: const Text('🏅 أوسمتي')),
      body: badges.isEmpty
          ? const Center(child: Text('ابدأ التزامك لتحصل على أول وسام 🌱'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
              ),
              itemCount: badges.length,
              itemBuilder: (_, i) => Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      badges[i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/* ========================= TODAY ========================= */

class TodayScreen extends StatelessWidget {
  final VoidCallback onChanged;
  const TodayScreen({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مهام اليوم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'خطتك اليومية 🌱',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: '🕌',
            title: 'الصلوات الخمس',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrayerScreen()),
            ),
          ),
          _ActionCard(
            icon: '📖',
            title: 'ورد القرآن',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WirdScreen()),
            ),
          ),
          _ActionCard(
            icon: '🤲',
            title: 'أذكار الصباح والمساء',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AzkarScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 30)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_back),
        onTap: onTap,
      ),
    );
  }
}

/* ========================= LEAGUE ========================= */

class LeagueScreen extends StatelessWidget {
  final bool isVip;
  const LeagueScreen({super.key, required this.isVip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دوري الملتزمين 🏆')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!isVip)
            Card(
              color: Colors.amber.shade100,
              child: const ListTile(
                title: Text('👑 سجل VIP للمشاركة في الجوائز'),
                subtitle: Text('الدفع الحقيقي سيُربط لاحقًا عبر بوابة دفع آمنة.'),
              ),
            ),
          const ListTile(
            title: Text('🥇 1. أحمد محمد علي - 980 نقطة'),
            subtitle: Text('الجائزة: 500 جنيه'),
          ),
          const ListTile(
            title: Text('🥈 2. فاطمة حسن إبراهيم - 870 نقطة'),
            subtitle: Text('الجائزة: 300 جنيه'),
          ),
          const ListTile(
            title: Text('🥉 3. محمد سعيد محمود - 750 نقطة'),
            subtitle: Text('الجائزة: 200 جنيه'),
          ),
        ],
      ),
    );
  }
}

/* ========================= SETTINGS ========================= */

class SettingsScreen extends StatefulWidget {
  final bool isVip;
  final int points;
  final String name;
  final VoidCallback onChanged;

  const SettingsScreen({
    super.key,
    required this.isVip,
    required this.points,
    required this.name,
    required this.onChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool isVip;

  @override
  void initState() {
    super.initState();
    isVip = widget.isVip;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('حساب ${widget.name}')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(widget.name),
              subtitle: Text(RankSystem.getRank(widget.points)),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('نقاطك: ${widget.points}'),
              subtitle: const Text('استمر لتفتح رتبًا وأوسمة جديدة'),
            ),
          ),
          if (!isVip)
            Card(
              child: ListTile(
                title: const Text('👑 ترقية إلى VIP'),
                subtitle: const Text(
                  'تحفيزات حصرية • دوري الجوائز • ثيم ذهبي',
                ),
                trailing: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VipRegisterScreen(),
                    ),
                  ),
                  child: const Text('VIP'),
                ),
              ),
            )
          else
            Card(
              color: Colors.amber.shade700,
              child: ListTile(
                title: Text(
                  'أنت VIP يا ${widget.name} 👑',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'استمر في التزامك، اسمك قريب من لوحة الشرف 💎',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
            onPressed: () async {
              final p = await SharedPreferences.getInstance();
              await p.setBool('loggedIn', false);
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
