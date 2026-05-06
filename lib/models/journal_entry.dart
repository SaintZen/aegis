class JournalEntry {
  final DateTime timestamp;
  final int distressLevel;
  final String note;
  final List<String> symptoms;
  final String mood;

  JournalEntry({
    required this.timestamp,
    required this.distressLevel,
    required this.note,
    required this.symptoms,
    this.mood = 'Neutral',
  });
}
