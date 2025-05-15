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
            SizedBox(height: 16),
            _buildFilterBar(),
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

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Symptom? Detection', flex: 2),
          _buildHeaderCell('Location'),
          _buildHeaderCell('Status'),
          _buildHeaderCell('Technician'),
          _buildHeaderCell('Date Opened'),
          _buildHeaderCell('Ticket ID'),
        ],
      ),
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

  Widget _buildTable() {
    return ListView.builder(
      itemCount: filteredAndSortedData.length,
      itemBuilder: (context, index) => _buildExpandableTableRow(filteredAndSortedData[index]),
    );
  }

  Widget _buildExpandableTableRow(Map<String, dynamic> data) {
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
              child: Row(
                children: [
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
                  _buildRowCell(
                    Row(
                      children: [
                        Expanded(child: Text(data['technician'])),
                        Icon(data['isExpanded'] ? Icons.arrow_drop_down : Icons.arrow_right),
                      ],
                    ),
                  ),
                  _buildRowCell(Text(data['dateOpened'])),
                  _buildRowCell(Text(data['ticketId'])),
                ],
              ),
            ),
          ),
        ),
        if (data['isExpanded'])
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRowCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sub-symptoms:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...data['subSymptoms'].map<Widget>((subSymptom) {
                        return Text('${subSymptom['name']}: ${subSymptom['percentage']}%');
                      }).toList(),
                    ],
                  ),
                  flex: 2,
                ),
                _buildRowCell(SizedBox()),
                _buildRowCell(SizedBox()),
                _buildRowCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Technician options:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...data['technicianOptions'].map<Widget>((option) {
                        return Text(option);
                      }).toList(),
                    ],
                  ),
                ),
                _buildRowCell(SizedBox()),
                _buildRowCell(SizedBox()),
              ],
            ),
          ),
      ],
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

  void _showDetailPopup(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${data['symptom']}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text('${data['location']}'),
                    Text('Status: ${data['status']}'),
                    Text('Ticket #${data['ticketId']}'),
                    Text('Opened ${data['dateOpened']}'),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildDetailSection('Classifications', [
                          'Plumbing',
                          'Water Damage',
                          'Emergency',
                          'Structural',
                          'Utility',
                        ]),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailSection('Available Technicians', [
                          'Ethan R., Manager',
                          'Michael S., Technician',
                          'Sarah L., Plumber',
                          'John D., Emergency Response',
                          'Any Available',
                        ]),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailSection('Maintenance Log', [
                          'Historically, pipe bursts have been addressed by:',
                          '1. Immediate water shutoff to prevent further damage',
                          '2. Assessment of the extent of water damage',
                          '3. Locating and repairing the burst pipe',
                          '4. Drying and dehumidifying affected areas',
                          '5. Checking for mold growth and treating if necessary',
                          '6. Restoring any damaged structures or furnishings',
                          '',
                          'Average resolution time: 2-5 days depending on severity.',
                          'Common causes: freezing temperatures, age of pipes, high water pressure, or physical damage.',
                        ]),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    child: Text('Close Ticket Summary'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  items[index],
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
