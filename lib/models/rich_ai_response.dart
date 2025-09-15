// lib/models/rich_ai_response.dart

class RichAIResponse {
  /// The main text content of the AI's reply.
  final String responseText;

  /// A list of suggested, tappable follow-up questions for the user.
  final List<String> suggestedPrompts;

  /// Optional: The name of the data source document (e.g., game title) for transparency.
  final String? dataSource;

  RichAIResponse({
    required this.responseText,
    this.suggestedPrompts = const [], // Default to an empty list
    this.dataSource,
  });
}
