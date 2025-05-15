import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonEncode
import 'package:speech_to_text/speech_to_text.dart' as stt; // Import the speech_to_text package

class ChatbotPage extends StatefulWidget {
  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Scroll controller

  // Sample conversations for demonstration
  List<List<Map<String, String>>> conversations = [
    [{'sender': 'bot', 'text': 'Welcome to Chat 1!'}],
    [{'sender': 'bot', 'text': 'Welcome to Chat 2!'}],
    [{'sender': 'bot', 'text': 'Welcome to Chat 3!'}],
  ];
  int selectedConversationIndex = 0;

  bool _isListening = false;  // Track if the microphone is listening
  String _speechText = '';     // Store recognized speech input
  stt.SpeechToText _speech = stt.SpeechToText(); // Speech recognition instance

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to the conversation
    setState(() {
      conversations[selectedConversationIndex].add({'sender': 'user', 'text': message});
    });

    // Clear the input field
    _controller.clear();

    // Scroll to the bottom after sending a message
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.204.31:5000/chat'), // Your Flask server URL
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

    // Scroll to the bottom after receiving a response
    _scrollToBottom();
  }

  // Method to scroll to the bottom of the chat messages
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
          _isListening = true; // Start listening for voice input
          _speechText = '';    // Clear previous text
        });

        _speech.listen(onResult: (result) {
          setState(() {
            _speechText = result.recognizedWords; // Update recognized text
            _controller.text = _speechText;       // Populate input field
          });
        });
      }
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false; // Stop listening
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        actions: [
          // Dropdown for selecting chat
          DropdownButton<int>(
            dropdownColor: Colors.grey[900],
            value: selectedConversationIndex + 1,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            onChanged: (int? newValue) {
              setState(() {
                selectedConversationIndex = newValue! - 1; // Convert 1,2,3 to 0,1,2
                _scrollToBottom(); // Scroll to the bottom when changing chats
              });
            },
            items: [
              DropdownMenuItem<int>(
                value: 1,
                child: Text('Chat 1', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem<int>(
                value: 2,
                child: Text('Chat 2', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem<int>(
                value: 3,
                child: Text('Chat 3', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Assign the controller
              padding: EdgeInsets.all(8),
              itemCount: conversations[selectedConversationIndex].length,
              itemBuilder: (context, index) {
                return _buildMessage(conversations[selectedConversationIndex][index]);
              },
            ),
          ),
          // Chat input area
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (value) {
                      _sendMessage(value); // Send message on submit
                    },
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
                      color: _isListening ? Colors.red : Colors.white  // Highlight mic icon red when recording
                  ),
                  onPressed: () {
                    if (_isListening) {
                      _stopListening(); // Stop listening
                    } else {
                      _startListening(); // Start voice input listening
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true, // Ensures that layout will adjust when keyboard appears
    );
  }
}