import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

const String BASE_URL = 'http://192.168.204.10:5000';

class ChatProvider extends ChangeNotifier {
  List<String> chatTitles = [];
  List<List<Map<String, String>>> conversations = [];

  bool chatExists(String ticketId) {
    return chatTitles.any((title) => title.startsWith('$ticketId:'));
  }

  Future<void> addNewChat(String ticketId, String symptom) async {
    if (chatExists(ticketId)) return;

    chatTitles.add('$ticketId: $symptom');
    List<Map<String, String>> newConversation = [];

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/initial_chat'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'ticketId': ticketId,
          'symptom': symptom,
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String initialMessage = responseData['message'];
        newConversation.add({'sender': 'bot', 'text': initialMessage});
      } else {
        newConversation.add({
          'sender': 'bot',
          'text':
              'Welcome to the chat for Task #$ticketId. How can I assist you with the $symptom issue?'
        });
      }
    } catch (e) {
      newConversation.add({
        'sender': 'bot',
        'text':
            'Welcome to the chat for Task #$ticketId. How can I assist you with the $symptom issue?'
      });
    }

    conversations.add(newConversation);
    notifyListeners();
  }

  void removeResolvedChat(String ticketId) {
    int index = chatTitles.indexWhere((title) => title.startsWith('$ticketId:'));
    if (index != -1) {
      chatTitles.removeAt(index);
      conversations.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> initializeChatsFromFirestore() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isNotEqualTo: 'Resolved')
        .get();

    for (var doc in snapshot.docs) {
      String ticketId = doc['ticketId'];
      String symptom = doc['symptom'];
      await addNewChat(ticketId, symptom);
    }
  }
}