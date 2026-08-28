import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({super.key});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _quillController = QuillController.basic();
  final _handleController = TextEditingController();
  final _urlController = TextEditingController();

  String _postType = 'text'; // 'text' or 'social_embed'
  String _socialPlatform = 'youtube'; // 'youtube', 'instagram', 'twitter', 'facebook'
  bool _isSubmitting = false;
  bool _isExpanded = false;

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _handleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String? _parseAndConvertEmbedUrl(String platform, String url) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;

    if (platform == 'youtube') {
      final ytRegex = RegExp(
          r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
          caseSensitive: false);
      final match = ytRegex.firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 1) {
        final videoId = match.group(1);
        return 'https://www.youtube.com/embed/$videoId';
      }
      if (cleanUrl.length == 11 && !cleanUrl.contains('/')) {
        return 'https://www.youtube.com/embed/$cleanUrl';
      }
    } else if (platform == 'instagram') {
      final igRegex = RegExp(r'instagram\.com\/(?:p|reel)\/([a-zA-Z0-9_\-]+)',
          caseSensitive: false);
      final match = igRegex.firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 1) {
        final postId = match.group(1);
        return 'https://www.instagram.com/p/$postId/embed';
      }
    } else if (platform == 'twitter') {
      final twRegex = RegExp(r'(?:twitter|x)\.com\/[a-zA-Z0-9_]+\/status\/([0-9]+)',
          caseSensitive: false);
      final match = twRegex.firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 1) {
        final tweetId = match.group(1);
        return 'https://platform.twitter.com/embed/Tweet.html?id=$tweetId';
      }
    } else if (platform == 'facebook') {
      final encoded = Uri.encodeComponent(cleanUrl);
      return 'https://www.facebook.com/plugins/post.php?href=$encoded&show_text=true';
    }

    return cleanUrl.startsWith('http') ? cleanUrl : 'https://$cleanUrl';
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate Quill Editor Content
    final plainText = _quillController.document.toPlainText().trim();
    if (plainText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content / Description is required'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final appState = Provider.of<AppState>(context, listen: false);

    String? finalEmbedUrl;
    if (_postType == 'social_embed') {
      finalEmbedUrl = _parseAndConvertEmbedUrl(_socialPlatform, _urlController.text);
    }

    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

    try {
      await appState.createBlogPost(
        title: _titleController.text.trim(),
        content: contentJson,
        postType: _postType,
        socialPlatform: _postType == 'social_embed' ? _socialPlatform : null,
        socialHandle: _postType == 'social_embed' ? _handleController.text.trim() : null,
        embedUrl: finalEmbedUrl,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blog post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceContainerDark : Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxWidth: 550,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Blog Post',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Scrollable Content area
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Type Segmented Button
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTypeSegmentButton('text', 'Share Thought', Icons.notes),
                              _buildTypeSegmentButton('social_embed', 'Embed Social Post', Icons.link),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Common Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Post Title',
                          hintText: 'Enter a catchy title...',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Post Description / Thoughts Field with Quill Editor
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _postType == 'text' ? 'Your Thoughts' : 'Post Description',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                tooltip: _isExpanded ? 'Collapse Editor' : 'Expand Editor',
                                onPressed: () {
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            height: _isExpanded ? 380 : 220,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                            ),
                            child: Column(
                              children: [
                                QuillSimpleToolbar(
                                  controller: _quillController,
                                  config: const QuillSimpleToolbarConfig(
                                    showFontFamily: false,
                                    showFontSize: false,
                                    showSubscript: false,
                                    showSuperscript: false,
                                    showInlineCode: false,
                                    showSearchButton: false,
                                    showCodeBlock: false,
                                    showColorButton: false,
                                    showBackgroundColorButton: false,
                                    showAlignmentButtons: false,
                                    showLeftAlignment: false,
                                    showCenterAlignment: false,
                                    showRightAlignment: false,
                                    showJustifyAlignment: false,
                                    showDirection: false,
                                    showIndent: false,
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: QuillEditor.basic(
                                      controller: _quillController,
                                      config: QuillEditorConfig(
                                        placeholder: _postType == 'text'
                                            ? 'What is on your mind? Share your ride or travel experiences...'
                                            : 'Provide a brief summary or key takeaways of the embedded post...',
                                        expands: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Social Embedding Specific Fields
                      if (_postType == 'social_embed') ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Social Embed Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Platform Dropdown Selector
                        DropdownButtonFormField<String>(
                          initialValue: _socialPlatform,
                          decoration: InputDecoration(
                            labelText: 'Social Platform',
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
                            if (val != null) {
                              setState(() => _socialPlatform = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Handle & URL Fields (Stacked vertically)
                        TextFormField(
                          controller: _handleController,
                          decoration: InputDecoration(
                            labelText: 'Your Handle',
                            hintText: '@user',
                            prefixIcon: const Icon(Icons.alternate_email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (_postType == 'social_embed' && (value == null || value.trim().isEmpty)) {
                              return 'Social handle is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: 'Post URL',
                            hintText: 'Paste link here...',
                            prefixIcon: const Icon(Icons.link),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (_postType == 'social_embed' && (value == null || value.trim().isEmpty)) {
                              return 'Post URL is required';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Sticky Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Publish Post', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegmentButton(String type, String label, IconData icon) {
    final isSelected = _postType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _postType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : AppColors.primaryContainer)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
