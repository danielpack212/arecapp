import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart'; // Make sure you've created this file
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notification_service.dart';
import 'chat_provider.dart';
import 'dart:async';

class MaintenanceLogPage extends StatefulWidget {
  @override
  _MaintenanceLogPageState createState() => _MaintenanceLogPageState();
}

class _MaintenanceLogPageState extends State<MaintenanceLogPage> {
  String searchQuery = '';
  List<String> classifications = ['All', 'Plumbing', 'Electrical', 'HVAC'];
  List<String> statuses = ['All', 'Action Required', 'Assigned'];
  List<String> locations = ['All', 'Hofburg', 'TUWien'];
  String selectedClassification = 'All';
  String selectedStatus = 'All';
  String selectedLocation = 'All';
  String sortBy = 'Date Opened';
  bool sortAscending = true;

  List<Map<String, dynamic>> dummyData = [
    {
      'symptom': 'Pipe Burst',
      'classification': 'Plumbing',
      'subSymptoms': [
        {'name': 'Excess Consumption', 'percentage': 20},
        {'name': 'Loose Fittings', 'percentage': 8},
      ],
      'location': 'Hofburg',
      'status': 'Action Required',
      'technician': 'Unassigned',
      'technicianOptions': [
        'Ethan R., Manager',
        'Michael S., Technician',
        'Any Available'
      ],
      'dateOpened': '16-04-2025',
      'ticketId': 'CTH178',
      'isExpanded': false,
    },
    {
      'symptom': 'Electrical Shortage',
      'classification': 'Electrical',
      'subSymptoms': [
        {'name': 'Overloaded Circuit', 'percentage': 30},
        {'name': 'Faulty Wiring', 'percentage': 15},
      ],
      'location': 'TUWien',
      'status': 'Resolved',
      'technician': 'Mark G.',
      'technicianOptions': [
        'Mark G.',
        'Sarah L., Electrician',
        'Any Available'
      ],
      'dateOpened': '04-04-2025',
      'ticketId': 'CTH179',
      'isExpanded': false,
    },
    {
      'symptom': 'AC Malfunction',
      'classification': 'HVAC',
      'subSymptoms': [
        {'name': 'Insufficient Cooling', 'percentage': 40},
        {'name': 'Strange Noise', 'percentage': 10},
      ],
      'location': 'Hofburg',
      'status': 'In Progress',
      'assignedBy': 'Alice Johnson (Energy Expert)',
      'technicianOptions': ['Bob K., HVAC Specialist', 'Any Available'],
      'dateOpened': '10-04-2025',
      'ticketId': 'CTH180',
      'isExpanded': false,
    },
    {
      'symptom': 'Lighting Failure',
      'classification': 'Electrical',
      'subSymptoms': [
        {'name': 'Flickering Lights', 'percentage': 25},
        {'name': 'Dead Bulbs', 'percentage': 75},
      ],
      'location': 'TUWien',
      'status': 'Action Required',
      'assignedBy': 'Unassigned',
      'technicianOptions': [
        'Sarah L., Electrician',
        'Mark G.',
        'Any Available'
      ],
      'dateOpened': '12-04-2025',
      'ticketId': 'CTH181',
      'isExpanded': false,
    },
    {
      'symptom': 'Water Heater Leak',
      'classification': 'Plumbing',
      'subSymptoms': [
        {'name': 'Puddle Formation', 'percentage': 60},
        {'name': 'Reduced Hot Water', 'percentage': 40},
      ],
      'location': 'Hofburg',
      'status': 'In Progress',
      'assignedBy': 'John Doe (Energy Expert)',
      'technicianOptions': [
        'Michael S., Technician',
        'Ethan R., Manager',
        'Any Available'
      ],
      'dateOpened': '14-04-2025',
      'ticketId': 'CTH182',
      'isExpanded': false,
    },
  ];

  void listenForNewTasks() {
    FirebaseFirestore.instance
        .collection('tasks')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var newTask = change.doc.data() as Map<String, dynamic>;
          String ticketId = newTask['ticketId'];
          String symptom = newTask['Symptom'];

          // Check if a chat for this ticket already exists
          if (!Provider.of<ChatProvider>(context, listen: false)
              .chatExists(ticketId)) {
            createNewChatTab(ticketId,symptom);
          }
        }
      }
    });
  }

  late ChatProvider _chatProvider;
  late StreamSubscription<QuerySnapshot> _taskSubscription;

  //initialize tasks in firebase
  @override
  void initState() {
    super.initState();
    initializeFirestoreWithDummyData();
    listenForNewTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _initializeChatsFromFirestore();
    _listenForNewTasks();
  }

  void _initializeChatsFromFirestore() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isEqualTo: 'Action Required')
        .get();

    for (var doc in snapshot.docs) {
      String ticketId = doc.id;
      String symptom = doc['symptom'] ?? 'Unknown issue';
      if (!_chatProvider.chatExists(ticketId)) {
        await _chatProvider.addNewChat(ticketId, symptom);
      }
    }
  }

  void _listenForNewTasks() {
    _taskSubscription = FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isEqualTo: 'Action Required')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          String ticketId = change.doc.id;
          String symptom = change.doc['symptom'] ?? 'Unknown issue';
          if (!_chatProvider.chatExists(ticketId)) {
            _chatProvider.addNewChat(ticketId, symptom);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _taskSubscription.cancel();
    super.dispose();
  }

  Future<bool> tasksExistInFirestore() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('tasks').limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> initializeFirestoreWithDummyData() async {
    bool tasksExist = await tasksExistInFirestore();
    if (!tasksExist) {
      for (var task in dummyData) {
        await addTaskToFirebase(task);
      }
      print('Dummy data added to Firestore');
    } else {
      print('Tasks already exist in Firestore');
    }
  }

  Future<void> addTaskToFirebase(Map<String, dynamic> taskData) async {
    // Remove the 'isExpanded' field as it's not needed in Firestore
    taskData.remove('isExpanded');
    await FirebaseFirestore.instance.collection('tasks').add(taskData);
  }

// NEW filtering and sorting
  Query getFilteredAndSortedQuery() {
    Query query = FirebaseFirestore.instance.collection('tasks');

    // Apply filters
    if (selectedClassification != 'All') {
      query = query.where('classification', isEqualTo: selectedClassification);
    }
    if (selectedStatus != 'All') {
      query = query.where('status', isEqualTo: selectedStatus);
    }
    if (selectedLocation != 'All') {
      query = query.where('location', isEqualTo: selectedLocation);
    }

    return query;
  }

// create new chat
  void createNewChatTab(String ticketId, String Symptom) {
    // You'll need to implement a way to communicate between pages
    // One way is to use a global state management solution like Provider
    Provider.of<ChatProvider>(context, listen: false).addNewChat(ticketId, Symptom);
  }

// close chat
  void checkAndRemoveResolvedChats(List<Map<String, dynamic>> tasks) {
    for (var task in tasks) {
      if (task['status'] == 'Resolved') {
        String ticketId = task['ticketId'];
        Provider.of<ChatProvider>(context, listen: false)
            .removeResolvedChat(ticketId);
      }
    }
  }

// new methods
  void updateFilter(String filterType, String value) {
    setState(() {
      switch (filterType) {
        case 'classification':
          selectedClassification = value;
          break;
        case 'status':
          selectedStatus = value;
          break;
        case 'location':
          selectedLocation = value;
          break;
      }
    });
  }

  void updateSort(String newSortBy) {
    setState(() {
      if (sortBy == newSortBy) {
        sortAscending = !sortAscending;
      } else {
        sortBy = newSortBy;
        sortAscending = true;
      }
    });
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  bool _showMobileFilters = false;
  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<UserProvider>().userRole;

    return Scaffold(
      body: kIsWeb ? _buildWebLayout(userRole) : _buildMobileLayout(userRole),
    );
  }

  Widget _buildWebLayout(String? userRole) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          _buildFilterBar(),
          SizedBox(height: 16),
          _buildTableHeader(userRole),
          Expanded(
            child: _buildRoleBasedContent(userRole),
          ),
          if (userRole == 'Energy Expert') _buildCreateNewTaskButton(context),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(String? userRole) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
                _showMobileFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showMobileFilters = !_showMobileFilters;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          children: [
            if (_showMobileFilters)
              Padding(
                padding: EdgeInsets.all(16.0),
                child: _buildMobileFilterBar(),
              ),
            ..._buildMobileRoleBasedContent(userRole),
          ],
        ),
      ),
      // Remove the floatingActionButton
    );
  }

  Widget _buildMobileHeader(String? userRole) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            userRole == 'Maintenance Technician'
                ? 'Maintenance View'
                : 'Energy Expert View',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(
                _showMobileFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showMobileFilters = !_showMobileFilters;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterBar() {
    return Column(
      children: [
        _buildFilterButton(
            'Classification', classifications, selectedClassification, (value) {
          setState(() => selectedClassification = value!);
        }),
        SizedBox(height: 8),
        _buildFilterButton('Status', statuses, selectedStatus, (value) {
          setState(() => selectedStatus = value!);
        }),
        SizedBox(height: 8),
        _buildFilterButton('Location', locations, selectedLocation, (value) {
          setState(() => selectedLocation = value!);
        }),
        SizedBox(height: 8),
        _buildSortByButton(),
        SizedBox(height: 8),
        _buildSearchBar(),
      ],
    );
  }

  List<Widget> _buildMobileRoleBasedContent(String? userRole) {
    return [
      StreamBuilder<QuerySnapshot>(
        stream: getFilteredAndSortedQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No tasks available'));
          }

          List<Map<String, dynamic>> tasks = snapshot.data!.docs
              .map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              })
              .where((task) =>
                  searchQuery.isEmpty ||
                  (task['symptom'] ?? '')
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()) ||
                  (task['ticketId'] ?? '')
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
              .toList();

          if (userRole == 'Maintenance Technician') {
            String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
            tasks = tasks
                .where((task) => task['assignedTo'] == currentUserUid)
                .toList();
          }

          if (tasks.isEmpty) {
            return Center(child: Text('No tasks match the current filters'));
          }

          return Column(
            children: tasks
                .map((data) => _buildMobileTableRow(data, userRole))
                .toList(),
          );
        },
      ),
    ];
  }

  Widget _buildMobileTable(String? userRole) {
    return StreamBuilder<QuerySnapshot>(
      stream: getFilteredAndSortedQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No tasks available'));
        }

        List<Map<String, dynamic>> tasks = snapshot.data!.docs
            .map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            })
            .where((task) =>
                searchQuery.isEmpty ||
                task['symptom']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                task['ticketId']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
            .toList();

        if (userRole == 'Maintenance Technician') {
          String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
          tasks = tasks
              .where((task) => task['assignedTo'] == currentUserUid)
              .toList();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) =>
              _buildMobileTableRow(tasks[index], userRole),
        );
      },
    );
  }

  Widget _buildMobileTableRow(Map<String, dynamic> data, String? userRole) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(data['symptom'] ?? 'No symptom',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${data['location'] ?? 'No location'} - ${data['status'] ?? 'No status'}'),
        children: [
          ListTile(
              title: Text('Date Opened: ${data['dateOpened'] ?? 'Unknown'}')),
          ListTile(title: Text('Ticket ID: ${data['ticketId'] ?? 'Unknown'}')),
          if (userRole == 'Energy Expert')
            ListTile(
                title: Text(
                    'Assigned To: ${data['assignedToName'] ?? 'Unassigned'}')),
          if (userRole == 'Maintenance Technician')
            FutureBuilder<String>(
              future: _getAssignedByName(data['assignedBy']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(title: CircularProgressIndicator());
                }
                return ListTile(
                    title: Text('Assigned By: ${snapshot.data ?? 'Unknown'}'));
              },
            ),
          if (data['subSymptoms'] != null &&
              (data['subSymptoms'] as List).isNotEmpty)
            ListTile(
              title: Text('Sub-symptoms:'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    (data['subSymptoms'] as List).map<Widget>((subSymptom) {
                  return Text(
                      '${subSymptom['name'] ?? 'Unknown'}: ${subSymptom['percentage'] ?? 'Unknown'}%');
                }).toList(),
              ),
            ),
          if (userRole == 'Energy Expert')
            FutureBuilder<List<String>>(
              future: _fetchTechniciansForBuilding(data['location']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(title: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return ListTile(title: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return ListTile(title: Text('No technicians available'));
                } else {
                  return ListTile(
                    title: Text('Available Technicians:'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          snapshot.data!.map((tech) => Text(tech)).toList(),
                    ),
                  );
                }
              },
            ),
          if (userRole == 'Energy Expert')
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                child: Text('Assign Technician'),
                onPressed: () => _showAssignTechnicianDialog(context, data),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterButton(
                  'Classification', classifications, selectedClassification,
                  (value) {
                setState(() => selectedClassification = value!);
              }),
              _buildFilterButton('Status', statuses, selectedStatus, (value) {
                setState(() => selectedStatus = value!);
              }),
              _buildFilterButton('Location', locations, selectedLocation,
                  (value) {
                setState(() => selectedLocation = value!);
              }),
              _buildSortByButton(),
              ElevatedButton(
                child: Text('Reset Filters'),
                onPressed: () {
                  setState(() {
                    selectedClassification = 'All';
                    selectedStatus = 'All';
                    selectedLocation = 'All';
                  });
                },
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildSearchBar(),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, List<String> items, String value,
      void Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: PopupMenuButton<String>(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value == 'All' ? label : value),
              SizedBox(width: 8),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        onSelected: (String newValue) {
          setState(() {
            switch (label.toLowerCase()) {
              case 'classification':
                selectedClassification = newValue;
                break;
              case 'status':
                selectedStatus = newValue;
                break;
              case 'location':
                selectedLocation = newValue;
                break;
            }
          });
          onChanged(newValue);
        },
        itemBuilder: (BuildContext context) {
          return items.map<PopupMenuItem<String>>((String item) {
            return PopupMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildSortByButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: PopupMenuButton<String>(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sort By: $sortBy'),
              SizedBox(width: 8),
              Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            ],
          ),
        ),
        onSelected: (String newValue) {
          updateSort(newValue);
        },
        itemBuilder: (BuildContext context) {
          return <String>['Date Opened', 'Status']
              .map<PopupMenuItem<String>>((String value) {
            return PopupMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search...',
        suffixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      onChanged: (value) {
        updateSearch(value);
      },
    );
  }

  Widget _buildTableHeader(String? userRole) {
    List<Widget> headerCells = [
      _buildHeaderCell('Symptom Detection', flex: 2),
      _buildHeaderCell('Location'),
      _buildHeaderCell('Status'),
      _buildHeaderCell('Date Opened'),
      _buildHeaderCell('Ticket ID'),
    ];
    if (userRole == 'Energy Expert') {
      headerCells.insert(3, _buildHeaderCell('Assigned To'));
    } else if (userRole == 'Maintenance Technician') {
      headerCells.insert(3, _buildHeaderCell('Assigned By'));
    }
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black),
        ),
      ),
      child: Row(children: headerCells),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRoleBasedContent(String? userRole) {
    return StreamBuilder<QuerySnapshot>(
      stream: getFilteredAndSortedQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No tasks match the current filters.'),
          );
        }

        List<Map<String, dynamic>> tasks = snapshot.data!.docs
            .map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            })
            .where((task) =>
                searchQuery.isEmpty ||
                task['symptom']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                task['ticketId']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
            .toList();

        // Check and remove resolved chats
        checkAndRemoveResolvedChats(tasks);

        if (userRole == 'Maintenance Technician') {
          String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
          tasks = tasks
              .where((task) => task['assignedTo'] == currentUserUid)
              .toList();
        }

        if (tasks.isEmpty) {
          return Center(
            child: Text('No tasks match the current filters.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Expanded(child: _buildTable(userRole, tasks)),
          ],
        );
      },
    );
  }

  Widget _buildTable(String? userRole, List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) =>
          _buildExpandableTableRow(tasks[index], userRole),
    );
  }

  Widget _buildExpandableTableRow(Map<String, dynamic> data, String? userRole) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setStateRow) {
        List<Widget> rowCells = [
          _buildRowCell(
            Row(
              children: [
                Icon(data['isExpanded'] == true
                    ? Icons.arrow_drop_down
                    : Icons.arrow_right),
                Expanded(
                    child: Text(data['symptom'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            flex: 2,
          ),
          _buildRowCell(Text(data['location'] ?? '')),
          _buildRowCell(Text(data['status'] ?? '')),
          _buildRowCell(Text(data['dateOpened'] ?? '')),
          _buildRowCell(Text(data['ticketId'] ?? '')),
        ];

        if (userRole == 'Energy Expert') {
          rowCells.insert(
              3, _buildRowCell(Text(data['assignedToName'] ?? 'Unassigned')));
        } else if (userRole == 'Maintenance Technician') {
          rowCells.insert(
              3,
              _buildRowCell(FutureBuilder<String>(
                future: _getAssignedByName(data['assignedBy']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  return Text(snapshot.data ?? 'Unknown');
                },
              )));
        }

        return Column(
          children: [
            GestureDetector(
              onTap: () {
                setStateRow(() {
                  data['isExpanded'] = !(data['isExpanded'] == true);
                });
              },
              onDoubleTap: () {
                _showDetailPopup(context, data);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(children: rowCells),
              ),
            ),
            if (data['isExpanded'] == true)
              _buildExpandedContent(data, userRole),
          ],
        );
      },
    );
  }

  Future<String> _getAssignedByName(String? uid) async {
    if (uid == null) return 'Unknown';
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.get('name') as String? ?? 'Unknown';
  }

  Widget _buildExpandedContent(Map<String, dynamic> data, String? userRole) {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.grey[100],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(data['symptom'] ?? 'No description available'),
                SizedBox(height: 8),
                if (data['subSymptoms'] != null &&
                    (data['subSymptoms'] as List).isNotEmpty) ...[
                  Text('Sub-symptoms:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...data['subSymptoms'].map<Widget>((subSymptom) {
                    return Text(
                        '${subSymptom['name']}: ${subSymptom['percentage']}%');
                  }).toList(),
                ],
              ],
            ),
          ),
          Expanded(child: SizedBox()), // Empty space for Location
          Expanded(child: SizedBox()), // Empty space for Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    userRole == 'Energy Expert'
                        ? 'Available Technicians:'
                        : 'Assigned By:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (userRole == 'Energy Expert')
                  FutureBuilder<List<String>>(
                    future: _fetchTechniciansForBuilding(data['location']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('No technicians available');
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              snapshot.data!.map((tech) => Text(tech)).toList(),
                        );
                      }
                    },
                  )
                else
                  FutureBuilder<String>(
                    future: _getAssignedByName(data['assignedBy']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      return Text(snapshot.data ?? 'Unknown');
                    },
                  ),
              ],
            ),
          ),
          Expanded(child: SizedBox()), // Empty space for Date Opened
          Expanded(child: SizedBox()), // Empty space for Ticket ID
        ],
      ),
    );
  }

  Widget _buildRowCell(Widget child, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: child,
      ),
    );
  }

  Widget _buildCreateNewTaskButton(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        showCreateTaskDialog(context, context.read<UserProvider>().userRole);
      },
    );
  }

  void showCreateTaskDialog(BuildContext context, String? userRole) {
    String symptom = '';
    String classification = '';
    String location = '';
    String technician = '';
    List<Map<String, dynamic>> subSymptoms = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.9,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Task',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              decoration: _inputDecoration('Symptom'),
                              onChanged: (value) => symptom = value,
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Classification'),
                              value: classification.isEmpty
                                  ? null
                                  : classification,
                              items: ['Plumbing', 'Electrical', 'HVAC']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => classification = value!);
                              },
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Location'),
                              value: location.isEmpty ? null : location,
                              items: ['Hofburg', 'TUWien', 'The Loft']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  location = value!;
                                  technician =
                                      ''; // Reset technician when location changes
                                });
                              },
                            ),
                            SizedBox(height: 16),
                            if (location.isNotEmpty)
                              FutureBuilder<List<String>>(
                                future: _fetchTechniciansForBuilding(location),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Text('No technicians available');
                                  } else {
                                    return DropdownButtonFormField<String>(
                                      decoration:
                                          _inputDecoration('Technician'),
                                      value: technician.isEmpty
                                          ? null
                                          : technician,
                                      items: snapshot.data!.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() => technician = value!);
                                      },
                                    );
                                  }
                                },
                              ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: Text('Cancel',
                              style: TextStyle(color: Colors.red)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          child: Text('Create Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: () {
                            if (symptom.isNotEmpty &&
                                classification.isNotEmpty &&
                                location.isNotEmpty) {
                              _createNewTask(symptom, classification, location,
                                  technician);
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Please fill in all required fields')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[800]),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year}';
  }

  void _createNewTask(String symptom, String classification, String location,
      String technician) async {
    try {
      String? technicianUid;
      if (technician.isNotEmpty) {
        QuerySnapshot technicianSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: technician)
            .limit(1)
            .get();
        if (technicianSnapshot.docs.isNotEmpty) {
          technicianUid = technicianSnapshot.docs.first.id;
        }
      }

      // Generate a unique ticketId
      String ticketId =
          'CTH' + DateTime.now().millisecondsSinceEpoch.toString().substring(7);

      // Add the task to Firestore
      DocumentReference docRef =
          await FirebaseFirestore.instance.collection('tasks').add({
        'symptom': symptom,
        'classification': classification,
        'location': location,
        'status': technicianUid != null ? 'Assigned' : 'Action Required',
        'assignedTo': technicianUid,
        'assignedToName': technicianUid != null ? technician : null,
        'assignedBy': technicianUid != null
            ? FirebaseAuth.instance.currentUser!.uid
            : null,
        'dateOpened': _formatDate(DateTime.now()),
        'ticketId': ticketId,
        'subSymptoms': [],
      });

      // Create a new chat for this task
      Provider.of<ChatProvider>(context, listen: false).addNewChat(ticketId,symptom);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New task created successfully')),
      );

      // Optionally, you can update the document with its Firestore-generated ID
      await docRef.update({'id': docRef.id});
    } catch (e) {
      print('Error creating new task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create new task')),
      );
    }
  }

  Future<Map<String, dynamic>?> _addSubSymptom(BuildContext context) async {
    String name = '';
    int percentage = 0;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Sub-symptom'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Percentage'),
                keyboardType: TextInputType.number,
                onChanged: (value) => percentage = int.tryParse(value) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () {
                Navigator.of(context)
                    .pop({'name': name, 'percentage': percentage});
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _getTechnicianName(String? userRole) async {
    if (userRole == 'Maintenance Technician') {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          return userData['name'] ?? '';
        }
      }
    }
    return '';
  }

  void _showDetailPopup(BuildContext context, Map<String, dynamic> data) {
    final userRole = context.read<UserProvider>().userRole;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${data['symptom']}',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text('${data['location']}',
                          style: TextStyle(color: Colors.black)),
                    ),
                    Expanded(
                      child: Text('Status: ${data['status']}',
                          style: TextStyle(color: Colors.black)),
                    ),
                    Expanded(
                      child: Text('Ticket #${data['ticketId']}',
                          style: TextStyle(color: Colors.black)),
                    ),
                    Expanded(
                      child: Text('Opened ${data['dateOpened']}',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection(
                            'Classification', [data['classification'] ?? 'N/A'],
                            isWide: true),
                        SizedBox(height: 16),
                        if (data['description'] != null &&
                            data['description'].isNotEmpty)
                          _buildDetailSection(
                              'Description', [data['description']],
                              isWide: true),
                        SizedBox(height: 16),
                        if (data['subSymptoms'] != null &&
                            (data['subSymptoms'] as List).isNotEmpty)
                          _buildDetailSection(
                              'Sub-symptoms',
                              (data['subSymptoms'] as List)
                                  .map<String>((subSymptom) =>
                                      '${subSymptom['name']}: ${subSymptom['percentage']}%')
                                  .toList(),
                              isWide: true),
                        SizedBox(height: 16),
                        _buildDetailSection('Assigned To',
                            [data['assignedToName'] ?? 'Unassigned'],
                            isWide: true),
                        SizedBox(height: 16),
                        FutureBuilder<List<String>>(
                          future:
                              _fetchTechniciansForBuilding(data['location']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Text('No technicians available');
                            } else {
                              return _buildDetailSection(
                                  'Available Technicians', snapshot.data!,
                                  isWide: true);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (userRole == 'Energy Expert')
                      ElevatedButton(
                        child: Text('Assign Technician'),
                        onPressed: () =>
                            _showAssignTechnicianDialog(context, data),
                      ),
                    ElevatedButton(
                      child: Text('Close Ticket Summary'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<String> items,
      {bool isWide = false}) {
    return Container(
      width: isWide ? double.infinity : null,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          ...items
              .map((item) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      item,
                      style: TextStyle(color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Future<List<String>> _fetchTechniciansForBuilding(String building) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Maintenance Technician')
        .where('building', isEqualTo: building)
        .get();
    return snapshot.docs.map((doc) => doc.get('name') as String).toList();
  }

  void _showAssignTechnicianDialog(
      BuildContext context, Map<String, dynamic> data) async {
    List<String> technicians =
        await _fetchTechniciansForBuilding(data['location']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Assign Technician'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                ListTile(
                  title: Text('Unassign'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showConfirmationDialog(context, data, null);
                  },
                ),
                ...technicians.isEmpty
                    ? [ListTile(title: Text('No available technicians'))]
                    : technicians.map((String technician) {
                        return ListTile(
                          title: Text(technician),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showConfirmationDialog(context, data, technician);
                          },
                        );
                      }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, Map<String, dynamic> data,
      String? selectedTechnician) {
    String message = selectedTechnician == null
        ? 'Are you sure you want to unassign this task?'
        : 'Are you sure you want to assign $selectedTechnician to this task?';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(selectedTechnician == null
              ? 'Confirm Unassignment'
              : 'Confirm Technician Assignment'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                _assignTechnician(data, selectedTechnician);
              },
            ),
          ],
        );
      },
    );
  }

Future<void> _assignTechnician(Map<String, dynamic> data, String? selectedTechnician) async {
  try {
    // Start a batch write
    WriteBatch batch = FirebaseFirestore.instance.batch();
    
    DocumentReference taskRef = FirebaseFirestore.instance.collection('tasks').doc(data['id']);

    Map<String, dynamic> updateData;
    String? technicianUid;

    if (selectedTechnician == null) {
      // Unassign the task
      updateData = {
        'status': 'Action Required',
        'assignedTo': null,
        'assignedToName': null,
        'assignedBy': null,
      };
    } else {
      // Fetch technician data (consider caching this data if it's accessed frequently)
      QuerySnapshot technicianSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: selectedTechnician)
          .limit(1)
          .get();

      if (technicianSnapshot.docs.isEmpty) {
        throw Exception('Technician not found');
      }

      technicianUid = technicianSnapshot.docs.first.id;

      updateData = {
        'status': 'Assigned',
        'assignedTo': technicianUid,
        'assignedToName': selectedTechnician,
        'assignedBy': FirebaseAuth.instance.currentUser!.uid,
      };
    }

    // Add task update to batch
    batch.update(taskRef, updateData);

    // Commit the batch
    await batch.commit();

    // If a technician was assigned, send a notification
    if (technicianUid != null) {
      // Use a separate async call for notification to not block the UI
      _sendNotificationToTechnician(technicianUid, data['ticketId'], data['symptom']);
    }

    // Update UI
    if (mounted) {
      setState(() {
        // Update your local state here if necessary
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(selectedTechnician == null
            ? 'Task unassigned'
            : 'Task assigned to $selectedTechnician')),
      );
    }
  } catch (e) {
    print('Error assigning/unassigning technician: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign/unassign technician')),
      );
    }
  }
}

// Separate method for sending notification
Future<void> _sendNotificationToTechnician(String technicianUid, String ticketId, String symptom) async {
  try {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    bool notificationSent = await notificationService.sendTaskAssignmentNotification(
      technicianUid,
      ticketId,
      symptom,
    );

    if (!notificationSent) {
      print('Failed to send task assignment notification');
    }
  } catch (e) {
    print('Error sending notification: $e');
  }
}
}
