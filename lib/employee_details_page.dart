import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';

class EmployeeDetailsPage extends StatefulWidget {
  final Map<String, dynamic> employee;
  final bool isAdmin;

  EmployeeDetailsPage({required this.employee, this.isAdmin = true});

  @override
  _EmployeeDetailsPageState createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> {
  List<Map<String, dynamic>> attendanceRecords = [];
  bool isLoading = true;
  int presentDays = 0;
  int totalWorkingDays = 0;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/attendance/${widget.employee['emp_id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> records = 
            List<Map<String, dynamic>>.from(data['records']);
        
        // Filter for current month only
        final now = DateTime.now();
        final currentMonth = now.month;
        final currentYear = now.year;
        
        records = records.where((record) {
          try {
            final date = DateTime.parse(record['date']);
            return date.month == currentMonth && date.year == currentYear;
          } catch (e) {
            return false;
          }
        }).toList();

        // Calculate working hours and attendance status
        for (var record in records) {
          record['working_hours'] = _calculateWorkingHours(
            record['check_in'] ?? '', 
            record['check_out'] ?? ''
          );
          record['is_present'] = _isPresent(
            record['check_in'] ?? '', 
            record['check_out'] ?? ''
          );
        }

        // Count present days (excluding Mondays)
        presentDays = 0;
        totalWorkingDays = 0;
        
        for (var record in records) {
          try {
            final date = DateTime.parse(record['date']);
            if (date.weekday != DateTime.monday) { // Exclude Mondays
              totalWorkingDays++;
              if (record['is_present']) {
                presentDays++;
              }
            }
          } catch (e) {
            // Skip invalid dates
          }
        }

        setState(() {
          attendanceRecords = records;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching attendance data: $e')),
      );
    }
  }

  String _calculateWorkingHours(String checkIn, String checkOut) {
    if (checkIn.isEmpty || checkOut.isEmpty) return '0h 0m';
    
    try {
      final checkInTime = DateTime.parse('2024-01-01 $checkIn');
      final checkOutTime = DateTime.parse('2024-01-01 $checkOut');
      final difference = checkOutTime.difference(checkInTime);
      
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      
      return '${hours}h ${minutes}m';
    } catch (e) {
      return '0h 0m';
    }
  }

  bool _isPresent(String checkIn, String checkOut) {
    if (checkIn.isEmpty || checkOut.isEmpty) return false;
    
    try {
      final checkInTime = DateTime.parse('2024-01-01 $checkIn');
      final checkOutTime = DateTime.parse('2024-01-01 $checkOut');
      final difference = checkOutTime.difference(checkInTime);
      
      return difference.inHours >= 9;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.employee['name']} Details'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Employee Info Card
                Card(
                  margin: EdgeInsets.all(16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.teal,
                              child: Text(
                                widget.employee['name'][0],
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.employee['name'],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.employee['email'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'ID: ${widget.employee['emp_id']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$presentDays',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text('Present Days'),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '${totalWorkingDays - presentDays}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text('Absent Days'),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '$totalWorkingDays',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text('Working Days'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Attendance Records
                Expanded(
                  child: attendanceRecords.isEmpty
                      ? Center(child: Text('No attendance records found'))
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: attendanceRecords.length,
                          itemBuilder: (context, index) {
                            final record = attendanceRecords[index];
                            final isPresent = record['is_present'] ?? false;
                            final workingHours = record['working_hours'] ?? '0h 0m';
                            
                            // Check if it's Monday (week off)
                            bool isMonday = false;
                            try {
                              final date = DateTime.parse(record['date']);
                              isMonday = date.weekday == DateTime.monday;
                            } catch (e) {
                              // Skip invalid dates
                            }
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              color: isMonday 
                                  ? Colors.grey[200] 
                                  : (isPresent ? Colors.green[50] : Colors.red[50]),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isMonday 
                                        ? Colors.grey 
                                        : (isPresent ? Colors.green : Colors.red),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    isMonday 
                                        ? Icons.weekend 
                                        : (isPresent ? Icons.check : Icons.close),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  record['date'] ?? 'N/A',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMonday) ...[
                                      Text('Check-in: ${record['check_in'] ?? 'N/A'}'),
                                      Text('Check-out: ${record['check_out'] ?? 'N/A'}'),
                                      Text('Working Hours: $workingHours'),
                                      if (widget.isAdmin) ...[
                                        Text('IP: ${record['ip_address'] ?? 'N/A'}'),
                                        Text('Location: ${record['location'] ?? 'N/A'}'),
                                      ],
                                    ] else ...[
                                      Text('Week Off (Monday)'),
                                    ],
                                  ],
                                ),
                                trailing: isMonday 
                                    ? Icon(Icons.weekend, color: Colors.grey)
                                    : Icon(
                                        isPresent ? Icons.check_circle : Icons.cancel,
                                        color: isPresent ? Colors.green : Colors.red,
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
