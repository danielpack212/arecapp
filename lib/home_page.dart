import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'sidebar.dart';

class ChatbotPage extends StatefulWidget {
  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<List<Map<String, String>>> conversations = [
    [{'sender': 'bot', 'text': 'Welcome to the Pipe Burst chat! How can I assist you with this issue?'}],
    [{'sender': 'bot', 'text': 'Welcome to the Electrical Shortage chat! What details can you provide about the problem?'}],
    [{'sender': 'bot', 'text': 'Welcome to the Other Issues chat! Please describe the maintenance problem you\'re facing.'}],
  ];
  int selectedConversationIndex = 0;

  List<String> chatTitles = ['Pipe Burst', 'Electrical Shortage', 'Other Issues'];

  bool _isListening = false;
  String _speechText = '';
  stt.SpeechToText _speech = stt.SpeechToText();

  bool isWebPlatform() {
    return kIsWeb;
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      conversations[selectedConversationIndex].add({'sender': 'user', 'text': message});
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.204.31:5000/chat'), // Update this URL to your server
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

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _speechText = '';
        });

        _speech.listen(onResult: (result) {
          setState(() {
            _speechText = result.recognizedWords;
            _controller.text = _speechText;
          });
        });
      }
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
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

  Widget _buildDropdown() {
    return DropdownButton<int>(
      dropdownColor: Colors.grey[900],
      value: selectedConversationIndex + 1,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      onChanged: (int? newValue) {
        setState(() {
          selectedConversationIndex = newValue! - 1;
          _scrollToBottom();
        });
      },
      items: List.generate(chatTitles.length, (index) {
        return DropdownMenuItem<int>(
          value: index + 1,
          child: Text(chatTitles[index], style: TextStyle(color: Colors.white)),
        );
      }),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(8),
      itemCount: conversations[selectedConversationIndex].length,
      itemBuilder: (context, index) {
        return _buildMessage(conversations[selectedConversationIndex][index]);
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
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
            icon: Icon(
              Icons.mic,
              color: _isListening ? Colors.red : Colors.white
            ),
            onPressed: () {
              if (_isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: () => _sendMessage(_controller.text),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: _buildChatList(),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Row(
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
                child: _buildChatList(),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = isWebPlatform();

    return Scaffold(
      appBar: isWeb 
        ? null  // This will hide the AppBar on web
        : AppBar(
        title: Text('Chatbot', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        actions:[
          _buildDropdown(),
        ],
      ),
      body: isWeb ? _buildWebLayout() : _buildMobileLayout(),
      resizeToAvoidBottomInset: true,
    );
  }
}