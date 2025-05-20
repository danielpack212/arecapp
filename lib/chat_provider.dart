import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String BASE_URL = 'http://192.168.204.45:5000/';

class ChatProvider extends ChangeNotifier {
  List<String> chatTitles = [];
  List<List<Map<String, String>>> conversations = [];

bool chatExists(String symptom) {
  return chatTitles.any((title) => title.endsWith('$symptom'));
}


Future<void> addNewChat(String ticketId, String symptom) async {
  // Prevent duplicates here too
  if (chatExists(symptom)) return;

  chatTitles.add('$symptom');
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
    int index = chatTitles.indexWhere((title) => title.contains(ticketId));
    if (index != -1) {
      chatTitles.removeAt(index);
      conversations.removeAt(index);
      notifyListeners();
    }
  }
}
