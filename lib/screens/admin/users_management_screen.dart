import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final int _limit = 20;
  int _currentPage = 1;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRole = 'All';

  List<UserProfile> _users = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final users = await appState.supabaseService.getUsersPaginated(
      _currentPage,
      _limit,
      searchQuery: _searchQuery,
      role: _selectedRole,
    );
    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _loadUsers();
  }

  void _onRoleChanged(String? role) {
    if (role != null) {
      _selectedRole = role;
      _currentPage = 1;
      _loadUsers();
    }
  }

  Future<void> _toggleUserBan(UserProfile user) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final newStatus = !user.isBanned;
    await appState.supabaseService.updateUserBannedStatus(user.uid, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(newStatus ? 'User ${user.displayName} blocked.' : 'User unblocked.'),
      backgroundColor: newStatus ? Colors.red : Colors.green,
    ));
    _loadUsers();
  }

  void _showUserDetails(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(user.displayName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${user.email}'),
              Text('Phone: ${user.phoneNumber}'),
              Text('Role: ${user.role}'),
              Text('Trust Score: ${user.trustScore}'),
              const SizedBox(height: 16),
              Text('Status: ${user.isBanned ? "Blocked" : "Active"}', style: TextStyle(
                color: user.isBanned ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Bar (Search & Filter)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedRole,
                items: ['All', 'Rider', 'Host', 'Admin'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: _onRoleChanged,
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('No users found.'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                            child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
                          ),
                          title: Text(user.displayName),
                          subtitle: Text('${user.email} • Role: ${user.role}'),
                          onTap: () => _showUserDetails(user),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: user.isBanned ? Colors.green : Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _toggleUserBan(user),
                            child: Text(user.isBanned ? 'Unblock' : 'Block'),
                          ),
                        );
                      },
                    ),
        ),

        // Pagination Controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () {
                        _currentPage--;
                        _loadUsers();
                      }
                    : null,
              ),
              Text('Page $_currentPage'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _users.length == _limit
                    ? () {
                        _currentPage++;
                        _loadUsers();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
