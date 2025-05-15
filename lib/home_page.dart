import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonEncode
import 'sidebar.dart';  // Import the Sidebar widget

class ChatbotPage extends StatefulWidget {
  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  List<List<Map<String, String>>> conversations = [
    [{'sender': 'bot', 'text': 'Welcome to Chat 0!'}],
    [{'sender': 'bot', 'text': 'Welcome to Chat 1!'}],
    [{'sender': 'bot', 'text': 'Welcome to Chat 2!'}],
  ];
  int selectedConversationIndex = 0;

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to the conversation
    setState(() {
      conversations[selectedConversationIndex].add({'sender': 'user', 'text': message});
    });

    // Clear the input field
    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.204.31:5000/chat'), // Substitute with your Flask server's URL
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'text': message,
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String botReply = responseData['answer'];

        // Add bot response to the conversation
        setState(() {
          conversations[selectedConversationIndex].add({'sender': 'bot', 'text': botReply});
        });
      } else {
        setState(() {
          conversations[selectedConversationIndex].add({'sender': 'bot', 'text': 'Failed to get response!'});
        });
      }
    } catch (e) {
      setState(() {
        conversations[selectedConversationIndex].add({'sender': 'bot', 'text': 'Error: ${e.toString()}'});
      });
    }
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
      appBar: !kIsWeb ? AppBar(
        title: Text('Chatbot', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ) : null,
      body: Row(
        children: [
          Expanded(
            child: SingleChildScrollView( // Allow scrolling
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
          ),
        ],
      ),
      drawer: Drawer(
        child: Sidebar(
          conversations: List.generate(conversations.length, (index) => 'Chat $index'),
          onConversationSelected: (index) {
            setState(() {
              selectedConversationIndex = index;
            });
            Navigator.of(context).pop(); // Close the drawer after selection
          },
          selectedConversationIndex: selectedConversationIndex,
        ),
      ),
      resizeToAvoidBottomInset: true, // Allow the body to resize
    );
  }
}