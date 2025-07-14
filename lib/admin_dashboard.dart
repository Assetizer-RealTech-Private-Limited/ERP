import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';
import 'login_page.dart';
import 'employee_details_page.dart';
import 'admin_employees_page.dart';
import 'admin_requests_page.dart';
import 'admin_settings_page.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    fetchEmployees();
    fetchRequests();
  }

  Future<void> fetchEmployees() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/employees'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          employees = List<Map<String, dynamic>>.from(data['employees']);
        });
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }
  }

  Future<void> fetchRequests() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/requests'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          requests = List<Map<String, dynamic>>.from(data['requests']);
        });
      }
    } catch (e) {
      print('Error fetching requests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Color(0xFF8A2BE2),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8A2BE2), // Purple
              Color(0xFFFF6347), // Orange
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF8A2BE2), Color(0xFFFF6347)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'ART',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 50),
            // Navigation Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildNavigationButton(
                    'Employees',
                    Icons.people,
                    Colors.blue,
                    () => _navigateToEmployees(),
                  ),
                  SizedBox(height: 20),
                  _buildNavigationButton(
                    'Requests',
                    Icons.assignment,
                    Colors.orange,
                    () => _navigateToRequests(),
                  ),
                  SizedBox(height: 20),
                  _buildNavigationButton(
                    'Settings',
                    Icons.settings,
                    Colors.grey,
                    () => _navigateToSettings(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEmployees() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEmployeesPage(),
      ),
    );
  }

  void _navigateToRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminRequestsPage(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminSettingsPage(),
      ),
    );
  }

  Widget _buildEmployeesTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(employee['name'][0]),
            ),
            title: Text(employee['name']),
            subtitle: Text(employee['email']),
            trailing: IconButton(
              icon: Icon(Icons.info),
              onPressed: () => _showEmployeeDetails(employee),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${request['type']} Request'),
            subtitle: Text('From: ${request['employee_name']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveRequest(request['id']),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectRequest(request['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person_add),
            title: Text('Add Employee'),
            onTap: () => _showAddEmployeeDialog(),
          ),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text('Remove Employee'),
            onTap: () => _showRemoveEmployeeDialog(),
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Change Password'),
            onTap: () => _showChangePasswordDialog(),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () => _logout(),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailsPage(employee: employee),
      ),
    );
  }

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Employee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addEmployee(nameController.text, emailController.text, passwordController.text);
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: InputDecoration(labelText: 'Old Password'),
              obscureText: true,
            ),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _changePassword(oldPasswordController.text, newPasswordController.text);
              Navigator.pop(context);
            },
            child: Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showRemoveEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Employee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select employee to remove:'),
            SizedBox(height: 10),
            Container(
              height: 200,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final employee = employees[index];
                  if (employee['role'] == 'admin') return Container();
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(employee['name'][0]),
                    ),
                    title: Text(employee['name']),
                    subtitle: Text(employee['email']),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmRemoveEmployee(employee);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveEmployee(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Removal'),
        content: Text('Are you sure you want to remove ${employee['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeEmployee(employee['emp_id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _addEmployee(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_employee'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Employee added successfully')),
        );
        fetchEmployees();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding employee: $e')),
      );
    }
  }

  Future<void> _removeEmployee(String empId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/remove_employee/$empId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Employee removed successfully')),
        );
        fetchEmployees();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing employee: $e')),
      );
    }
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    // Implementation for changing password
  }

  Future<void> _approveRequest(String requestId) async {
    // Implementation for approving request
  }

  Future<void> _rejectRequest(String requestId) async {
    // Implementation for rejecting request
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }
}
