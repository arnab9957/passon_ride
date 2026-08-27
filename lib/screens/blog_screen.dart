import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../widgets/create_post_dialog.dart';
import '../widgets/blog_iframe_widget.dart';
import '../widgets/supabase_auth_dialog.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  String _activeTab = 'all'; // 'all', 'text', 'social'

  @override
  void initState() {
    super.initState();
    // Load posts on page enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).loadBlogPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Filter posts based on active tab
    final filteredPosts = appState.blogPosts.where((post) {
      if (_activeTab == 'all') return true;
      if (_activeTab == 'text') return post.postType == 'text';
      if (_activeTab == 'social') return post.postType == 'social_embed';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Blog & Social Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Feed',
            onPressed: () => appState.loadBlogPosts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Database Fallback Notice Banner
          if (!appState.isBlogDbInitialized)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.amber.shade900.withOpacity(0.12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Running in Local Fallback Mode: DB tables are not created on Supabase. Your posts will be stored in-memory for testing.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          // Header Hero Section
          _buildHeroHeader(isDark),

          // Filters Tab Bar Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Posts', Icons.feed_outlined),
                const SizedBox(width: 8),
                _buildFilterChip('text', 'Rider Thoughts', Icons.notes_outlined),
                const SizedBox(width: 8),
                _buildFilterChip('social', 'Connected Handles', Icons.rss_feed_outlined),
              ],
            ),
          ),

          // Post feed List
          Expanded(
            child: appState.isLoadingBlog
                ? const Center(child: CircularProgressIndicator())
                : filteredPosts.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPosts.length,
                        itemBuilder: (ctx, idx) {
                          final post = filteredPosts[idx];
                          return _BlogPostCard(post: post);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleCreatePost(context, appState),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_note, color: Colors.white),
        label: const Text('Share Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _handleCreatePost(BuildContext context, AppState appState) {
    if (!appState.isSignedIn) {
      showDialog(
        context: context,
        builder: (_) => const SupabaseAuthDialog(),
      );
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (_) => const CreatePostDialog(),
    ).then((updated) {
      if (updated == true) {
        appState.loadBlogPosts();
      }
    });
  }

  Widget _buildHeroHeader(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFEFF6FF), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.primary.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore the Community Feed',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Riders can share road stories, and link their social handles to display posts. Guided tour hosts can add community verification comments.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String tabId, String label, IconData icon) {
    final isSelected = _activeTab == tabId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _activeTab = tabId);
        }
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 72,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Posts Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your travel thoughts or embed a social handle post!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Blog Post Card component
class _BlogPostCard extends StatefulWidget {
  final BlogPost post;

  const _BlogPostCard({required this.post});

  @override
  State<_BlogPostCard> createState() => _BlogPostCardState();
}

class _BlogPostCardState extends State<_BlogPostCard> {
  bool _showComments = false;
  int _commentsCount = 0;
  bool _isLoadingCommentsCount = true;

  @override
  void initState() {
    super.initState();
    _fetchCommentsCount();
  }

  void _fetchCommentsCount() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final list = await appState.loadBlogComments(widget.post.id);
    if (mounted) {
      setState(() {
        _commentsCount = list.length;
        _isLoadingCommentsCount = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLiked = widget.post.likedByUsers.contains(appState.activeUserId);

    final isYoutube = widget.post.socialPlatform == 'youtube';
    final isInstagram = widget.post.socialPlatform == 'instagram';
    final isTwitter = widget.post.socialPlatform == 'twitter';
    final isFacebook = widget.post.socialPlatform == 'facebook';

    Color platformColor = Colors.grey.shade700;
    IconData platformIcon = Icons.link;

    if (isYoutube) {
      platformColor = const Color(0xFFFF0000);
      platformIcon = Icons.play_circle_filled;
    } else if (isInstagram) {
      platformColor = const Color(0xFFE1306C);
      platformIcon = Icons.camera_alt;
    } else if (isTwitter) {
      platformColor = const Color(0xFF1DA1F2);
      platformIcon = Icons.chat_bubble_outline;
    } else if (isFacebook) {
      platformColor = const Color(0xFF1877F2);
      platformIcon = Icons.facebook;
    }

    final formattedDate = DateFormat('MMM dd, yyyy').format(widget.post.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isDark ? 0 : 2,
      color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: widget.post.authorAvatar != null && widget.post.authorAvatar!.isNotEmpty
                        ? NetworkImage(appState.imageKitService.buildImageUrl(widget.post.authorAvatar!))
                        : null,
                    radius: 20,
                    child: widget.post.authorAvatar == null || widget.post.authorAvatar!.isEmpty
                        ? Text(
                            widget.post.authorName.isNotEmpty ? widget.post.authorName[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.post.authorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Badge for Author Role
                            _buildRoleBadge(widget.post.authorRole),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$formattedDate • ${widget.post.postType == 'social_embed' ? "Social Share" : "Thought"}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Delete post option (Author or Admin only)
                  if (appState.activeUserId == widget.post.authorId || appState.activeUserRole == 'Admin')
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      tooltip: 'Delete Post',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Blog Post?'),
                            content: const Text('Are you sure you want to permanently delete this blog post?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  appState.deleteBlogPost(widget.post.id);
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.post.content,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Connected Social Handle Iframe / Embed Section
            if (widget.post.postType == 'social_embed' && widget.post.embedUrl != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Premium App Card Header Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: widget.post.socialPlatform == 'instagram'
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF833AB4),
                                    Color(0xFFFD1D1D),
                                    Color(0xFFF56040),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: widget.post.socialPlatform != 'instagram' ? platformColor : null,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: Row(
                          children: [
                            Icon(platformIcon, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Shared via ${widget.post.socialPlatform!.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.post.socialHandle ?? '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Embed Frame Widget Viewport
                      Container(
                        height: widget.post.socialPlatform == 'youtube' ? 240 : 350,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey.shade50,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                        ),
                        child: BlogIframeWidget(
                          postId: widget.post.id,
                          embedUrl: widget.post.embedUrl!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Divider(height: 1),

            // Actions Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Like Button Pill
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (!appState.isSignedIn) {
                        showDialog(context: context, builder: (_) => const SupabaseAuthDialog(),);
                        return;
                      }
                      appState.toggleLikePost(widget.post.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLiked
                            ? Colors.redAccent.withOpacity(0.12)
                            : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLiked
                              ? Colors.redAccent.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.redAccent : (isDark ? Colors.grey : Colors.grey.shade600),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.post.likesCount}',
                            style: TextStyle(
                              color: isLiked ? Colors.redAccent : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Comment Button Pill
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() => _showComments = !_showComments);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _showComments
                            ? AppColors.primary.withOpacity(0.12)
                            : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _showComments
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: _showComments ? AppColors.primary : (isDark ? Colors.grey : Colors.grey.shade600),
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          _isLoadingCommentsCount
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                              : Text(
                                  '$_commentsCount Comments',
                                  style: TextStyle(
                                    color: _showComments ? AppColors.primary : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                                    fontSize: 12,
                                    fontWeight: _showComments ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expansion Comments Drawer
            if (_showComments)
              _CommentSectionWidget(
                postId: widget.post.id,
                onCommentsUpdated: (count) {
                  setState(() => _commentsCount = count);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color badgeColor = Colors.grey.shade500;
    String label = role;
    if (role.toLowerCase() == 'host' || role.toLowerCase() == 'provider') {
      badgeColor = AppColors.primary;
      label = 'Host Guide';
    } else if (role.toLowerCase() == 'admin') {
      badgeColor = Colors.orange;
      label = 'Admin';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: badgeColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// Comments List & Creation Widget
class _CommentSectionWidget extends StatefulWidget {
  final String postId;
  final Function(int count) onCommentsUpdated;

  const _CommentSectionWidget({
    required this.postId,
    required this.onCommentsUpdated,
  });

  @override
  State<_CommentSectionWidget> createState() => _CommentSectionWidgetState();
}

class _CommentSectionWidgetState extends State<_CommentSectionWidget> {
  final _commentController = TextEditingController();
  List<BlogComment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadComments() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final list = await appState.loadBlogComments(widget.postId);
    if (mounted) {
      setState(() {
        _comments = list;
        _isLoading = false;
      });
      widget.onCommentsUpdated(list.length);
    }
  }

  void _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      await appState.addBlogComment(postId: widget.postId, content: content);
      _commentController.clear();
      _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to comment: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Host Comments',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // Comments List
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No comments yet. Only verified Hosts can write comments.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              itemBuilder: (ctx, idx) {
                final comment = _comments[idx];
                final commentDate = DateFormat('MMM dd • HH:mm').format(comment.createdAt);
                final isHostComment = comment.authorRole.toLowerCase() == 'host' || comment.authorRole.toLowerCase() == 'provider' || comment.authorRole.toLowerCase() == 'admin';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHostComment
                          ? AppColors.primary.withOpacity(0.3)
                          : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
                      width: isHostComment ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            backgroundImage: comment.authorAvatar != null && comment.authorAvatar!.isNotEmpty
                                ? NetworkImage(appState.imageKitService.buildImageUrl(comment.authorAvatar!))
                                : null,
                            child: comment.authorAvatar == null || comment.authorAvatar!.isEmpty
                                ? Text(
                                    comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    comment.authorName,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isHostComment) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'HOST',
                                      style: TextStyle(color: AppColors.primary, fontSize: 7, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(commentDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),

                          // Delete comment button
                          if (appState.activeUserId == comment.authorId || appState.activeUserRole == 'Admin')
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent, size: 14),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                await appState.supabaseService.deleteBlogComment(comment.id);
                                _loadComments();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        comment.content,
                        style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 12),

          // Comment Input Composer - ONLY for Hosts & Admins
          if (appState.isHost) ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
                    ),
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Add a community comment...',
                        prefixIcon: Icon(Icons.comment_outlined, size: 16, color: AppColors.primary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: AppColors.primary, size: 20),
                  tooltip: 'Submit Comment',
                ),
              ],
            ),
          ] else ...[
            // Non-host restricted state UI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerLowestDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Community comments are restricted to verified hosts and guides to provide verified safety updates.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
