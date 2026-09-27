import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';

class AdminUsersTab extends StatefulWidget {
  final List<UserProfile> users;
  final Function(UserProfile user) onToggleBan;
  final Function(UserProfile user, String newRole) onChangeRole;
  final Function(UserProfile user, double newTrustScore) onUpdateTrustScore;

  const AdminUsersTab({
    super.key,
    required this.users,
    required this.onToggleBan,
    required this.onChangeRole,
    required this.onUpdateTrustScore,
  });

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';

  List<UserProfile> get _filteredUsers {
    return widget.users.where((user) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phoneNumber.toLowerCase().contains(query) ||
          user.uid.toLowerCase().contains(query);

      final matchesRole = _selectedRoleFilter == 'All' ||
          user.role.toLowerCase() == _selectedRoleFilter.toLowerCase();

      final matchesStatus = _selectedStatusFilter == 'All' ||
          (_selectedStatusFilter == 'Active' && !user.isBanned) ||
          (_selectedStatusFilter == 'Banned' && user.isBanned);

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  void _showRoleDialog(UserProfile user) {
    String selectedRole = user.role;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Change Role: ${user.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select account privilege role:'),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: selectedRole,
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedRole = val);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final role in ['Rider', 'Host', 'Admin'])
                      RadioListTile<String>(
                        title: Text(role),
                        subtitle: Text(
                          role == 'Admin'
                              ? 'Full platform management access'
                              : (role == 'Host' ? 'Can list vehicles & manage fleet' : 'Can book rides and rent vehicles'),
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: role,
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onChangeRole(user, selectedRole);
              },
              child: const Text('Apply Role'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrustScoreDialog(UserProfile user) {
    double currentScore = user.trustScore;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Kinetic Trust Score: ${user.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Score: ${currentScore.toStringAsFixed(1)} / 100.0',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Slider(
                value: currentScore,
                min: 0.0,
                max: 100.0,
                divisions: 100,
                label: currentScore.toStringAsFixed(1),
                onChanged: (val) {
                  setDialogState(() => currentScore = val);
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Adjusting trust score modifies the user deposit waiver and verification limits.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onUpdateTrustScore(user, currentScore);
              },
              child: const Text('Save Score'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailsDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
              child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(user.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('User ID', user.uid),
            _buildDetailRow('Phone', user.phoneNumber.isNotEmpty ? user.phoneNumber : 'Not provided'),
            _buildDetailRow('Role', user.role),
            _buildDetailRow('Trust Score', '${user.trustScore.toStringAsFixed(1)} / 100'),
            _buildDetailRow('Account Status', user.isBanned ? 'Blocked / Banned' : 'Active'),
            _buildDetailRow('Created At', DateFormat('dd MMM yyyy, HH:mm').format(user.createdAt)),
            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Bio:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(user.bio, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredUsers;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Search / Filter Controls
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, phone, or UID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              // Role Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRoleFilter,
                    items: ['All', 'Rider', 'Host', 'Admin'].map((role) {
                      return DropdownMenuItem(value: role, child: Text('Role: $role'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRoleFilter = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatusFilter,
                    items: ['All', 'Active', 'Banned'].map((status) {
                      return DropdownMenuItem(value: status, child: Text('Status: $status'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatusFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick count overview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filtered.length} of ${widget.users.length} Users',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? AppColors.onSurfaceVariantDark : Colors.grey.shade700,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildStatPill('Riders: ${widget.users.where((u) => u.role.toLowerCase() == 'rider').length}', Colors.green),
                  _buildStatPill('Hosts: ${widget.users.where((u) => u.role.toLowerCase() == 'host').length}', Colors.blue),
                  _buildStatPill('Admins: ${widget.users.where((u) => u.role.toLowerCase() == 'admin').length}', Colors.red),
                  _buildStatPill('Banned: ${widget.users.where((u) => u.isBanned).length}', Colors.orange),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Users List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No users found matching current filters.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: user.isBanned
                                ? Colors.red.withValues(alpha: 0.5)
                                : (isDark ? AppColors.outlineVariantDark : Colors.grey.shade200),
                            width: user.isBanned ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                              child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        user.displayName.isNotEmpty ? user.displayName : 'Unnamed User',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildRoleBadge(user.role),
                                      if (user.isBanned) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('BANNED', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${user.email} • UID: ${user.uid.substring(0, user.uid.length > 8 ? 8 : user.uid.length)}',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _showTrustScoreDialog(user),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.speed, size: 12, color: Colors.teal),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Trust: ${user.trustScore.toStringAsFixed(1)}',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(Icons.edit, size: 10, color: Colors.teal),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Joined: ${DateFormat('MMM yyyy').format(user.createdAt)}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons
                            Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info_outline, size: 20),
                                  tooltip: 'View Profile',
                                  onPressed: () => _showUserDetailsDialog(user),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.manage_accounts, size: 16),
                                  label: const Text('Role', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () => _showRoleDialog(user),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: user.isBanned ? Colors.green : Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  onPressed: () => widget.onToggleBan(user),
                                  child: Text(user.isBanned ? 'Unblock' : 'Block', style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;
    switch (role.toLowerCase()) {
      case 'admin':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade700;
        break;
      case 'host':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade700;
        break;
      default:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildStatPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
