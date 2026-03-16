import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quran/quran.dart' as quran;

class TafsirView extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;

  const TafsirView({super.key, required this.surahNumber, required this.ayahNumber});

  @override
  State<TafsirView> createState() => _TafsirViewState();
}

class _TafsirViewState extends State<TafsirView> {
  final Map<int, String> _availableTafsirs = {
    169: "Ibn Kathir (English)",
    168: "Ma'arif-ul-Quran (English)",
    74: "Al-Jalalayn (Arabic)",
    99: "Al-Mizan (English)",
    16: "Tafsir Muyassar (Arabic)",
  };

  int _selectedTafsirId = 169; 
  String _tafsirContent = "";
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchTafsir();
  }

  Future<void> _fetchTafsir() async {
    setState(() {
      _isLoading = true;
      _errorMessage = ""; 
    });

    final url = Uri.parse(
        'https://api.quran.com/api/v4/tafsirs/$_selectedTafsirId/by_ayah/${widget.surahNumber}:${widget.ayahNumber}');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'QuranProApp/1.0', 
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tafsirContent = data['tafsir']['text'] ?? "No content available.";
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Server Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection Failed. Check your internet.";
        _isLoading = false;
      });
      debugPrint("Dev Log Error: $e");
    }
  }

  String _cleanHtml(String htmlString) {
    if (htmlString.isEmpty) return "";
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '') 
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ') 
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Updated gold color to use newer withValues if necessary, 
    // but the constant itself is fine as is.
    final Color gold = isDark ? const Color(0xFFB76E79) : const Color(0xFFD4AF37);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${quran.getSurahName(widget.surahNumber)} [${widget.surahNumber}:${widget.ayahNumber}]",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          DropdownButton<int>(
            value: _selectedTafsirId,
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: gold),
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() => _selectedTafsirId = newValue);
                _fetchTafsir();
              }
            },
            items: _availableTafsirs.entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(entry.value, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: gold))
          : _errorMessage.isNotEmpty
              ? _buildErrorUI(gold)
              : _buildTafsirBody(isDark, gold),
    );
  }

  Widget _buildErrorUI(Color gold) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fixed: using .withValues instead of .withOpacity
          Icon(Icons.cloud_off, size: 40, color: gold.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Text(_errorMessage),
          TextButton(
            onPressed: _fetchTafsir, 
            child: Text("Try Again", style: TextStyle(color: gold))
          ),
        ],
      ),
    );
  }

  Widget _buildTafsirBody(bool isDark, Color gold) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              // Fixed: using .withValues instead of .withOpacity
              color: gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _availableTafsirs[_selectedTafsirId]!.toUpperCase(),
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: gold, 
                letterSpacing: 1.1
              ),
            ),
          ),
          const Divider(height: 30),
          Text(
            _cleanHtml(_tafsirContent),
            style: TextStyle(
              fontSize: 17,
              height: 1.8,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}