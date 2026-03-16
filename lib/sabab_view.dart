import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quran/quran.dart' as quran;

class SababView extends StatefulWidget {
  final int surahNumber;
  final int initialAyah;

  const SababView({super.key, required this.surahNumber, this.initialAyah = 1});

  @override
  State<SababView> createState() => _SababViewState();
}

class _SababViewState extends State<SababView> {
  late int selectedAyah;
  late Future<Map<String, dynamic>> _sababFuture;

  @override
  void initState() {
    super.initState();
    selectedAyah = widget.initialAyah;
    _sababFuture = fetchSabab(selectedAyah);
  }

  Future<Map<String, dynamic>> fetchSabab(int ayah) async {
    final url = Uri.parse('https://quranx.com/api/Tafsir/en.wahidi/${widget.surahNumber}/$ayah');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'QuranProApp/1.0', // Essential for QuranX API
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  void _updateAyah(int ayah) {
    setState(() {
      selectedAyah = ayah;
      _sababFuture = fetchSabab(ayah);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color gold = isDark ? const Color(0xFFB76E79) : const Color(0xFFD4AF37);
    int totalAyahs = quran.getVerseCount(widget.surahNumber);

    return Scaffold(
      appBar: AppBar(
        title: Text("Sababu-n-Nuzul", style: GoogleFonts.philosopher()),
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- HORIZONTAL AYAH PICKER ---
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: totalAyahs,
              itemBuilder: (context, index) {
                int ayah = index + 1;
                bool isSelected = selectedAyah == ayah;
                return GestureDetector(
                  onTap: () => _updateAyah(ayah),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 10),
                    width: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? gold : gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: gold.withValues(alpha: 0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "$ayah",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : gold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- CONTENT AREA ---
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _sababFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: gold));
                }

                if (snapshot.hasError) {
                  return _buildErrorWidget(gold);
                }

                final data = snapshot.data?['tafsir'];
                final String content = (data != null && data.isNotEmpty) 
                    ? data[0]['text'] 
                    : "There is no specific 'Sabab' (historical reason) recorded for Ayah $selectedAyah in Al-Wahidi's collection.";

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arabic Verse Preview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: gold.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          quran.getVerse(widget.surahNumber, selectedAyah),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.notoNaskhArabic(fontSize: 20, height: 1.8),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      Row(
                        children: [
                          Icon(Icons.auto_stories, color: gold, size: 20),
                          const SizedBox(width: 10),
                          Text("Historical Context", 
                            style: GoogleFonts.philosopher(fontSize: 18, fontWeight: FontWeight.bold, color: gold)),
                        ],
                      ),
                      const Divider(height: 30),

                      Text(
                        content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                        style: TextStyle(
                          fontSize: 16, 
                          height: 1.7, 
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontStyle: data == null ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Color gold) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 40, color: gold.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          const Text("Could not load data."),
          TextButton(
            onPressed: () => _updateAyah(selectedAyah),
            child: Text("Retry", style: TextStyle(color: gold)),
          )
        ],
      ),
    );
  }
}