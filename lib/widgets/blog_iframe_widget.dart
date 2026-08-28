import 'package:flutter/material.dart';
import 'blog_iframe_stub.dart'
    if (dart.library.html) 'blog_iframe_web.dart' as impl;

class BlogIframeWidget extends StatelessWidget {
  final String postId;
  final String embedUrl;

  const BlogIframeWidget({
    super.key,
    required this.postId,
    required this.embedUrl,
  });

  @override
  Widget build(BuildContext context) {
    return impl.buildBlogIframe(postId: postId, embedUrl: embedUrl);
  }
}
