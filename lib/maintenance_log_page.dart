import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
      'technicianOptions': ['Unassigned', 'Ethan R., Manager', 'Michael S., Technician', 'Any Available'],
      'dateOpened': '16-04-2025',
      'ticketId': 'CTH178',
    },
    {
      'symptom': 'Electrical Shortage',
      'classification': 'Electrical',
      'location': 'TUWien',
      'status': 'Resolved',
      'technician': 'Mark G.',
      'dateOpened': '04-04-2025',
      'ticketId': 'CTH179',
    },
    {
      'symptom': 'AC Malfunction',
      'classification': 'HVAC',
      'location': 'Hofburg',
      'status': 'In Progress',
      'technician': 'Sarah L.',
      'dateOpened': '10-04-2025',
      'ticketId': 'CTH180',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance Log',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildFilterBar(),
            SizedBox(height: 16),
            _buildSearchBar(),
            SizedBox(height: 16),
            _buildTableHeader(),
            Expanded(
              child: _buildTable(),
            ),
            _buildCreateNewTaskButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        _buildFilterDropdown('Classification', classifications, selectedClassification, (value) {
          setState(() => selectedClassification = value!);
        }),
        SizedBox(width: 16),
        _buildFilterDropdown('Status', statuses, selectedStatus, (value) {
          setState(() => selectedStatus = value!);
        }),
        SizedBox(width: 16),
        _buildFilterDropdown('Location', locations, selectedLocation, (value) {
          setState(() => selectedLocation = value!);
        }),
        SizedBox(width: 16),
        _buildSortByDropdown(),
      ],
    );
  }

  Widget _buildFilterDropdown(String label, List<String> items, String value, void Function(String?) onChanged) {
    return DropdownButton<String>(
      value: value,
      onChanged: onChanged,
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildSortByDropdown() {
    return Row(
      children: [
        Text('Sort By:'),
        SizedBox(width: 8),
        DropdownButton<String>(
          value: sortBy,
          onChanged: (String? newValue) {
            setState(() {
              if (sortBy == newValue) {
                sortAscending = !sortAscending;
              } else {
                sortBy = newValue!;
                sortAscending = true;
              }
            });
          },
          items: <String>['Date Opened', 'Status']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        IconButton(
          icon: Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
          onPressed: () {
            setState(() {
              sortAscending = !sortAscending;
            });
          },
        ),
      ],
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
      ),
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Symptom? Detection', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Technician', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Date Opened', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Ticket ID', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return ListView.builder(
      itemCount: filteredAndSortedData.length,
      itemBuilder: (context, index) => _buildTableRow(filteredAndSortedData[index]),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['symptom'], style: TextStyle(fontWeight: FontWeight.bold)),
                if (data['subSymptoms'] != null)
                  ...data['subSymptoms'].map<Widget>((subSymptom) {
                    return Text('${subSymptom['name']} ${subSymptom['percentage']}%');
                  }).toList(),
              ],
            ),
          ),
          Expanded(child: Text(data['location'])),
          Expanded(child: Text(data['status'])),
          Expanded(
            child: data['technicianOptions'] != null
                ? DropdownButton<String>(
                    value: data['technician'],
                    items: data['technicianOptions'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        data['technician'] = newValue!;
                      });
                    },
                  )
                : Text(data['technician']),
          ),
          Expanded(child: Text(data['dateOpened'])),
          Expanded(child: Text(data['ticketId'])),
        ],
      ),
    );
  }

  Widget _buildCreateNewTaskButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        child: Text('Create New Task +'),
        onPressed: () {
          // Implement create new task functionality
        },
      ),
    );
  }
}