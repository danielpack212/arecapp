import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'sidebar.dart';
import 'chat_provider.dart';
import 'package:provider/provider.dart';

const String BASE_URL = 'http://192.168.204.45:5000/';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  late ChatProvider _chatProvider;
  int selectedConversationIndex = 0;
  bool _isListening = false;
  String _speechText = '';
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _initializeChats();
  }
  Future<void> _initializeChats() async {
    await _chatProvider.initializeChatsFromFirestore();
    setState(() {});
  }
  bool isWebPlatform() => kIsWeb;

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _chatProvider.conversations.isEmpty) return;

    if (_chatProvider.conversations.isEmpty) {
      await _chatProvider.addNewChat('New Chat', 'New Conversation');
      setState(() => selectedConversationIndex = 0);
    }

    if (selectedConversationIndex >= _chatProvider.conversations.length) {
      setState(() => selectedConversationIndex = _chatProvider.conversations.length - 1);
    }

    _addMessage({'sender': 'user', 'text': message});
    _controller.clear();
    _scrollToBottom();

    try {
      String ticketId = _chatProvider.chatTitles[selectedConversationIndex].split('#').last;
      if (ticketId.isEmpty) throw Exception('Invalid ticketId');

      final response = await http.post(
        Uri.parse('$BASE_URL/chat'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'text': message, 'ticketId': ticketId}),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        _addMessage({'sender': 'bot', 'text': responseData['answer']});
      } else {
        throw Exception('Failed to get response from server');
      }
    } catch (e) {
      print('Error in _sendMessage: $e');
      _addMessage({'sender': 'bot', 'text': 'Sorry, I encountered an error. Please try again later.'});
    }

    _scrollToBottom();
  }

  void _addMessage(Map<String, String> message) {
    int index = _chatProvider.conversations[selectedConversationIndex].length;
    _chatProvider.conversations[selectedConversationIndex].add(message);
    _listKey.currentState?.insertItem(index);
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _speechText = '';
        });

        _speech.listen(
          onResult: (result) => setState(() {
            _speechText = result.recognizedWords;
            _controller.text = _speechText;
          }),
        );
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Widget _buildMessage(Map<String, String> message, Animation<double> animation) {
    bool isUser = message['sender'] == 'user';
    return SizeTransition(
      sizeFactor: animation,
      child: Align(
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
      ),
    );
  }

  Widget _buildDropdown() {
    if (_chatProvider.chatTitles.isEmpty) return Container();
    return DropdownButton<int>(
      dropdownColor: Colors.grey[900],
      value: selectedConversationIndex < _chatProvider.chatTitles.length
          ? selectedConversationIndex
          : 0,
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
    if (_chatProvider.conversations.isEmpty ||
        selectedConversationIndex >= _chatProvider.conversations.length) {
      return Center(child: Text("No conversations available.", style: TextStyle(color: Colors.black)));
    }

    return AnimatedList(
      key: _listKey,
      controller: _scrollController,
      initialItemCount: _chatProvider.conversations[selectedConversationIndex].length,
      itemBuilder: (context, index, animation) {
        return _buildMessage(
          _chatProvider.conversations[selectedConversationIndex][index],
          animation,
        );
      },
    );
  }

  Widget _buildInputArea() {
    if (_chatProvider.conversations.isEmpty) return Container();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.grey[900],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: _sendMessage,
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
            icon: Icon(Icons.mic, color: _isListening ? Colors.red : Colors.white),
            onPressed: _isListening ? _stopListening : _startListening,
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
        Expanded(child: _buildChatList()),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        Sidebar(
          conversations: _chatProvider.chatTitles,
          onConversationSelected: (index) => setState(() => selectedConversationIndex = index),
          selectedConversationIndex: selectedConversationIndex,
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildChatList()),
              _buildInputArea(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isWebPlatform()
          ? null
          : AppBar(
              title: Text('Chatbot', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.grey[900],
              actions: _chatProvider.conversations.isEmpty ? [] : [_buildDropdown()],
            ),
      body: isWebPlatform() ? _buildWebLayout() : _buildMobileLayout(),
      resizeToAvoidBottomInset: true,
    );
  }
}