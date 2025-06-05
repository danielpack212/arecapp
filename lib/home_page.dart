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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

const String BASE_URL = 'http://192.168.1.10:5000';
String userRole = 'm';
int n = 0;

class ChatbotPage extends StatefulWidget {
  final String? initialTicketId;
  const ChatbotPage({Key? key, this.initialTicketId}) : super(key: key);

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  static bool _hasInitialized = false; // Add this line

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  late ChatProvider _chatProvider;
  int selectedConversationIndex = 0;
  bool _isListening = false;
  String _speechText = '';
  final stt.SpeechToText _speech = stt.SpeechToText();

  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (!_hasInitialized) {
      _initializationFuture = _initializeOnce();
      _hasInitialized = true;
    } else {
      _initializationFuture = Future.value(); // Already initialized
    }
  }

  Future<void> _initializeOnce() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await _initializeUserAndChats(userProvider);
    _setupFirebaseListener(userProvider.userId);
  }

  Future<void> _initializeUserAndChats(UserProvider userProvider) async {
    try {
      await userProvider.ensureUserRoleLoaded();
      await userProvider.fetchUserRole();
      print('initializeuserandchats');
      print(userProvider.userRole);
      if (userProvider.userRole.isEmpty) {
        print('No user role');
        // Handle this case, maybe set a default role or show an error message
      }

      await _chatProvider.loadChats(userProvider.userId);

      if (_chatProvider.conversations.isEmpty) {
        await _chatProvider.initializeChatsFromFirestore(
            userProvider.userRole, userProvider.userId);
      }

      userRole = userProvider.userRole;
    } catch (e) {
      print('Error initializing user and chats: $e');
      // You might want to rethrow the error or handle it in some way
    }
  }

  void _setupFirebaseListener(String userId) {
    FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          String ticketId = change.doc['ticketId'];
          String symptom = change.doc['symptom'];
          String status = change.doc['status'];
          if (status != 'Resolved' && !_chatProvider.chatExists(ticketId)) {
            _chatProvider.addNewChat(ticketId, userRole, symptom, userId);
          }
        }
      }
    });
  }

  bool isWebPlatform() => kIsWeb;

  Future<void> _sendMessage(String message, {int? conversationIndex}) async {
    int safeIndex = conversationIndex ?? selectedConversationIndex;

    // Trim whitespace from the beginning and end, but preserve newlines within the message
    String trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;

    // Add user message
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await _chatProvider.addMessage(
        safeIndex, {'sender': 'user', 'text': message}, userProvider.userId);

    _controller.clear();
    _scrollToBottom(conversationIndex: safeIndex);

    try {
      String ticketId =
          _chatProvider.chatTitles[safeIndex].split('#').last.trim();
      ticketId = ticketId.replaceAll(RegExp(r'[^0-9]'), '');
      if (ticketId.isEmpty) throw Exception('Invalid ticketId');

      n = userRole == 'Energy Expert' ? 1 : 2;

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

        // Add bot message
        await _chatProvider.addMessage(
            safeIndex,
            {'sender': 'bot', 'text': responseData['answer']},
            userProvider.userId);

        // Check if the message was 'exit' and handle accordingly
        if (message.toLowerCase() == 'exit') {
          String summary = responseData['summary']; // Capture the summary
          await _resolveChat(ticketId, summary);
          return;
        }
      } else {
        throw Exception(
            'Server responded with status code: ${response.statusCode}. Body: ${response.body}');
      }
    } catch (e) {
      print('Error in _sendMessage: $e');
      await _chatProvider.addMessage(
          safeIndex,
          {'sender': 'bot', 'text': 'Sorry, I encountered an error: $e'},
          userProvider.userId);
    }

    _scrollToBottom(conversationIndex: safeIndex);
    setState(() {}); // Trigger a rebuild of the UI
  }

  Future<void> _resolveChat(String ticketId, String summary) async {
    try {
      if (userRole == 'Maintenance Technician') {
        await _updateFirebaseStatus(ticketId, summary, 2);
      } else {
        await _updateFirebaseStatus(ticketId, summary, 1);
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _chatProvider.removeResolvedChat(ticketId, userProvider.userId);

      // Show a dialog indicating completion
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Chat Resolved"),
            content: Text(
                "This chat has been successfully resolved and the ticket has been updated."),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  setState(() {
                    // Reset the selected conversation index if needed
                    if (_chatProvider.conversations.isEmpty) {
                      selectedConversationIndex = -1;
                    } else {
                      selectedConversationIndex = 0;
                    }
                  });
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error resolving chat: $e');
    }
  }

  Future<void> _updateFirebaseStatus(
      String ticketId, String summary, int user) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .where('ticketId', isEqualTo: ticketId)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          if (user == 1) {
          } else if (user == 2) {
            doc.reference.update({'status': 'Resolved'});
            doc.reference.update({'summary': summary});
          }
        }
      });

      // Also update the user's chats collection
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.userId)
          .collection('chats')
          .where('ticketId', isEqualTo: ticketId)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.update({'status': 'Resolved'});
        }
      });
      print('Updated Firebase status for ticket $ticketId');
    } catch (e) {
      print('Error updating Firebase status: $e');
    }
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
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message['text'] ?? '',
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.black,
          ),
          softWrap: true,
          overflow: TextOverflow.visible,
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
        if (selectedConversationIndex >= chatProvider.conversations.length) {
          selectedConversationIndex = 0;
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 150,
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: Colors.white),
                maxLines: 1, // Set to 1 to prevent multiline input
                keyboardType:
                    TextInputType.text, // Change to single line text input
                textInputAction: TextInputAction.send, // Change to send action
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (value) {
                  _sendMessage(value,
                      conversationIndex: selectedConversationIndex);
                  _controller.clear();
                },
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
            onPressed: () {
              _sendMessage(_controller.text,
                  conversationIndex: selectedConversationIndex);
              _controller.clear();
            },
          ),
        ],
      ),
    );
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          !event.isShiftPressed) {
        // Send the message
        _sendMessage(_controller.text,
            conversationIndex: selectedConversationIndex);

        // Clear the text field
        _controller.clear();

        // Force a rebuild to update the UI
        setState(() {});
      }
    }
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
    return RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: _handleKeyPress,
        child: Scaffold(
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20)),
                          SizedBox(width: 8),
                          Image.asset('assets/logo.png', height: 30),
                        ],
                      ),
                      SizedBox(height: 10), // Space between logo and dropdown
                      // Dropdown
                      if (_chatProvider.conversations.isNotEmpty)
                        _buildDropdown(),
                    ],
                  ),
                  backgroundColor: Colors.grey[900],
                ),
          body: FutureBuilder(
            future: _initializationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return isWebPlatform()
                        ? _buildWebLayout()
                        : _buildMobileLayout();
                  },
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
          resizeToAvoidBottomInset: true,
        ));
  }
}
