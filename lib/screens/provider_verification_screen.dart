import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

const Map<String, List<String>> kProviderDocuments = {
  'Vehicle Host': ['RC', 'Insurance', 'Commercial Rental Permit'],
  'Hotel / Homestay': ['Property Ownership or Lease Proof', 'Business / Trade Licence'],
  'Tour Guide': [],
};
const List<String> kCommonDocuments = ['ID Document', 'Selfie'];

/// Shows [child] to verified providers and the verification flow to everyone else.
class ProviderVerificationGate extends StatelessWidget {
  final Widget child;

  const ProviderVerificationGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return appState.canPublishListings ? child : const ProviderVerificationScreen();
  }
}

class ProviderVerificationScreen extends StatefulWidget {
  const ProviderVerificationScreen({super.key});

  @override
  State<ProviderVerificationScreen> createState() => _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState extends State<ProviderVerificationScreen> {
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _addressController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _payoutController = TextEditingController();
  final _picker = ImagePicker();

  final Set<String> _providerTypes = {};
  final Map<String, String> _documents = {};
  String _idType = 'PAN';
  String? _uploading;
  bool _submitting = false;
  bool _editing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _addressController.dispose();
    _idNumberController.dispose();
    _payoutController.dispose();
    super.dispose();
  }

  List<String> get _requiredDocuments => [
        ...kCommonDocuments,
        for (final type in _providerTypes) ...kProviderDocuments[type]!,
      ];

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDocument(String label) async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null || !mounted) return;

    setState(() => _uploading = label);
    final appState = Provider.of<AppState>(context, listen: false);
    final path = await appState.supabaseService.uploadProviderDocument(
      bytes: await image.readAsBytes(),
      label: label,
    );
    if (!mounted) return;
    setState(() {
      _uploading = null;
      if (path != null) _documents[label] = path;
    });
    if (path == null) _toast('Upload failed. Please try again.');
  }

  Future<void> _submit() async {
    final idNumber = _idNumberController.text.trim();
    if (_providerTypes.isEmpty) return _toast('Select what you want to host.');
    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        idNumber.isEmpty ||
        _payoutController.text.trim().isEmpty) {
      return _toast('Please fill in all required fields.');
    }
    if (_idType == 'Aadhaar' && !RegExp(r'^\d{4}$').hasMatch(idNumber)) {
      return _toast('Enter only the last 4 digits of your Aadhaar.');
    }
    final missing = _requiredDocuments.where((d) => !_documents.containsKey(d));
    if (missing.isNotEmpty) return _toast('Please upload: ${missing.join(', ')}');

    setState(() => _submitting = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.submitProviderVerification(
      providerTypes: _providerTypes.toList(),
      fullName: _nameController.text.trim(),
      businessName: _businessController.text.trim(),
      address: _addressController.text.trim(),
      idType: _idType,
      idNumber: _idType == 'Aadhaar' ? 'XXXX-XXXX-$idNumber' : idNumber,
      payoutDetails: _payoutController.text.trim(),
      documents: _documents,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (success) _editing = false;
    });
    _toast(success ? 'Submitted for review.' : 'Could not submit. Please try again.');
  }

  Widget _buildStatus(String title, String message, IconData icon, Color color, {String notes = '', bool canResubmit = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Admin note: $notes', textAlign: TextAlign.center, style: TextStyle(color: color)),
            ],
            if (canResubmit) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _editing = true),
                child: const Text('Update and Resubmit'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verify your profile before publishing. Our team reviews every submission.',
          ),
          const SizedBox(height: 14),
          const Text('What will you host? *', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              for (final type in kProviderDocuments.keys)
                FilterChip(
                  label: Text(type),
                  selected: _providerTypes.contains(type),
                  onSelected: (on) => setState(() => on ? _providerTypes.add(type) : _providerTypes.remove(type)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _field(_nameController, 'Full Legal Name *'),
          _field(_businessController, 'Business Name (optional)'),
          _field(_addressController, 'Full Address *', maxLines: 2),
          DropdownButtonFormField<String>(
            initialValue: _idType,
            decoration: const InputDecoration(labelText: 'ID Type *', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'PAN', child: Text('PAN')),
              DropdownMenuItem(value: 'Aadhaar', child: Text('Aadhaar (masked)')),
            ],
            onChanged: (v) => setState(() {
              _idType = v ?? 'PAN';
              _idNumberController.clear();
            }),
          ),
          const SizedBox(height: 12),
          _field(_idNumberController, _idType == 'Aadhaar' ? 'Last 4 Digits of Aadhaar *' : 'PAN Number *'),
          _field(_payoutController, 'UPI ID or Bank Details for Payouts *'),
          const Text('Documents *', style: TextStyle(fontWeight: FontWeight.bold)),
          if (_idType == 'Aadhaar')
            const Text('Upload a masked Aadhaar showing only the last 4 digits.', style: TextStyle(fontSize: 12)),
          for (final label in _requiredDocuments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _documents.containsKey(label) ? Icons.check_circle : Icons.upload_file,
                color: _documents.containsKey(label) ? Colors.green : null,
              ),
              title: Text(label),
              trailing: _uploading == label
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: _uploading != null ? null : () => _pickDocument(label),
                      child: Text(_documents.containsKey(label) ? 'Replace' : 'Upload'),
                    ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting || _uploading != null ? null : _submit,
              child: Text(_submitting ? 'Submitting...' : 'Submit for Verification'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final host = appState.hostProfile;
    final state = appState.providerReviewState;

    final Widget body;
    if (_editing || state == 'not_submitted') {
      body = _buildForm();
    } else if (state == 'rejected') {
      body = _buildStatus(
        'Verification rejected',
        'Please correct your details and submit again.',
        Icons.cancel_outlined,
        Colors.red,
        notes: host?.verificationNotes ?? '',
        canResubmit: true,
      );
    } else if (state == 'action_required') {
      body = _buildStatus(
        'Changes requested',
        'Our team needs a few changes before approving you.',
        Icons.edit_note,
        Colors.orange,
        notes: host?.verificationNotes ?? '',
        canResubmit: true,
      );
    } else {
      body = _buildStatus(
        'Verification in review',
        'Your details are with our team. You can publish as soon as you are approved.',
        Icons.hourglass_top,
        Colors.amber.shade800,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Verification')),
      body: body,
    );
  }
}
