import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ChatbotPage extends StatefulWidget {
  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;
    setState(() {
      _messages.add({'sender': 'user', 'text': message});
      _messages.add({'sender': 'bot', 'text': 'Thanks for your message!'});
    });
    _controller.clear();
  }

  Widget _buildMessage(Map<String, String> message) {
    bool isUser = message['sender'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8, // Constrain width for messages
        ),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: isUser ? Colors.blue : Colors.green),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double textFieldWidth = kIsWeb ? 600 : double.infinity;
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows)) {
      textFieldWidth = 600;
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(top: 10),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _buildMessage(_messages[index]);
            },
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Colors.grey[900],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: textFieldWidth == double.infinity
                    ? MediaQuery.of(context).size.width - 80 // Account for padding and button width
                    : textFieldWidth,
                child: TextField(
                  controller: _controller,
                  onSubmitted: (value) => _sendMessage(value),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(_controller.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}