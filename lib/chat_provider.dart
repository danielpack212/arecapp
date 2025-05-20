import 'package:flutter/foundation.dart';

class ChatProvider extends ChangeNotifier {
  List<Map<String, String>> chats = []; 
  // Each map contains { 'ticketId': '123', 'symptom': 'Leaking Valve' }

  List<List<Map<String, String>>> conversations = [];

  bool chatExists(String ticketId) {
    return chats.any((chat) => chat['ticketId'] == ticketId);
  }

  void addNewChat(String ticketId, String symptom) {
    chats.add({'ticketId': ticketId, 'symptom': symptom});
    conversations.add([
      {'sender': 'bot', 'text': 'Welcome to the $symptom chat! How can I assist you?'}
    ]);
    notifyListeners();
  }

  void removeResolvedChat(String ticketId) {
    int index = chats.indexWhere((chat) => chat['ticketId'] == ticketId);
    if (index != -1) {
      chats.removeAt(index);
      conversations.removeAt(index);
      notifyListeners();
    }
  }

  List<String> get chatTitles => chats.map((chat) => chat['symptom'] ?? 'Unknown').toList();
}
