import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Uploads a listing's supporting documents to private storage, filling [documents].
class ListingDocumentsSection extends StatefulWidget {
  final List<String> labels;
  final Map<String, String> documents;

  const ListingDocumentsSection({super.key, required this.labels, required this.documents});

  @override
  State<ListingDocumentsSection> createState() => _ListingDocumentsSectionState();
}

class _ListingDocumentsSectionState extends State<ListingDocumentsSection> {
  String? _uploading;

  Future<void> _pick(String label) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null || !mounted) return;

    setState(() => _uploading = label);
    final service = Provider.of<AppState>(context, listen: false).supabaseService;
    final path = await service.uploadProviderDocument(
      bytes: file!.bytes!,
      label: label,
      extension: file.extension ?? 'jpg',
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
                : TextButton(
                    onPressed: _uploading != null ? null : () => _pick(label),
                    child: Text(widget.documents.containsKey(label) ? 'Replace' : 'Upload'),
                  ),
          ),
        const Text('PDF, JPG, JPEG or PNG', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
