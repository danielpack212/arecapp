import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io' show SocketException;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'sidebar.dart';
import 'chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'user_provider.dart';

const String BASE_URL = 'http://192.168.204.10:5000';
String userRole = 'm';
int n = 0;

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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _initializeUserAndChats(userProvider);
    userRole = userProvider.userRole;
    print(userRole);
  }
  Future<void> _initializeUserAndChats(UserProvider userProvider) async {
    await userProvider.fetchUserRole();
    
    if (userProvider.userRole.isEmpty) {
      // You might want to set a default role here, or handle this case appropriately
    }
    
    await _initializeChats(userProvider.userRole, userProvider.userId);
    userRole = userProvider.userRole;
    
    if (mounted) {
      setState(() {});
    }
  }
  Future<void> _initializeChats(String userRole, String userId) async {
    await _chatProvider.initializeChatsFromFirestore(userRole, userId);
    if (mounted) {
      setState(() {});
    }
  }

  bool isWebPlatform() => kIsWeb;

  Future<void> _sendMessage(String message, {int? conversationIndex}) async {
    // Use null-coalescing operator to ensure conversationIndex is non-null
    int safeIndex = conversationIndex ?? selectedConversationIndex;

    if (message.trim().isEmpty) return;

    setState(() {
      if (_chatProvider.conversations.isEmpty) {
        _chatProvider.conversations.add([]);
        safeIndex = 0;
      }

      // Ensure we're working with the correct conversation
      if (safeIndex >= _chatProvider.conversations.length) {
        safeIndex = _chatProvider.conversations.length - 1;
      }

      // Add the user's message to the specific conversation
      _chatProvider.conversations[safeIndex]
          .add({'sender': 'user', 'text': message});
    });

    _controller.clear();
    _scrollToBottom(conversationIndex: safeIndex);

    try {
      String ticketId =
          _chatProvider.chatTitles[safeIndex].split('#').last.trim();
      ticketId = ticketId.replaceAll(RegExp(r'[^0-9]'), '');
      if (ticketId.isEmpty) throw Exception('Invalid ticketId');
      if (userRole == 'Energy Expert') {
        n = 1;
      } else {
        n = 2;
      }
      final requestBody =
          jsonEncode({'text': message, 'ticketId': ticketId, 'User': n});
      print('Sending request to: $BASE_URL/chat');
      print('Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse('$BASE_URL/chat'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(Duration(seconds: 30));

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        setState(() {
          _chatProvider.conversations[safeIndex]
              .add({'sender': 'bot', 'text': responseData['answer']});
        });
      } else {
        throw Exception(
            'Server responded with status code: ${response.statusCode}. Body: ${response.body}');
      }
    } catch (e) {
      print('Error in _sendMessage: $e');
      setState(() {
        _chatProvider.conversations[safeIndex].add(
            {'sender': 'bot', 'text': 'Sorry, I encountered an error: $e'});
      });
    }

    _scrollToBottom(conversationIndex: safeIndex);
    _chatProvider.notifyListeners();
  }

  void _scrollToBottom({int? conversationIndex}) {
    int safeIndex = conversationIndex ?? selectedConversationIndex;
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

  void _addMessage(Map<String, String> message) {
    int index = _chatProvider.conversations[selectedConversationIndex].length;
    _chatProvider.conversations[selectedConversationIndex].add(message);
    _listKey.currentState?.insertItem(index);
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
        child: MarkdownBody(
          data: message['text'] ?? '',
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: TextStyle(fontSize: 16.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    if (_chatProvider.chatTitles.isEmpty) return Container();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButton<int>(
        dropdownColor: Colors.grey[800],
        value: selectedConversationIndex < _chatProvider.chatTitles.length
            ? selectedConversationIndex
            : 0,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        underline: Container(), // This removes the underline
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
      ),
    );
  }

  Widget _buildChatList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.conversations.isEmpty ||
            selectedConversationIndex >= chatProvider.conversations.length) {
          return Center(
            child: Text("No conversations available.",
                style: TextStyle(color: Colors.black)),
          );
        }

        List<Map<String, String>> currentConversation =
            chatProvider.conversations[selectedConversationIndex];

        return ListView.builder(
          controller: _scrollController,
          itemCount: currentConversation.length,
          itemBuilder: (context, index) {
            return _buildMessage(currentConversation[index]);
          },
        );
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
              onSubmitted: (text) => _sendMessage(text,
                  conversationIndex: selectedConversationIndex),
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
            onPressed: _isListening ? _stopListening : _startListening,
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: () => _sendMessage(_controller.text,
                conversationIndex: selectedConversationIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: _chatProvider.conversations.isEmpty
              ? Center(
                  child: Text("No conversations available.",
                      style: TextStyle(color: Colors.black)))
              : _buildChatList(),
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
          onConversationSelected: (index) =>
              setState(() => selectedConversationIndex = index),
          selectedConversationIndex: selectedConversationIndex,
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _chatProvider.conversations.isEmpty
                    ? Center(
                        child: Text("No conversations available.",
                            style: TextStyle(color: Colors.black)))
                    : _buildChatList(),
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
    return Scaffold(
      appBar: isWebPlatform()
          ? null
          : AppBar(
              toolbarHeight: 100, // Increase the height of the AppBar
              flexibleSpace: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // TuneUp logo and text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('TuneUp',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                      SizedBox(width: 8),
                      Image.asset('assets/logo.png', height: 30),
                    ],
                  ),
                  SizedBox(height: 10), // Space between logo and dropdown
                  // Dropdown
                  if (_chatProvider.conversations.isNotEmpty) _buildDropdown(),
                ],
              ),
              backgroundColor: Colors.grey[900],
            ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return isWebPlatform() ? _buildWebLayout() : _buildMobileLayout();
        },
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
