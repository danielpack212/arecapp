import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'user_provider.dart';

class MaintenanceLogPage extends StatefulWidget {
  @override
  _MaintenanceLogPageState createState() => _MaintenanceLogPageState();
}

class _MaintenanceLogPageState extends State<MaintenanceLogPage> {
  String searchQuery = '';
  List<String> classifications = ['All', 'Plumbing', 'Electrical', 'HVAC'];
  List<String> statuses = ['All', 'Action Required', 'In Progress', 'Resolved'];
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
      'technicianOptions': ['Ethan R., Manager', 'Michael S., Technician', 'Any Available'],
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
      'technicianOptions': ['Mark G.', 'Sarah L., Electrician', 'Any Available'],
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
    'technicianOptions': ['Sarah L., Electrician', 'Mark G.', 'Any Available'],
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
    'technicianOptions': ['Michael S., Technician', 'Ethan R., Manager', 'Any Available'],
    'dateOpened': '14-04-2025',
    'ticketId': 'CTH182',
    'isExpanded': false,
  },
  ];

  List<Map<String, dynamic>> get filteredAndSortedData {
    return dummyData.where((item) {
      return (selectedClassification == 'All' || item['classification'] == selectedClassification) &&
          (selectedStatus == 'All' || item['status'] == selectedStatus) &&
          (selectedLocation == 'All' || item['location'] == selectedLocation) &&
          (searchQuery.isEmpty ||
              item['symptom'].toLowerCase().contains(searchQuery.toLowerCase()) ||
              item['ticketId'].toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList()
      ..sort((a, b) {
        if (sortBy == 'Date Opened') {
          return sortAscending
              ? a['dateOpened'].compareTo(b['dateOpened'])
              : b['dateOpened'].compareTo(a['dateOpened']);
        } else if (sortBy == 'Status') {
          return sortAscending
              ? a['status'].compareTo(b['status'])
              : b['status'].compareTo(a['status']);
        }
        return 0;
      });
  }
  bool _showMobileFilters = false;
  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<UserProvider>().userRole;

        return Scaffold(
          body: kIsWeb
              ? _buildWebLayout(userRole)
              : _buildMobileLayout(userRole),
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
          _buildCreateNewTaskButton(),
        ],
      ),
    );
  }
  Widget _buildMobileLayout(String? userRole) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userRole == 'Maintenance Technician' ? 'Maintenance View' : 'Energy Expert View'),
        actions: [
          IconButton(
            icon: Icon(_showMobileFilters ? Icons.filter_list_off : Icons.filter_list),
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
          // Implement refresh logic here
          setState(() {
            // Refresh your data
          });
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
      floatingActionButton: _buildCreateNewTaskButton(),
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
            userRole == 'Maintenance Technician' ? 'Maintenance View' : 'Energy Expert View',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(_showMobileFilters ? Icons.filter_list_off : Icons.filter_list),
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
        _buildFilterButton('Classification', classifications, selectedClassification, (value) {
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
  List<Widget> content = [
    ...filteredAndSortedData.map((data) => _buildMobileTableRow(data, userRole)).toList(),
  ];

  if (userRole == 'Energy Expert') {
    content.addAll([
      SizedBox(height: 20),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('Energy Consumption Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      // Add energy consumption analysis widgets here
    ]);
  }

  return content;
}

  Widget _buildMobileTable(String? userRole) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filteredAndSortedData.length,
      itemBuilder: (context, index) => _buildMobileTableRow(filteredAndSortedData[index], userRole),
    );
  }

  Widget _buildMobileTableRow(Map<String, dynamic> data, String? userRole) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(data['symptom'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${data['location']} - ${data['status']}'),
        children: [
          ListTile(title: Text('Date Opened: ${data['dateOpened']}')),
          ListTile(title: Text('Ticket ID: ${data['ticketId']}')),
          if (userRole == 'Energy Expert')
            ListTile(title: Text('Assigned To: ${data['assignedTo'] ?? 'Unassigned'}')),
          if (userRole == 'Maintenance Technician')
            ListTile(title: Text('Assigned By: ${data['assignedBy'] ?? 'Unassigned'}')),
          ListTile(
            title: Text('Sub-symptoms:'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data['subSymptoms'].map<Widget>((subSymptom) {
                return Text('${subSymptom['name']}: ${subSymptom['percentage']}%');
              }).toList(),
            ),
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
              _buildFilterButton('Classification', classifications, selectedClassification, (value) {
                setState(() => selectedClassification = value!);
              }),
              _buildFilterButton('Status', statuses, selectedStatus, (value) {
                setState(() => selectedStatus = value!);
              }),
              _buildFilterButton('Location', locations, selectedLocation, (value) {
                setState(() => selectedLocation = value!);
              }),
              _buildSortByButton(),
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

  Widget _buildFilterButton(String label, List<String> items, String value, void Function(String?) onChanged) {
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
        onSelected: onChanged,
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
        onSelected: (String? newValue) {
          setState(() {
            if (sortBy == newValue) {
              sortAscending = !sortAscending;
            } else {
              sortBy = newValue!;
              sortAscending = true;
            }
          });
        },
        itemBuilder: (BuildContext context) {
          return <String>['Date Opened', 'Status'].map<PopupMenuItem<String>>((String value) {
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
        setState(() {
          searchQuery = value;
        });
      },
    );
  }

  Widget _buildTableHeader(String? userRole) {
        List<Widget> headerCells = [
      _buildHeaderCell('Symptom? Detection', flex: 2),
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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (userRole == 'Maintenance Technician')
        Text('Maintenance Technician View', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      if (userRole == 'Energy Expert')
        Text('Energy Expert View', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SizedBox(height: 10),
      Expanded(child: _buildTable(userRole)),
      if (userRole == 'Energy Expert') ...[
        SizedBox(height: 10),
        Text('Energy Consumption Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        // Add energy consumption analysis widgets here
      ],
    ],
  );
}
  Widget _buildTable(String? userRole) {
    return ListView.builder(
      itemCount: filteredAndSortedData.length,
      itemBuilder: (context, index) => _buildExpandableTableRow(filteredAndSortedData[index], userRole),
    );
  }

  Widget _buildExpandableTableRow(Map<String, dynamic> data, String? userRole) {
        List<Widget> rowCells = [
      _buildRowCell(
        Row(
          children: [
            Icon(data['isExpanded'] ? Icons.arrow_drop_down : Icons.arrow_right),
            Expanded(child: Text(data['symptom'], style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        flex: 2,
      ),
      _buildRowCell(Text(data['location'])),
      _buildRowCell(Text(data['status'])),
      _buildRowCell(Text(data['dateOpened'])),
      _buildRowCell(Text(data['ticketId'])),
    ];

    if (userRole == 'Energy Expert') {
      rowCells.insert(3, _buildRowCell(Text(data['assignedTo'] ?? 'Unassigned')));
    } else if (userRole == 'Maintenance Technician') {
      rowCells.insert(3, _buildRowCell(Text(data['assignedBy'] ?? 'Unassigned')));
    }

    return Column(
      children: [
        GestureDetector(
          onDoubleTap: () {
            _showDetailPopup(context, data);
          },
          child: InkWell(
            onTap: () {
              setState(() {
                data['isExpanded'] = !data['isExpanded'];
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row( children: rowCells),
              ),
            ),
          ),
        if (data['isExpanded'])
        _buildExpandedContent(data, userRole),
      ],
    );
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
              Text('Sub-symptoms:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...data['subSymptoms'].map<Widget>((subSymptom) {
                return Text('${subSymptom['name']}: ${subSymptom['percentage']}%');
              }).toList(),
            ],
          ),
        ),
        Expanded(child: SizedBox()), // Empty space for Location
        Expanded(child: SizedBox()), // Empty space for Status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userRole == 'Energy Expert' ? 'Assigned To:' : 'Assigned By:', 
                   style: TextStyle(fontWeight: FontWeight.bold)),
              Text(userRole == 'Energy Expert' 
                   ? (data['assignedTo'] ?? 'Unassigned')
                   : (data['assignedBy'] ?? 'Unassigned')),
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

Widget _buildCreateNewTaskButton() {
  return FloatingActionButton(
    child: Icon(Icons.add),
    onPressed: () {
      // Implement create new task functionality
    },
  );
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
                  Text(
                    '${data['symptom']}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text('${data['location']}', style: TextStyle(color: Colors.black)),
                  Text('Status: ${data['status']}', style: TextStyle(color: Colors.black)),
                  Text('Ticket #${data['ticketId']}', style: TextStyle(color: Colors.black)),
                  Text('Opened ${data['dateOpened']}', style: TextStyle(color: Colors.black)),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Classification', [data['classification']], isWide: true),
                      SizedBox(height: 16),
                      _buildDetailSection('Sub-symptoms', 
                        data['subSymptoms'].map<String>((subSymptom) => 
                          '${subSymptom['name']}: ${subSymptom['percentage']}%'
                        ).toList(),
                        isWide: true
                      ),
                      SizedBox(height: 16),
                      if (userRole == 'Energy Expert') ...[
                        _buildDetailSection('Energy Impact', [
                          'Estimated energy loss: 150 kWh',
                          'Potential cost increase: \$30 per day',
                          'Recommended action: Prioritize repair to minimize energy waste'
                        ], isWide: true),
                        SizedBox(height: 16),
                        _buildDetailSection('Assigned To', [data['assignedTo'] ?? 'Unassigned'], isWide: true),
                      ] else if (userRole == 'Maintenance Technician') ...[
                        _buildDetailSection('Maintenance Log', [
                          '1. Immediate water shutoff to prevent further damage',
                          '2. Assessment of the extent of water damage',
                          '3. Locating and repairing the burst pipe',
                          '4. Drying and dehumidifying affected areas',
                          '5. Checking for mold growth and treating if necessary',
                          '6. Restoring any damaged structures or furnishings'
                        ], isWide: true),
                        SizedBox(height: 16),
                        _buildDetailSection('Assigned By', [data['assignedBy'] ?? 'Unassigned'], isWide: true),
                      ],
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
                      onPressed: () => _showAssignTechnicianDialog(context, data),
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

  Widget _buildDetailSection(String title, List<String> items, {bool isWide = false}) {
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: TextStyle(color: Colors.black),
              textAlign: TextAlign.center,
            ),
          )).toList(),
        ],
      ),
    );
  }

  void _showAssignTechnicianDialog(BuildContext context, Map<String, dynamic> data) {
    List<String> technicians = List<String>.from(data['technicianOptions'] ?? []);
    if (!technicians.contains('Any Available')) {
      technicians.add('Any Available');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Assign Technician'),
          content: SingleChildScrollView(
            child: ListBody(
              children: technicians.map((String technician) {
                return ListTile(
                  title: Text(technician),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showConfirmationDialog(context, data, technician);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, Map<String, dynamic> data, String selectedTechnician) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Technician Assignment'),
          content: Text('Are you sure you want to assign $selectedTechnician to this task?'),
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
    void _assignTechnician(Map<String, dynamic> data, String selectedTechnician) {
    // Here you would update the data and send it to the database
    // For now, we'll just print the assignment
    print('Assigning $selectedTechnician to task ${data['ticketId']}');
    
    // TODO: Implement database update
    // Example of how you might update the data:
    // data['technician'] = selectedTechnician;
    // DatabaseService().updateMaintenanceTask(data['ticketId'], data);
    
    // For now, let's update the state to reflect the change
    setState(() {
      data['technician'] = selectedTechnician;
    });
  }
}