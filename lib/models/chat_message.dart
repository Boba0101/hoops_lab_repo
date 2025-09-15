// lib/models/chat_message.dart

enum ChatAuthor { user, ai }

class ChatMessage {
  final String text;
  final ChatAuthor author;
  final String? dataSource; // Add this field

  ChatMessage({
    required this.text,
    required this.author,
    this.dataSource, // Add to constructor
  });
}
