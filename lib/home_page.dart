import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'sidebar.dart';  // Import the Sidebar widget

class ChatbotPage extends StatefulWidget {
  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  List<List<Map<String, String>>> conversations = [
    [{'sender': 'bot', 'text': 'Welcome to the Pipe Burst chat! How can I assist you with this issue?'}],
    [{'sender': 'bot', 'text': 'Welcome to the Electrical Shortage chat! What details can you provide about the problem?'}],
    [{'sender': 'bot', 'text': 'Welcome to the Other Issues chat! Please describe the maintenance problem you\'re facing.'}],
  ]; 
  int selectedConversationIndex = 0;

  List<String> chatTitles = ['Pipe Burst', 'Electrical Shortage', 'Other Issues'];

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;
    setState(() {
      conversations[selectedConversationIndex].add({'sender': 'user', 'text': message});
      conversations[selectedConversationIndex].add({
        'sender': 'bot', 
        'text': 'Thank you for providing information about the ${chatTitles[selectedConversationIndex]}. A technician will review your message and respond shortly.'
      });
    });
    _controller.clear();
  }

  Widget _buildMessage(Map<String, String> message) {
    bool isUser = message['sender'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message['text'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !kIsWeb
          ? AppBar(
              title: Text('Maintenance Chat', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.grey[900],
            )
          : null,
      body: Row(
        children: [
          Sidebar(
            conversations: chatTitles,
            onConversationSelected: (index) {
              setState(() {
                selectedConversationIndex = index;
              });
            },
            selectedConversationIndex: selectedConversationIndex,
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: conversations[selectedConversationIndex].length,
                    itemBuilder: (context, index) {
                      return _buildMessage(conversations[selectedConversationIndex][index]);
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: Colors.grey[900],
                  child: Row(
                    children: [
                      Expanded(
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
            ),
          ),
        ],
      ),
    );
  }
}