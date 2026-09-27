import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AdminBroadcastDialog extends StatefulWidget {
  final Function(String title, String message, String audience, String type) onBroadcast;

  const AdminBroadcastDialog({super.key, required this.onBroadcast});

  @override
  State<AdminBroadcastDialog> createState() => _AdminBroadcastDialogState();
}

class _AdminBroadcastDialogState extends State<AdminBroadcastDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _targetAudience = 'All Users';
  String _alertType = 'System Announcement';

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out both Title and Message.')),
      );
      return;
    }

    Navigator.pop(context);
    widget.onBroadcast(title, message, _targetAudience, _alertType);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.campaign, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Broadcast System Announcement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Publish an instant notification or emergency alert to active users on the platform.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Announcement Title',
                hintText: 'e.g. Platform Maintenance Notice / Weather Alert',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Message Body',
                hintText: 'Enter full notification content...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _targetAudience,
              decoration: InputDecoration(
                labelText: 'Target Audience',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: ['All Users', 'Riders Only', 'Hosts Only'].map((aud) {
                return DropdownMenuItem(value: aud, child: Text(aud));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _targetAudience = val);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _alertType,
              decoration: InputDecoration(
                labelText: 'Alert Priority / Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: ['System Announcement', 'Urgent Weather / Security Alert', 'Platform Promo'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _alertType = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: _submit,
          icon: const Icon(Icons.send, size: 16),
          label: const Text('Send Broadcast'),
        ),
      ],
    );
  }
}
