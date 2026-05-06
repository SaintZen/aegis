/// A single section within an Intelligence Briefing.
class ResourceArticle {
  const ResourceArticle({
    required this.title,
    required this.body,
    this.subtitle,
    this.quickActions,
  });

  final String title;
  final String? subtitle;
  final String body;
  /// Optional: State → Tool pairs for rapid reference (e.g. Quick Action table).
  final List<QuickActionRow>? quickActions;
}

/// A row in a Quick Action table: State → Tool.
class QuickActionRow {
  const QuickActionRow({
    required this.state,
    required this.tool,
  });

  final String state;
  final String tool;
}
