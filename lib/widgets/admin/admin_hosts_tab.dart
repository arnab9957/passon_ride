import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';

class AdminHostsTab extends StatefulWidget {
  final List<HostProfile> hosts;
  final Function(HostProfile host, bool verify) onVerifyHost;
  final Function(HostProfile host, String rejectionReason) onRejectHostWithReason;

  const AdminHostsTab({
    super.key,
    required this.hosts,
    required this.onVerifyHost,
    required this.onRejectHostWithReason,
  });

  @override
  State<AdminHostsTab> createState() => _AdminHostsTabState();
}

class _AdminHostsTabState extends State<AdminHostsTab> {
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: Pending, 1: Verified, 2: Rejected, 3: All

  List<HostProfile> get _filteredHosts {
    return widget.hosts.where((host) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          host.businessName.toLowerCase().contains(query) ||
          host.displayName.toLowerCase().contains(query) ||
          host.email.toLowerCase().contains(query) ||
          host.governmentIdNumber.toLowerCase().contains(query) ||
          host.businessRegistrationNumber.toLowerCase().contains(query);

      bool matchesStatus = true;
      if (_selectedFilterIndex == 0) {
        matchesStatus = !host.isVerified && host.verificationStatus.toLowerCase() == 'pending';
      } else if (_selectedFilterIndex == 1) {
        matchesStatus = host.isVerified || host.verificationStatus.toLowerCase() == 'verified';
      } else if (_selectedFilterIndex == 2) {
        matchesStatus = host.verificationStatus.toLowerCase() == 'rejected';
      }

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _showRejectDialog(HostProfile host) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Verification: ${host.businessName.isNotEmpty ? host.businessName : host.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejecting this host application:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Unclear government ID photo, invalid business registration...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onRejectHostWithReason(host, reasonController.text.trim());
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  void _showHostDetailsDialog(HostProfile host) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: host.isVerified ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
              child: Icon(host.isVerified ? Icons.verified : Icons.pending, color: host.isVerified ? Colors.green : Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(host.businessName.isNotEmpty ? host.businessName : host.displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Owner: ${host.displayName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow('User ID', host.userId),
              _buildRow('Email', host.email.isNotEmpty ? host.email : 'Not specified'),
              _buildRow('Phone', host.phoneNumber.isNotEmpty ? host.phoneNumber : 'Not specified'),
              _buildRow('Status', host.verificationStatus.toUpperCase()),
              _buildRow('Govt ID Type', host.governmentIdType.isNotEmpty ? host.governmentIdType : 'None'),
              _buildRow('Govt ID Number', host.governmentIdNumber.isNotEmpty ? host.governmentIdNumber : 'None'),
              _buildRow('Business Reg #', host.businessRegistrationNumber.isNotEmpty ? host.businessRegistrationNumber : 'None'),
              _buildRow('Listings Count', '${host.totalListingsCount} Vehicles'),
              _buildRow('Host Rating', '★ ${host.rating.toStringAsFixed(1)} (${host.reviewCount} reviews)'),
              if (host.verifiedAt != null)
                _buildRow('Verified Date', DateFormat('dd MMM yyyy').format(host.verifiedAt!)),
              if (host.verificationNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Notes / Reason:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(host.verificationNotes, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
              if (host.documentUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(host.documentUrl);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Inspect Uploaded ID Document'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredHosts;

    final int pendingCount = widget.hosts.where((h) => !h.isVerified && h.verificationStatus.toLowerCase() == 'pending').length;
    final int verifiedCount = widget.hosts.where((h) => h.isVerified).length;
    final int rejectedCount = widget.hosts.where((h) => h.verificationStatus.toLowerCase() == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs & Search
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search hosts by business name, owner, email, ID #...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),
              // Segmented Status Filter
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text('Pending ($pendingCount)')),
                  ButtonSegment(value: 1, label: Text('Verified ($verifiedCount)')),
                  ButtonSegment(value: 2, label: Text('Rejected ($rejectedCount)')),
                  const ButtonSegment(value: 3, label: Text('All')),
                ],
                selected: {_selectedFilterIndex},
                onSelectionChanged: (set) => setState(() => _selectedFilterIndex = set.first),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List of Hosts
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No host partner profiles found for this criteria.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final host = filtered[index];
                      final isVerified = host.isVerified;
                      final isPending = !isVerified && host.verificationStatus.toLowerCase() == 'pending';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPending
                                ? Colors.amber.shade600
                                : (isDark ? AppColors.outlineVariantDark : Colors.grey.shade200),
                            width: isPending ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isVerified
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : (isPending ? Colors.amber.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15)),
                              child: Icon(
                                isVerified ? Icons.verified : (isPending ? Icons.pending_actions : Icons.cancel_outlined),
                                color: isVerified ? Colors.green : (isPending ? Colors.amber.shade800 : Colors.red),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        host.businessName.isNotEmpty ? host.businessName : host.displayName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isVerified ? Colors.green : (isPending ? Colors.amber : Colors.red)).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          host.verificationStatus.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isVerified ? Colors.green : (isPending ? Colors.amber.shade900 : Colors.red),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Owner: ${host.displayName} • ${host.email.isNotEmpty ? host.email : host.phoneNumber}',
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (host.governmentIdType.isNotEmpty)
                                        Text(
                                          '${host.governmentIdType}: ${host.governmentIdNumber.isNotEmpty ? host.governmentIdNumber : "Uploaded"}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      if (host.businessRegistrationNumber.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        Text(
                                          'Reg #: ${host.businessRegistrationNumber}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                      const SizedBox(width: 12),
                                      Text(
                                        'Listings: ${host.totalListingsCount} vehicles',
                                        style: const TextStyle(fontSize: 11, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Action controls
                            Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info_outline, size: 20),
                                  tooltip: 'Inspect Details',
                                  onPressed: () => _showHostDetailsDialog(host),
                                ),
                                if (host.documentUrl.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.file_present_rounded, size: 20, color: Colors.indigo),
                                    tooltip: 'Open ID Document',
                                    onPressed: () async {
                                      final uri = Uri.tryParse(host.documentUrl);
                                      if (uri != null && await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                  ),
                                if (!isVerified)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => widget.onVerifyHost(host, true),
                                  ),
                                if (isVerified)
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Revoke'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => _showRejectDialog(host),
                                  )
                                else
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => _showRejectDialog(host),
                                    child: const Text('Reject'),
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
}
