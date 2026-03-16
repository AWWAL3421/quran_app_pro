import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';
import 'quran_data.dart';
import 'quran_themes_data.dart'; 
import 'tafsir_view.dart'; 
import 'sabab_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuranApp());
}

class QuranApp extends StatefulWidget {
  const QuranApp({super.key});
  @override
  State<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends State<QuranApp> {
  ThemeMode _themeMode = ThemeMode.light;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light, 
        scaffoldBackgroundColor: const Color.fromARGB(255, 233, 215, 143),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4AF37)),
      ),
      darkTheme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: Colors.black),
      home: HomeScreen(onThemeChanged: () => setState(() => _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light)),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  const HomeScreen({super.key, required this.onThemeChanged});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = "All";
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  int? _lastReadSurah;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _lastReadSurah = prefs.getInt('lastRead'));
  }

  void _processSearch(String text) {
    String input = text.toLowerCase().trim();
    if (input.isEmpty) return;
    bool found = false;
    for (int i = 1; i <= 114; i++) {
      if (input.contains(quran.getSurahName(i).toLowerCase()) || input == i.toString()) {
        found = true;
        Navigator.push(context, MaterialPageRoute(builder: (c) => MushafView(surahNumber: i))).then((_) => _loadProgress());
        break;
      }
    }
    if (!found) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Surah not found."), backgroundColor: Colors.red),
      );
    }
  }

  void _startVoice() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        if (val.finalResult) {
          setState(() => _isListening = false);
          _processSearch(val.recognizedWords);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color gold = isDark ? const Color(0xFFB76E79) : const Color(0xFFD4AF37);
    final surahs = List.generate(114, (i) => i + 1).where((sNum) {
      if (_selectedFilter == "All") return true;
      return quran.getPlaceOfRevelation(sNum) == _selectedFilter;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100, pinned: true,
            title: Text("AL - Quran Pro", style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
            actions: [
              if (_lastReadSurah != null) 
                IconButton(icon: const Icon(Icons.history), onPressed: () => _processSearch(_lastReadSurah.toString())),
              IconButton(icon: const Icon(Icons.brightness_4), onPressed: widget.onThemeChanged)
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(color: gold.withAlpha(30), borderRadius: BorderRadius.circular(15)),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(hintText: "Search Surah...", border: InputBorder.none),
                        onSubmitted: _processSearch,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: _isListening ? Colors.red : gold,
                    child: IconButton(
                      icon: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white), 
                      onPressed: _startVoice,
                    ),
                  )
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: [
                  _studyButton("Topic Index", Icons.format_list_bulleted, Colors.purple, () => _showTopicIndex()),
                  _studyButton("Themes", Icons.auto_awesome, Colors.orange, () => _showThemes()),
                  _studyButton("Juz View", Icons.grid_view_rounded, Colors.green, () => _showJuzView()), 
                  _studyButton("Tafsir", Icons.menu_book_rounded, Colors.blue, () => _showTafsirGrid()),
                  _studyButton("Sababu-n-Nuzul", Icons.history_edu, Colors.purple, () => _showSababGrid()),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: ["All", "Makkah", "Madinah"].map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f), 
                    selected: _selectedFilter == f, 
                    onSelected: (v) => setState(() => _selectedFilter = f)
                  ),
                )).toList(),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((c, i) {
              int sNum = surahs[i];
              return ListTile(
                leading: Text("$sNum", style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                title: Text(quran.getSurahName(sNum)),
                subtitle: Text("${quran.getPlaceOfRevelation(sNum)} • ${quran.getVerseCount(sNum)} Ayahs"),
                trailing: Text(quran.getSurahNameArabic(sNum), style: GoogleFonts.notoNaskhArabic(color: gold)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => MushafView(surahNumber: sNum))),
              );
            }, childCount: surahs.length),
          ),
        ],
      ),
    );
  }

  Widget _studyButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, color: color), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))],
        ),
      ),
    );
  }

  // --- NEW: SABABU-N-NUZUL GRID ---
  void _showSababGrid() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color gold = isDark ? const Color(0xFFB76E79) : const Color(0xFFD4AF37);
    final List<int> allSurahs = List.generate(114, (i) => i + 1);
    List<int> filteredSurahs = List.from(allSurahs);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 50, height: 5,
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text("Sababu-n-Nuzul", 
                        style: GoogleFonts.philosopher(fontSize: 22, fontWeight: FontWeight.bold, color: gold)),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: gold.withAlpha(20),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: gold.withAlpha(40)),
                        ),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Search Surah...",
                            border: InputBorder.none,
                            icon: Icon(Icons.history, size: 20),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              filteredSurahs = allSurahs.where((sNum) {
                                final name = quran.getSurahName(sNum).toLowerCase();
                                return name.contains(val.toLowerCase()) || sNum.toString() == val;
                              }).toList();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: filteredSurahs.length,
                    itemBuilder: (context, index) {
                      int sNum = filteredSurahs[index];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (c) => SababView(surahNumber: sNum)
                          ));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: gold.withAlpha(15),
                            border: Border.all(color: gold.withAlpha(30)),
                          ),
                          child: Center(
                            child: Text(quran.getSurahName(sNum), 
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- EXISTING TAFSIR METHODS ---
  void _showTafsirGrid() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color gold = isDark ? const Color(0xFFB76E79) : const Color(0xFFD4AF37);
    
    final List<int> allSurahs = List.generate(114, (i) => i + 1);
    List<int> filteredSurahs = List.from(allSurahs);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 50, height: 5,
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text("Select Surah for Tafsir", 
                        style: GoogleFonts.philosopher(fontSize: 22, fontWeight: FontWeight.bold, color: gold)),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: gold.withAlpha(20),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: gold.withAlpha(40)),
                        ),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Search by name or number...",
                            border: InputBorder.none,
                            icon: Icon(Icons.search, size: 20),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              filteredSurahs = allSurahs.where((sNum) {
                                final name = quran.getSurahName(sNum).toLowerCase();
                                return name.contains(val.toLowerCase()) || sNum.toString() == val;
                              }).toList();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: filteredSurahs.isEmpty 
                  ? Center(child: Text("No Surah found", style: TextStyle(color: gold.withAlpha(150))))
                  : GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: filteredSurahs.length,
                    itemBuilder: (context, index) {
                      int sNum = filteredSurahs[index];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showAyahPickerForTafsir(sNum);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: isDark 
                                ? [gold.withAlpha(50), gold.withAlpha(20)] 
                                : [gold.withAlpha(40), gold.withAlpha(10)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: gold.withAlpha(60)),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: -5, left: 10,
                                child: Text("$sNum", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: gold.withAlpha(30))),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      quran.getSurahNameArabic(sNum),
                                      style: GoogleFonts.notoNaskhArabic(fontSize: 18, fontWeight: FontWeight.bold, color: gold),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(width: double.infinity),
                                        Text(quran.getSurahName(sNum), 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text("${quran.getVerseCount(sNum)} Ayahs", 
                                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAyahPickerForTafsir(int surahNumber) {
    final gold = Theme.of(context).brightness == Brightness.dark ? const Color(0xFFB76E79) : const Color(0xFFD4AF37);
    int verseCount = quran.getVerseCount(surahNumber);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Select Ayah from ${quran.getSurahName(surahNumber)}", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: gold)),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: verseCount,
                itemBuilder: (context, index) {
                  int aNum = index + 1;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (c) => TafsirView(surahNumber: surahNumber, ayahNumber: aNum)
                      ));
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: gold.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: gold.withAlpha(50)),
                      ),
                      child: Text("$aNum", style: TextStyle(fontWeight: FontWeight.bold, color: gold)),
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

  void _showTopicIndex() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(15), child: Text("Topic Index (A-Z)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: QuranIndexData.topics.keys.map((letter) => ExpansionTile(
                  title: Text(letter, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: QuranIndexData.topics[letter]!.map((topicItem) => ExpansionTile(
                    title: Text(topicItem['topic']),
                    children: (topicItem['verses'] as List<Map<String, int>>).map((ref) => ListTile(
                      title: Text("Surah ${quran.getSurahName(ref['s']!)} : Ayah ${ref['a']}"),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => MushafView(surahNumber: ref['s']!, highlightAyah: ref['a']))),
                    )).toList(),
                  )).toList(),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemes() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color gold = isDark ? const Color(0xFFB76E79) : const Color(0xFFD4AF37);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
              Text("Major Themes", style: GoogleFonts.philosopher(fontSize: 22, fontWeight: FontWeight.bold, color: gold)),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: ThemeDataCollection.fazlurRahmanThemes.length,
                  itemBuilder: (context, index) {
                    final theme = ThemeDataCollection.fazlurRahmanThemes[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: gold.withAlpha(20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: gold.withAlpha(40))),
                      child: ExpansionTile(
                        leading: CircleAvatar(backgroundColor: gold.withAlpha(40), child: Text("${index + 1}", style: TextStyle(color: gold, fontWeight: FontWeight.bold))),
                        title: Text(theme.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: theme.verses.map((v) => ListTile(
                          dense: true,
                          title: Text("Surah ${quran.getSurahName(v['s']!)} : Ayah ${v['a']}"),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => MushafView(surahNumber: v['s']!, highlightAyah: v['a']))),
                        )).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJuzView() {
    final Map<int, List<int>> juzMap = {
      1: [1, 1], 2: [2, 142], 3: [2, 253], 4: [3, 93], 5: [4, 24],
      6: [4, 148], 7: [5, 82], 8: [6, 111], 9: [7, 88], 10: [8, 41],
      11: [9, 93], 12: [11, 6], 13: [12, 53], 14: [15, 1], 15: [17, 1],
      16: [18, 75], 17: [21, 1], 18: [23, 1], 19: [25, 21], 20: [27, 56],
      21: [29, 46], 22: [33, 31], 23: [36, 28], 24: [39, 32], 25: [41, 47],
      26: [46, 1], 27: [51, 31], 28: [58, 1], 29: [67, 1], 30: [78, 1],
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(15), child: Text("Select Juz", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.2, mainAxisSpacing: 10, crossAxisSpacing: 10),
                itemCount: 30,
                itemBuilder: (context, index) {
                  int juzNumber = index + 1;
                  return InkWell(
                    onTap: () {
                      List<int> startPoint = juzMap[juzNumber]!;
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (c) => MushafView(surahNumber: startPoint[0], highlightAyah: startPoint[1])));
                    },
                    child: Container(
                      decoration: BoxDecoration(color: Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Juz", style: TextStyle(fontSize: 12, color: Colors.green)),
                          Text("$juzNumber", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
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

// --- MUSHAF VIEW ---
class MushafView extends StatefulWidget {
  final int surahNumber;
  final int? highlightAyah;
  const MushafView({super.key, required this.surahNumber, this.highlightAyah});

  @override
  State<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<MushafView> {
  bool _showTranslation = true; 
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _saveProgress();
    if (widget.highlightAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToAyah());
    }
  }

  void _jumpToAyah() {
    double position = (widget.highlightAyah! - 1) * 220.0; 
    _scrollController.animateTo(position, duration: const Duration(seconds: 1), curve: Curves.easeInOut);
  }

  void _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastRead', widget.surahNumber);
  }

  @override
  void dispose() {
    _scrollController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).brightness == Brightness.dark ? const Color(0xFFB76E79) : const Color(0xFFD4AF37);
    bool needsBasmala = widget.surahNumber != 1 && widget.surahNumber != 9;

    return Scaffold(
      appBar: AppBar(
        title: Text(quran.getSurahName(widget.surahNumber)),
        actions: [
          IconButton(
            icon: Icon(_showTranslation ? Icons.translate : Icons.g_translate),
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController, 
        padding: const EdgeInsets.all(20),
        itemCount: quran.getVerseCount(widget.surahNumber) + (needsBasmala ? 1 : 0),
        itemBuilder: (context, i) {
          if (needsBasmala && i == 0) {
            return Column(
              children: [
                Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", textAlign: TextAlign.center, style: GoogleFonts.notoNaskhArabic(fontSize: 30, color: gold, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
              ],
            );
          }
          int ayah = needsBasmala ? i : i + 1;
          bool isHighlighted = widget.highlightAyah == ayah;

          return Container(
            color: isHighlighted ? gold.withAlpha(40) : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(icon: Icon(Icons.share, size: 18, color: gold), onPressed: () => Share.share("${quran.getVerse(widget.surahNumber, ayah)}\n\n[Surah ${quran.getSurahName(widget.surahNumber)}: $ayah]")),
                        IconButton(icon: Icon(Icons.menu_book_rounded, size: 18, color: gold), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TafsirView(surahNumber: widget.surahNumber, ayahNumber: ayah)))),
                      ],
                    ),
                    Column(
                      children: [
                        Text("Pg ${quran.getPageNumber(widget.surahNumber, ayah)}", style: TextStyle(fontSize: 9, color: gold.withAlpha(180))),
                        const SizedBox(height: 4),
                        CircleAvatar(radius: 12, backgroundColor: gold.withAlpha(30), child: Text("$ayah", style: TextStyle(fontSize: 10, color: gold))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(quran.getVerse(widget.surahNumber, ayah, verseEndSymbol: true), textAlign: TextAlign.right, style: GoogleFonts.notoNaskhArabic(fontSize: 24, height: 2)),
                if (_showTranslation)
                  Padding(padding: const EdgeInsets.only(top: 10), child: Text(quran.getVerseTranslation(widget.surahNumber, ayah), textAlign: TextAlign.left, style: const TextStyle(fontSize: 14, color: Colors.grey))),
                const Divider(),
              ],
            ),
          );
        },
      ),
    );
  }
}