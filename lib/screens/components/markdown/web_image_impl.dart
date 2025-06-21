import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

// Web implementation using HTML elements to bypass CORS
Widget createWebImage(String src, VoidCallback? onTap, VoidCallback? onLongPress, {bool isFullScreen = false}) {
  if (isFullScreen) {
    // In fullscreen mode, add zoom functionality
    final viewId = 'image-${src.hashCode}-fullscreen-${DateTime.now().millisecondsSinceEpoch}';
    
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final imgElement = html.ImageElement()
        ..src = src
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.cursor = 'zoom-in'
        ..style.transition = 'transform 0.2s ease';
      
      // Add zoom functionality with mouse wheel for fullscreen
      double scale = 1.0;
      imgElement.onWheel.listen((event) {
        event.preventDefault();
        scale += event.deltaY > 0 ? -0.1 : 0.1;
        scale = scale.clamp(0.5, 3.0);
        imgElement.style.transform = 'scale($scale)';
        imgElement.style.cursor = scale > 1.0 ? 'zoom-out' : 'zoom-in';
      });
      
      // Reset zoom on double click in fullscreen
      imgElement.onDoubleClick.listen((event) {
        scale = 1.0;
        imgElement.style.transform = 'scale(1.0)';
        imgElement.style.cursor = 'zoom-in';
      });
      
      return imgElement;
    });

    return SizedBox(
      width: double.infinity,
      child: HtmlElementView(viewType: viewId),
    );
  }

  // Normal mode - use Stack with separate fullscreen button
  final viewId = 'image-${src.hashCode}-normal-${DateTime.now().millisecondsSinceEpoch}';
  
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    // Create a container div to control overflow
    final containerDiv = html.DivElement()
      ..style.width = '100%'
      ..style.height = '200px'
      ..style.overflow = 'hidden'
      ..style.position = 'relative';
    
    final imgElement = html.ImageElement()
      ..src = src
      ..style.width = '100%'
      ..style.height = '200px' // Force specific height
      ..style.objectFit = 'contain'
      ..style.cursor = 'pointer'
      ..style.display = 'block'
      ..onContextMenu.listen((event) {
        event.preventDefault(); // Prevent default context menu
        onLongPress?.call();
      });
    
    // Add image to container
    containerDiv.children.add(imgElement);
    
    return containerDiv;
  });

  return Container(
    height: 200, // Fixed height to prevent auto-extending
    clipBehavior: Clip.hardEdge, // Clip any overflow
    decoration: const BoxDecoration(), // Required for clipBehavior
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: HtmlElementView(viewType: viewId),
        ),
        // Simple tap detection overlay
        if (onTap != null || onLongPress != null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              onLongPress: onLongPress,
              child: const SizedBox(),
            ),
          ),
      ],
    ),
  );
}