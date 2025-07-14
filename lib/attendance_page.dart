import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';

class AttendancePage extends StatefulWidget {
  final String empId;
  
  AttendancePage({required this.empId});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<Map<String, dynamic>> attendanceRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/${widget.empId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          attendanceRecords = List<Map<String, dynamic>>.from(data['records']);
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
    try {
      final checkInTime = DateTime.parse(checkIn);
      final checkOutTime = DateTime.parse(checkOut);
      final difference = checkOutTime.difference(checkInTime);
      
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      
      return '${hours}h ${minutes}m';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getAttendanceStatus(String checkIn, String checkOut) {
    if (checkOut.isEmpty) return 'Incomplete';
    
    try {
      final checkInTime = DateTime.parse(checkIn);
      final checkOutTime = DateTime.parse(checkOut);
      final difference = checkOutTime.difference(checkInTime);
      
      return difference.inHours >= 9 ? 'Present' : 'Absent';
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Records'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : attendanceRecords.isEmpty
              ? Center(child: Text('No attendance records found'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: attendanceRecords.length,
                  itemBuilder: (context, index) {
                    final record = attendanceRecords[index];
                    final checkIn = record['check_in'] ?? '';
                    final checkOut = record['check_out'] ?? '';
                    final workingHours = _calculateWorkingHours(checkIn, checkOut);
                    final status = _getAttendanceStatus(checkIn, checkOut);
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  record['date'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'Present' ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.login, size: 16, color: Colors.green),
                                SizedBox(width: 4),
                                Text('Check-in: ${checkIn.isNotEmpty ? checkIn : 'N/A'}'),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.logout, size: 16, color: Colors.red),
                                SizedBox(width: 4),
                                Text('Check-out: ${checkOut.isNotEmpty ? checkOut : 'N/A'}'),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.blue),
                                SizedBox(width: 4),
                                Text('Working Hours: $workingHours'),
                              ],
                            ),
                            if (record['location'] != null) ...[
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text('Location: ${record['location']}'),
                                  ),
                                ],
                              ),
                            ],
                            if (record['ip_address'] != null) ...[
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.computer, size: 16, color: Colors.purple),
                                  SizedBox(width: 4),
                                  Text('IP: ${record['ip_address']}'),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
