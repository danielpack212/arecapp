import 'package:flutter/material.dart';

class MaintenanceLogPage extends StatefulWidget {
  @override
  _MaintenanceLogPageState createState() => _MaintenanceLogPageState();
}

class _MaintenanceLogPageState extends State<MaintenanceLogPage> {
  String? selectedBuilding;
  List<String> buildings = ['Building 1', 'Building 2', 'Building 3'];

  List<Map<String, String>> maintenanceLogs = [];

  final Map<String, List<Map<String, String>>> maintenanceData = {
    'Building 1': [
      {'date': '2025-04-10', 'issue': 'Leaking pipe', 'status': 'Completed'},
      {'date': '2025-04-12', 'issue': 'AC not working', 'status': 'Pending'},
    ],
    'Building 2': [
      {'date': '2025-04-09', 'issue': 'Broken window', 'status': 'Completed'},
    ],
    'Building 3': [
      {'date': '2025-04-14', 'issue': 'Power outage', 'status': 'In Progress'},
    ],
  };

  void loadMaintenanceLogs(String building) {
    setState(() {
      maintenanceLogs = maintenanceData[building] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFFAFAFA),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButton<String>(
            hint: Text('Select Building'),
            value: selectedBuilding,
            onChanged: (value) {
              setState(() {
                selectedBuilding = value;
                loadMaintenanceLogs(value!);
              });
            },
            items: buildings.map((building) {
              return DropdownMenuItem<String>(
                value: building,
                child: Text(building),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          if (selectedBuilding == null)
            Center(
              child: Text(
                'Please select a building to view maintenance logs.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          if (selectedBuilding != null)
            Expanded(
              child: ListView.builder(
                itemCount: maintenanceLogs.length,
                itemBuilder: (context, index) {
                  var log = maintenanceLogs[index];
                  return Card(
                    color: Colors.white,
                    elevation: 4,
                    margin: EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: ${log['date']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Issue: ${log['issue']}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Status: ${log['status']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: log['status'] == 'Completed'
                                  ? Colors.green
                                  : log['status'] == 'Pending'
                                      ? Colors.orange
                                      : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
