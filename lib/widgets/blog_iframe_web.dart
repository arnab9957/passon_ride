import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';

Widget buildBlogIframe({required String postId, required String embedUrl}) {
  final viewId = 'blog-iframe-$postId';

  // Register the element with a unique viewId for this post
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
    final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.src = embedUrl;
    iframe.style.border = 'none';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.style.borderRadius = '12px';
    iframe.allow = 'fullscreen';
    return iframe;
  });

  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: HtmlElementView(viewType: viewId),
  );
}
