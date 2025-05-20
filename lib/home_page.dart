import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'sidebar.dart';
import 'chat_provider.dart';
import 'package:provider/provider.dart';


const String BASE_URL =
    'http://192.168.204.45:5000/'; // Replace with your new IP address

class ChatbotPage extends StatefulWidget {
  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late ChatProvider _chatProvider;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  int selectedConversationIndex = 0;

  bool _isListening = false;
  String _speechText = '';
  stt.SpeechToText _speech = stt.SpeechToText();

  bool isWebPlatform() {
    return kIsWeb;
  }

   void _sendMessage(String message) async {
    if (message.trim().isEmpty || _chatProvider.conversations.isEmpty) return;

    // Check if there are any conversations
    if (_chatProvider.conversations.isEmpty) {
      // If no conversations exist, create a new one
      await _chatProvider.addNewChat('New Chat', 'New Conversation');
      setState(() {
        selectedConversationIndex = 0;
      });
    }

    // Ensure the selectedConversationIndex is valid
    if (selectedConversationIndex >= _chatProvider.conversations.length) {
      setState(() {
        selectedConversationIndex = _chatProvider.conversations.length - 1;
      });
    }

    setState(() {
      _chatProvider.conversations[selectedConversationIndex]
          .add({'sender': 'user', 'text': message});
    });

    _controller.clear();
    _scrollToBottom();

    try {
      // Ensure we have a valid ticketId
      String ticketId =
          _chatProvider.chatTitles[selectedConversationIndex].split('#').last;
      if (ticketId.isEmpty) {
        throw Exception('Invalid ticketId');
      }

      final response = await http.post(
        Uri.parse('$BASE_URL/chat'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'text': message,
          'ticketId': ticketId,
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String botReply = responseData['answer'];

        setState(() {
          _chatProvider.conversations[selectedConversationIndex]
              .add({'sender': 'bot', 'text': botReply});
        });
      } else {
        throw Exception('Failed to get response from server');
      }
    } catch (e) {
      print('Error in _sendMessage: $e');
      setState(() {
        _chatProvider.conversations[selectedConversationIndex].add({
          'sender': 'bot',
          'text':
              'Sorry, I encountered an error while processing your message. Please try again later.'
        });
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
    if (_chatProvider.chatTitles.isEmpty) {
      return Container(); // Return an empty container if there are no chat titles
    }
    return DropdownButton<int>(
      dropdownColor: Colors.grey[900],
      value: selectedConversationIndex < _chatProvider.chatTitles.length
          ? selectedConversationIndex
          : 0, // Ensure the selected index is valid
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      onChanged: (int? newValue) {
        if (newValue != null && newValue < _chatProvider.chatTitles.length) {
          setState(() {
            selectedConversationIndex = newValue;
            _scrollToBottom();
          });
        }
      },
      items: List.generate(_chatProvider.chatTitles.length, (index) {
        return DropdownMenuItem<int>(
          value: index,
          child: Text(_chatProvider.chatTitles[index],
              style: TextStyle(color: Colors.white)),
        );
      }),
    );
  }

  Widget _buildChatList() {
    if (_chatProvider.conversations.isEmpty) {
      return Container(); // Return an empty container when there are no chats
    }
    if (_chatProvider.conversations[selectedConversationIndex].isEmpty) {
      return Center(child: Text('No messages in this chat yet.'));
    }
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(8),
      itemCount: _chatProvider.conversations[selectedConversationIndex].length,
      itemBuilder: (context, index) {
        return _buildMessage(
            _chatProvider.conversations[selectedConversationIndex][index]);
      },
    );
  }

  Widget _buildInputArea() {
    if (_chatProvider.conversations.isEmpty) {
      return Container(); // Hide input area when there are no chats
    }
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
            icon: Icon(Icons.mic,
                color: _isListening ? Colors.red : Colors.white),
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
          conversations: _chatProvider.chatTitles,
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

  Widget body;
    body = isWeb ? _buildWebLayout() : _buildMobileLayout();

  return Scaffold(
    appBar: isWeb 
      ? null
      : AppBar(
          title: Text('Chatbot', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900],
          actions: _chatProvider.conversations.isEmpty ? [] : [_buildDropdown()],
        ),
    body: body,
    resizeToAvoidBottomInset: true,
  );
}
}
