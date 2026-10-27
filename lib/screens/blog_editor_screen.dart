import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../widgets/blog_image_embed.dart';

/// Full-screen editor for creating or editing a blog post.
/// Pops with `true` when the post was saved.
class BlogEditorScreen extends StatefulWidget {
  final BlogPost? existingPost;

  const BlogEditorScreen({super.key, this.existingPost});

  @override
  State<BlogEditorScreen> createState() => _BlogEditorScreenState();
}

class _BlogEditorScreenState extends State<BlogEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _handleController = TextEditingController();
  final _urlController = TextEditingController();
  final _editorFocus = FocusNode();
  final _picker = ImagePicker();
  late final QuillController _quillController;

  String _postType = 'text'; // 'text' or 'social_embed'
  String _socialPlatform = 'youtube'; // 'youtube', 'instagram', 'twitter', 'facebook'
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  bool get _isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    final post = widget.existingPost;
    _quillController = QuillController.basic();
    if (post != null) {
      _titleController.text = post.title;
      _postType = post.postType;
      _socialPlatform = post.socialPlatform ?? 'youtube';
      _handleController.text = post.socialHandle ?? '';
      _urlController.text = post.embedUrl ?? '';
      _loadContent(post.content);
    }
  }

  void _loadContent(String content) {
    try {
      if (content.startsWith('[') || content.startsWith('{')) {
        _quillController.document = Document.fromJson(jsonDecode(content));
        return;
      }
    } catch (_) {}
    // Legacy plain-text posts
    _quillController.document = Document()..insert(0, content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _handleController.dispose();
    _urlController.dispose();
    _editorFocus.dispose();
    _quillController.dispose();
    super.dispose();
  }

  String? _parseAndConvertEmbedUrl(String platform, String url) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;
    // Already converted (editing an existing post)
    if (cleanUrl.contains('/embed') || cleanUrl.contains('plugins/post.php')) return cleanUrl;

    if (platform == 'youtube') {
      final ytRegex = RegExp(
          r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
          caseSensitive: false);
      final match = ytRegex.firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 1) {
        return 'https://www.youtube.com/embed/${match.group(1)}';
      }
      if (cleanUrl.length == 11 && !cleanUrl.contains('/')) {
        return 'https://www.youtube.com/embed/$cleanUrl';
      }
    } else if (platform == 'instagram') {
      final match = RegExp(r'instagram\.com\/(?:p|reel)\/([a-zA-Z0-9_\-]+)', caseSensitive: false)
          .firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 1) {
        return 'https://www.instagram.com/p/${match.group(1)}/embed';
      }
    } else if (platform == 'twitter') {
      final match = RegExp(r'(?:twitter|x)\.com\/[a-zA-Z0-9_]+\/status\/([0-9]+)', caseSensitive: false)
          .firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 1) {
        return 'https://platform.twitter.com/embed/Tweet.html?id=${match.group(1)}';
      }
    } else if (platform == 'facebook') {
      return 'https://www.facebook.com/plugins/post.php?href=${Uri.encodeComponent(cleanUrl)}&show_text=true';
    }

    return cleanUrl.startsWith('http') ? cleanUrl : 'https://$cleanUrl';
  }

  Future<void> _insertImage(ImageSource source) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (picked == null) return;
      setState(() => _isUploadingImage = true);

      final bytes = await picked.readAsBytes();
      final url = await appState.imageKitService.uploadImage(
        bytes: bytes,
        fileName: 'blog_${DateTime.now().millisecondsSinceEpoch}.jpg',
        folder: '/blog',
      );
      if (url == null) throw Exception('Upload failed');

      final index = _quillController.selection.baseOffset < 0
          ? _quillController.document.length - 1
          : _quillController.selection.baseOffset;
      _quillController.replaceText(index, 0, BlockEmbed.image(url), null);
      _quillController.replaceText(index + 1, 0, '\n', TextSelection.collapsed(offset: index + 2));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not add image: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _insertImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _insertImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final hasText = _quillController.document.toPlainText().replaceAll('￼', '').trim().isNotEmpty;
    final hasImage = _quillController.document.toDelta().toList().any((op) => op.data is Map);
    if (!hasText && !hasImage) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Write something or add a photo'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final isEmbed = _postType == 'social_embed';
    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());
    final embedUrl = isEmbed ? _parseAndConvertEmbedUrl(_socialPlatform, _urlController.text) : null;

    try {
      if (_isEditing) {
        await appState.updateBlogPost(
          widget.existingPost!,
          title: _titleController.text.trim(),
          content: contentJson,
          postType: _postType,
          socialPlatform: isEmbed ? _socialPlatform : null,
          socialHandle: isEmbed ? _handleController.text.trim() : null,
          embedUrl: embedUrl,
        );
      } else {
        await appState.createBlogPost(
          title: _titleController.text.trim(),
          content: contentJson,
          postType: _postType,
          socialPlatform: isEmbed ? _socialPlatform : null,
          socialHandle: isEmbed ? _handleController.text.trim() : null,
          embedUrl: embedUrl,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error saving post: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final hasChanges = _titleController.text.trim().isNotEmpty ||
        _quillController.document.toPlainText().trim().isNotEmpty;
    if (!hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved edits will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _isSubmitting) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Post' : 'New Post', style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: _isSubmitting || _isUploadingImage ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Update' : 'Publish', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Formatting toolbar + image button
              Container(
                color: isDark ? AppColors.surfaceContainerDark : Colors.grey.shade100,
                child: Row(
                  children: [
                    Expanded(
                      child: QuillSimpleToolbar(
                        controller: _quillController,
                        config: const QuillSimpleToolbarConfig(
                          multiRowsDisplay: false,
                          showFontFamily: false,
                          showFontSize: false,
                          showSubscript: false,
                          showSuperscript: false,
                          showInlineCode: false,
                          showSearchButton: false,
                          showCodeBlock: false,
                          showColorButton: false,
                          showBackgroundColorButton: false,
                          showDirection: false,
                          showIndent: false,
                          showJustifyAlignment: false,
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    _isUploadingImage
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : IconButton(
                            icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                            tooltip: 'Insert photo',
                            onPressed: _showImageSourceSheet,
                          ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // Post type
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'text', label: Text('Story'), icon: Icon(Icons.notes)),
                        ButtonSegment(value: 'social_embed', label: Text('Social Post'), icon: Icon(Icons.link)),
                      ],
                      selected: {_postType},
                      onSelectionChanged: (s) => setState(() => _postType = s.first),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),

                    if (_postType == 'social_embed') ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _socialPlatform,
                        decoration: InputDecoration(
                          labelText: 'Platform',
                          prefixIcon: const Icon(Icons.public),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'youtube', child: Text('YouTube Video')),
                          DropdownMenuItem(value: 'instagram', child: Text('Instagram Post/Reel')),
                          DropdownMenuItem(value: 'twitter', child: Text('Twitter / X Tweet')),
                          DropdownMenuItem(value: 'facebook', child: Text('Facebook Post')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _socialPlatform = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _handleController,
                        decoration: InputDecoration(
                          labelText: 'Your Handle',
                          hintText: '@user',
                          prefixIcon: const Icon(Icons.alternate_email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (_postType == 'social_embed' && (v == null || v.trim().isEmpty))
                            ? 'Social handle is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'Post URL',
                          hintText: 'Paste link here...',
                          prefixIcon: const Icon(Icons.link),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (_postType == 'social_embed' && (v == null || v.trim().isEmpty))
                            ? 'Post URL is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Divider(),

                    // Body editor
                    QuillEditor(
                      controller: _quillController,
                      focusNode: _editorFocus,
                      scrollController: ScrollController(),
                      config: QuillEditorConfig(
                        placeholder: _postType == 'text'
                            ? 'Tell your story... Use the 📷 button to add photos.'
                            : 'Add a short description of the post...',
                        scrollable: false,
                        expands: false,
                        minHeight: 300,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        embedBuilders: const [BlogImageEmbedBuilder()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
