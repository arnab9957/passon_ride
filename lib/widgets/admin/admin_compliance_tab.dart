import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';

class AdminComplianceTab extends StatefulWidget {
  final List<ComplianceDocument> documents;
  final Function(ComplianceDocument doc, String newStatus) onUpdateDocumentStatus;

  const AdminComplianceTab({
    super.key,
    required this.documents,
    required this.onUpdateDocumentStatus,
  });

  @override
  State<AdminComplianceTab> createState() => _AdminComplianceTabState();
}

class _AdminComplianceTabState extends State<AdminComplianceTab> {
  String _searchQuery = '';
  int _selectedStatusIndex = 0; // 0: Pending, 1: Verified, 2: Action Required, 3: All
  String _selectedType = 'All';

  List<ComplianceDocument> get _filteredDocuments {
    return widget.documents.where((doc) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          doc.title.toLowerCase().contains(q) ||
          doc.holderName.toLowerCase().contains(q) ||
          doc.documentNumber.toLowerCase().contains(q) ||
          doc.userId.toLowerCase().contains(q) ||
          doc.type.toLowerCase().contains(q);

      bool matchesStatus = true;
      if (_selectedStatusIndex == 0) {
        matchesStatus = doc.status.toLowerCase() == 'pending';
      } else if (_selectedStatusIndex == 1) {
        matchesStatus = doc.status.toLowerCase() == 'verified';
      } else if (_selectedStatusIndex == 2) {
        matchesStatus = doc.status.toLowerCase() == 'action required' || doc.status.toLowerCase() == 'rejected';
      }

      final matchesType = _selectedType == 'All' ||
          doc.type.toLowerCase() == _selectedType.toLowerCase() ||
          doc.title.toLowerCase().contains(_selectedType.toLowerCase());

      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  void _showInspectDialog(ComplianceDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc.title.isNotEmpty ? doc.title : 'Document #${doc.id.substring(0, 8)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow('Doc ID', doc.id),
              _buildRow('User ID', doc.userId),
              _buildRow('Document Type', doc.type),
              _buildRow('Holder Name', doc.holderName),
              _buildRow('Document #', doc.documentNumber),
              _buildRow('Status', doc.status.toUpperCase()),
              _buildRow('Expiry Date', DateFormat('dd MMM yyyy').format(doc.expiryDate)),
              _buildRow('Expiry Valid?', doc.isExpiryValid ? 'YES' : 'EXPIRED / INVALID'),
              _buildRow('OCR Confidence', '${(doc.confidenceScore * 100).toStringAsFixed(1)}%'),
              if (doc.issuingAuthority.isNotEmpty) _buildRow('Authority', doc.issuingAuthority),
              if (doc.bloodGroup.isNotEmpty) _buildRow('Blood Group', doc.bloodGroup),
              if (doc.dob.isNotEmpty) _buildRow('DOB', doc.dob),
              if (doc.address.isNotEmpty) _buildRow('Address', doc.address),
              const SizedBox(height: 12),
              if (doc.documentUrl.isNotEmpty)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(doc.documentUrl);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open Scanned Document File'),
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
    final filtered = _filteredDocuments;

    final int pendingCount = widget.documents.where((d) => d.status.toLowerCase() == 'pending').length;
    final int verifiedCount = widget.documents.where((d) => d.status.toLowerCase() == 'verified').length;
    final int actionCount = widget.documents.where((d) => d.status.toLowerCase() == 'action required' || d.status.toLowerCase() == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Status Segments
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Holder Name, Document Number, User ID...',
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
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text('Pending ($pendingCount)')),
                  ButtonSegment(value: 1, label: Text('Verified ($verifiedCount)')),
                  ButtonSegment(value: 2, label: Text('Action Req ($actionCount)')),
                  const ButtonSegment(value: 3, label: Text('All')),
                ],
                selected: {_selectedStatusIndex},
                onSelectionChanged: (set) => setState(() => _selectedStatusIndex = set.first),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Document Type Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Driving License', 'Aadhaar', 'PAN', 'RC', 'Insurance', 'PUC'].map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedType = type);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Document review items
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No compliance documents found matching current filters.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final isPending = doc.status.toLowerCase() == 'pending';
                      final isVerified = doc.status.toLowerCase() == 'verified';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPending
                                ? Colors.amber.shade600
                                : (isVerified ? (isDark ? AppColors.outlineVariantDark : Colors.grey.shade200) : Colors.red.shade400),
                            width: isPending ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isVerified ? Colors.green : (isPending ? Colors.amber : Colors.red)).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isVerified ? Icons.verified : (isPending ? Icons.pending_actions : Icons.warning),
                                color: isVerified ? Colors.green : (isPending ? Colors.amber.shade800 : Colors.red),
                                size: 26,
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
                                        doc.title.isNotEmpty ? doc.title : '${doc.type} (${doc.holderName})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusPill(doc.status),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'OCR: ${(doc.confidenceScore * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Holder: ${doc.holderName.isNotEmpty ? doc.holderName : "N/A"} • Doc #: ${doc.documentNumber.isNotEmpty ? doc.documentNumber : "Pending"}',
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        'Expiry: ${DateFormat('dd MMM yyyy').format(doc.expiryDate)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: doc.isExpiryValid ? Colors.grey : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'User ID: ${doc.userId.isNotEmpty ? doc.userId.substring(0, doc.userId.length > 8 ? 8 : doc.userId.length) : "Unknown"}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                                  tooltip: 'Inspect Metadata',
                                  onPressed: () => _showInspectDialog(doc),
                                ),
                                if (doc.documentUrl.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.indigo),
                                    tooltip: 'View Document File',
                                    onPressed: () async {
                                      final uri = Uri.tryParse(doc.documentUrl);
                                      if (uri != null && await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                  ),
                                if (!isVerified)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Verify'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => widget.onUpdateDocumentStatus(doc, 'Verified'),
                                  ),
                                if (isVerified)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    onPressed: () => widget.onUpdateDocumentStatus(doc, 'Action Required'),
                                    child: const Text('Revoke'),
                                  )
                                else
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    onPressed: () => widget.onUpdateDocumentStatus(doc, 'Action Required'),
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

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'verified':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
        break;
      case 'pending':
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade900;
        break;
      default:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
