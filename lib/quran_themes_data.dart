class QuranTheme {
  final String title;
  final String description; // Summarizing Rahman's perspective
  final List<Map<String, int>> verses;

  QuranTheme({
    required this.title, 
    required this.description, 
    required this.verses
  });
}

class ThemeDataCollection {
  static List<QuranTheme> fazlurRahmanThemes = [
    QuranTheme(
      title: "God",
      description: "Focuses on the unique nature of Allah, His mercy, and His role as the Creator.",
      verses: [{"s": 1, "a": 1}, {"s": 2, "a": 255}, {"s": 112, "a": 1}],
    ),
    QuranTheme(
      title: "Man as Individual",
      description: "The nature of the soul, human struggle, and individual responsibility.",
      verses: [{"s": 91, "a": 7}, {"s": 95, "a": 4}, {"s": 75, "a": 14}],
    ),
    QuranTheme(
      title: "Man in Society",
      description: "Social justice, economic fairness, and communal ethics.",
      verses: [{"s": 4, "a": 135}, {"s": 49, "a": 10}, {"s": 2, "a": 177}],
    ),
    QuranTheme(
      title: "Nature",
      description: "Nature as a 'sign' (Ayah) of God and the harmony of the universe.",
      verses: [{"s": 3, "a": 190}, {"s": 30, "a": 20}, {"s": 21, "a": 30}],
    ),
    QuranTheme(
      title: "Prophethood and Revelation",
      description: "The bridge between the Divine and the Human through messengers.",
      verses: [{"s": 2, "a": 213}, {"s": 10, "a": 47}, {"s": 33, "a": 40}],
    ),
    QuranTheme(
      title: "Eschatology (The Hereafter)",
      description: "The end of time, the ultimate judgment, and the life to come.",
      verses: [{"s": 82, "a": 1}, {"s": 39, "a": 68}, {"s": 50, "a": 22}],
    ),
    QuranTheme(
      title: "Satan and Evil",
      description: "The source of distraction and the trial of moral choice.",
      verses: [{"s": 7, "a": 11}, {"s": 35, "a": 6}, {"s": 114, "a": 1}],
    ),
    QuranTheme(
      title: "The Emergence of the Muslim Community",
      description: "The historical struggle and the building of a moral social order.",
      verses: [{"s": 3, "a": 110}, {"s": 2, "a": 143}],
    ),
  ];
}