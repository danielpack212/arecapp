import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'sidebar.dart';
import 'chat_provider.dart';
import 'package:provider/provider.dart';

const String BASE_URL = 'http://192.168.204.45:5000/'; // Replace with your new IP address

class ChatbotPage extends StatefulWidget {
  final String? ticketId;
  ChatbotPage({this.ticketId});
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


  int selectedConversationIndex = 0;

  bool _isListening = false;
  String _speechText = '';
  stt.SpeechToText _speech = stt.SpeechToText();

  bool isWebPlatform() {
    return kIsWeb;
  }


  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
        if (widget.ticketId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSpecificChat(widget.ticketId!);
      });
    }
  }

  void _openSpecificChat(String ticketId) {
  int index = _chatProvider.chats.indexWhere((chat) => chat['ticketId'] == ticketId);
  if (index != -1) {
    setState(() {
      selectedConversationIndex = index;
    });
    print('Opened chat for ticket: $ticketId');
  } else {
    print('No chat found for ticket: $ticketId');
    // Optionally, you could create a new chat here or show an error message
  }
}

    void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _chatProvider.conversations[selectedConversationIndex].add({'sender': 'user', 'text': message});
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/chat'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'text': message,
          'ticketId': _chatProvider.chats[selectedConversationIndex]['ticketId'] ?? '',
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String botReply = responseData['answer'];

        setState(() {
          _chatProvider.conversations[selectedConversationIndex].add({'sender': 'bot', 'text': botReply});
        });
      } else {
        setState(() {
          _chatProvider.conversations[selectedConversationIndex].add({'sender': 'bot', 'text': 'Failed to get response!'});
        });
      }
    } catch (e) {
      setState(() {
        _chatProvider.conversations[selectedConversationIndex].add({'sender': 'bot', 'text': 'Error: ${e.toString()}'});
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
      value: selectedConversationIndex,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      onChanged: (int? newValue) {
        setState(() {
          selectedConversationIndex = newValue!;
          _scrollToBottom();
        });
      },
      items: List.generate(_chatProvider.chatTitles.length, (index) {
        return DropdownMenuItem<int>(
          value: index,
          child: Text(_chatProvider.chatTitles[index], style: TextStyle(color: Colors.white)),
        );
      }),
    );
  }

Widget _buildChatList() {
  if (_chatProvider.conversations.isEmpty || selectedConversationIndex >= _chatProvider.conversations.length) {
    return Center(child: Text("No conversations available.", style: TextStyle(color: Colors.black)));
  }

  return ListView.builder(
    controller: _scrollController,
    padding: EdgeInsets.all(8),
    itemCount: _chatProvider.conversations[selectedConversationIndex].length,
    itemBuilder: (context, index) {
      return _buildMessage(_chatProvider.conversations[selectedConversationIndex][index]);
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