import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';

/// Uploads a listing's supporting documents to private storage, filling [documents].
class ListingDocumentsSection extends StatefulWidget {
  final List<String> labels;
  final Map<String, String> documents;

  /// When editing, loads the documents previously saved under this listing name.
  final String? listingName;

  const ListingDocumentsSection({super.key, required this.labels, required this.documents, this.listingName});

  @override
  State<ListingDocumentsSection> createState() => _ListingDocumentsSectionState();
}

class _ListingDocumentsSectionState extends State<ListingDocumentsSection> {
  String? _uploading;

  @override
  void initState() {
    super.initState();
    if (widget.listingName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSaved());
    }
  }

  Future<void> _loadSaved() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final uid = appState.supabaseUser?.id;
    if (uid == null) return;
    final saved = await appState.supabaseService.getProviderVerification(uid);
    if (!mounted) return;
    final stored = Map<String, dynamic>.from(saved?['documents'] as Map? ?? {});
    setState(() {
      for (final label in widget.labels) {
        final path = stored['${widget.listingName} - $label'];
        if (path != null) widget.documents[label] = path.toString();
      }
    });
  }

  Future<void> _view(String label) async {
    final service = Provider.of<AppState>(context, listen: false).supabaseService;
    final link = await service.providerDocumentLink(widget.documents[label]!);
    if (link != null) await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
  }

  Future<void> _takePhoto(String label) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 2000,
    );
    if (image == null) return;
    await _upload(label, await image.readAsBytes(), 'jpg');
  }

  Future<void> _pick(String label) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    await _upload(label, file!.bytes!, file.extension ?? 'jpg');
  }

  Future<void> _upload(String label, Uint8List bytes, String extension) async {
    if (!mounted) return;

    setState(() => _uploading = label);
    final service = Provider.of<AppState>(context, listen: false).supabaseService;
    final path = await service.uploadProviderDocument(
      bytes: bytes,
      label: label,
      extension: extension,
    );
    if (!mounted) return;
    setState(() {
      _uploading = null;
      if (path != null) widget.documents[label] = path;
    });
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Listing Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        for (final label in widget.labels)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              widget.documents.containsKey(label) ? Icons.check_circle : Icons.upload_file,
              color: widget.documents.containsKey(label) ? Colors.green : null,
            ),
            title: Text(label),
            trailing: _uploading == label
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.documents.containsKey(label))
                        IconButton(
                          tooltip: 'View Document',
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: () => _view(label),
                        ),
                      IconButton(
                        tooltip: 'Take Photo',
                        icon: const Icon(Icons.photo_camera_outlined),
                        onPressed: _uploading != null ? null : () => _takePhoto(label),
                      ),
                      TextButton(
                        onPressed: _uploading != null ? null : () => _pick(label),
                        child: Text(widget.documents.containsKey(label) ? 'Replace' : 'Upload'),
                      ),
                    ],
                  ),
          ),
        const Text('PDF, JPG, JPEG or PNG', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

/// Read-only list of the compliance documents saved for a vehicle.
class SavedVehicleDocuments extends StatelessWidget {
  final String vehicleId;

  const SavedVehicleDocuments({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final docs = Provider.of<AppState>(context).documents
        .where((d) => d.licenseType.contains('($vehicleId)') && d.documentUrl.startsWith('http'))
        .toList();
    if (docs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Uploaded Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        for (final doc in docs)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(doc.type),
            subtitle: Text(doc.fileName),
            trailing: IconButton(
              tooltip: 'View Document',
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () => launchUrl(Uri.parse(doc.documentUrl), mode: LaunchMode.externalApplication),
            ),
          ),
      ],
    );
  }
}
