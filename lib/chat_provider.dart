import 'package:flutter/foundation.dart';

class ChatProvider extends ChangeNotifier {
  List<String> chatTitles = ['Pipe Burst', 'Electrical Shortage', 'Other Issues'];
  List<List<Map<String, String>>> conversations = [
    [{'sender': 'bot', 'text': 'Welcome to the Pipe Burst chat! How can I assist you with this issue?'}],
    [{'sender': 'bot', 'text': 'Welcome to the Electrical Shortage chat! What details can you provide about the problem?'}],
    [{'sender': 'bot', 'text': 'Welcome to the Other Issues chat! Please describe the maintenance problem you\'re facing.'}],
  ];

  bool chatExists(String ticketId) {
    return chatTitles.any((title) => title.contains(ticketId));
  }
  
  void addNewChat(String ticketId) {
    chatTitles.add('Task #$ticketId');
    conversations.add([{'sender': 'bot', 'text': 'Welcome to the chat for Task #$ticketId. How can I assist you?'}]);
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