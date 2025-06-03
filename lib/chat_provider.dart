import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const String BASE_URL = 'http://192.168.204.10:5000';

class ChatProvider extends ChangeNotifier {
  List<String> chatTitles = [];
  List<List<Map<String, String>>> conversations = [];

  bool chatExists(String ticketId) {
    return chatTitles.any((title) => title.startsWith('$ticketId:'));
  }

Future<void> clearChats(String userId) async {
  chatTitles.clear();
  conversations.clear();
  await saveChats(userId);
  notifyListeners();
}
Future<void> loadChats(String userId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  chatTitles = prefs.getStringList('chatTitles_$userId') ?? [];
  String? conversationsJson = prefs.getString('conversations_$userId');
  if (conversationsJson != null) {
    List<dynamic> decodedList = json.decode(conversationsJson);
    conversations = decodedList.map((item) => 
      (item as List).map((conv) => Map<String, String>.from(conv)).toList()
    ).toList();
  } else {
    conversations.clear();
  }
  notifyListeners();
}

Future<void> saveChats(String userId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('chatTitles_$userId', chatTitles);
  await prefs.setString('conversations_$userId', json.encode(conversations));
}

  Future<void> addNewChat(String ticketId, String userRole, String symptom, String userId) async {
    if (chatExists(ticketId)) {
      return;
    }

    chatTitles.add('$ticketId: $symptom');
    List<Map<String, String>> newConversation = [];

    try {
      int n = userRole == 'Energy Expert' ? 1 : 2;

      ticketId = ticketId.replaceAll(RegExp(r'[^0-9]'), '');
      
      final response = await http.post(
        Uri.parse('$BASE_URL/initial_chat'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'ticketId': ticketId,
          'user_id': n,
        }),
      );
      print('Sending request to: $BASE_URL/initial');
      print('Request user: $n');

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String initialMessage = responseData['message'];
        newConversation.add({'sender': 'bot', 'text': initialMessage});
      } else {
        newConversation.add({
          'sender': 'bot',
          'text': 'Chat boot failed'
        });
      }
    } catch (e) {
      newConversation.add({
        'sender': 'bot',
        'text': 'Chat boot failed'
      });
    }

    conversations.add(newConversation);
    await saveChats(userId);
    notifyListeners();
  }

  void removeResolvedChat(String ticketId,String userId) {
    int index = chatTitles.indexWhere((title) => title.startsWith('$ticketId:'));
    if (index != -1) {
      chatTitles.removeAt(index);
      conversations.removeAt(index);
      saveChats(userId);
      notifyListeners();
    } 
  }

  Future<void> addMessage(int conversationIndex, Map<String, String> message, String userId) async {
    if (conversationIndex < conversations.length) {
      conversations[conversationIndex].add(message);
      await saveChats(userId);
      notifyListeners();
    }
  }

  Future<void> initializeChatsFromFirestore(String userRole, String userId) async {
    if (chatTitles.isEmpty) {
      QuerySnapshot snapshot;

      if (userRole == 'Energy Expert') {
        snapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedBy', isEqualTo: 'Unassigned')
            .get();
      } else if (userRole == 'Maintenance Technician') {
        snapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .where('status', isNotEqualTo: 'Resolved')
            .where('assignedTo', isEqualTo: userId)
            .get();
      } else {
        return;
      }

      for (var doc in snapshot.docs) {
        String ticketId = doc['ticketId'];
        String symptom = doc['symptom'];
        await addNewChat(ticketId, userRole, symptom, userId);
      }

      await saveChats(userId);
    }
    notifyListeners();
  }
}