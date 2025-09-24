// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/rich_ai_response.dart';
import '../models/user.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  User? _currentUser;
  late final AIService _aiService;
  late final FirebaseService _firebaseService;
  bool _isInitializing = true; // Use a dedicated flag for initial setup

  List<String> _currentSuggestions = [];

  @override
  void initState() {
    super.initState();
    _aiService = Provider.of<AIService>(context, listen: false);
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _initializeServices();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _fetchCurrentUser();

    String apiKey = '';
    try {
      // Use the single, correct channel name
      const MethodChannel channel =
          MethodChannel('com.example.hoops_lab_v1/native_secrets');
      apiKey = await channel.invokeMethod('getGeminiApiKey') ?? '';
      print(
          "--- Successfully fetched Gemini API Key from native. Length: ${apiKey.length} ---");
    } catch (e) {
      print("--- CRITICAL: Failed to get Gemini API key: $e ---");
    }

    await _aiService.initialize(apiKey);

    if (mounted) {
      setState(() {
        _isInitializing = false; // Turn off initial loading
        _messages.add(
          ChatMessage(
            text:
                "Hello! I'm your HoopsLab AI Assistant. Ask me about player performance or the team's last game.",
            author: ChatAuthor.ai,
          ),
        );
        _currentSuggestions = [
          "How did the team do last game?",
          "Who was our top scorer?",
          "Summarize Calvin's performance",
        ];
      });
    }
  }

  Future<void> _fetchCurrentUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      _currentUser =
          await _firebaseService.getUserById(authService.currentUser!.uid);
    }
  }

  void _handleSendPressed({String? textOverride}) async {
    final text = textOverride ?? _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.insert(0, ChatMessage(text: text, author: ChatAuthor.user));
      _isLoading = true;
      _currentSuggestions = [];
    });

    _scrollToTop();

    final RichAIResponse aiResponse =
        await _aiService.getResponse(text, _firebaseService, _currentUser);

    // --- THIS IS THE FIX ---
    // Before calling the final setState, check if the widget is still on the screen.
    if (mounted) {
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text: aiResponse.responseText,
            author: ChatAuthor.ai,
            dataSource: aiResponse.dataSource,
          ),
        );
        _currentSuggestions = aiResponse.suggestedPrompts;
        _isLoading = false;
      });
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    Future.delayed(Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("AI Performance Assistant"),
          backgroundColor: Colors.orange),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(8.0),
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          if (_isLoading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(width: 16),
                Text("AI is thinking...")
              ]),
            ),
          if (!_isLoading && _currentSuggestions.isNotEmpty)
            _buildSuggestions(),
          _buildTextInputArea(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _currentSuggestions.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _currentSuggestions[index];
          return ActionChip(
            label: Text(suggestion),
            onPressed: () => _handleSendPressed(textOverride: suggestion),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.author == ChatAuthor.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.orange : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: TextStyle(color: Colors.white)),
            if (message.dataSource != null) ...[
              SizedBox(height: 8),
              Text(
                "Data Source: ${message.dataSource}",
                style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                    fontStyle: FontStyle.italic),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputArea() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Ask about a player or game...",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _handleSendPressed(),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Colors.orange),
            onPressed: _isLoading ? null : _handleSendPressed,
          ),
        ],
      ),
    );
  }
}
