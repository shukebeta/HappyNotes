import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:math' as math;

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
      
      // Add zoom functionality with mouse wheel and touch gestures for fullscreen
      double scale = 1.0;
      double lastScale = 1.0;
      
      // Mouse wheel zoom
      imgElement.onWheel.listen((event) {
        event.preventDefault();
        scale += event.deltaY > 0 ? -0.1 : 0.1;
        scale = scale.clamp(0.5, 3.0);
        imgElement.style.transform = 'scale($scale)';
        imgElement.style.cursor = scale > 1.0 ? 'zoom-out' : 'zoom-in';
      });
      
      // Touch gesture zoom
      Map<int, html.Touch> activeTouches = {};
      
      imgElement.onTouchStart.listen((event) {
        event.preventDefault();
        for (var touch in event.changedTouches!) {
          activeTouches[touch.identifier ?? 0] = touch;
        }
      });
      
      imgElement.onTouchMove.listen((event) {
        event.preventDefault();
        if (activeTouches.length == 2) {
          var touches = activeTouches.values.toList();
          var touch1 = touches[0];
          var touch2 = touches[1];
          
          // Find current touches
          html.Touch? currentTouch1;
          html.Touch? currentTouch2;
          
          for (var touch in event.touches!) {
            if (touch.identifier == touch1.identifier) {
              currentTouch1 = touch;
            } else if (touch.identifier == touch2.identifier) {
              currentTouch2 = touch;
            }
          }
          
          if (currentTouch1 != null && currentTouch2 != null) {
            // Calculate distance between touches
            double currentDistance = _calculateDistance(currentTouch1, currentTouch2);
            double initialDistance = _calculateDistance(touch1, touch2);
            
            if (initialDistance > 0) {
              double gestureScale = currentDistance / initialDistance;
              double newScale = lastScale * gestureScale;
              newScale = newScale.clamp(0.5, 3.0);
              
              imgElement.style.transform = 'scale($newScale)';
              scale = newScale;
            }
          }
        }
      });
      
      imgElement.onTouchEnd.listen((event) {
        event.preventDefault();
        for (var touch in event.changedTouches!) {
          activeTouches.remove(touch.identifier ?? 0);
        }
        lastScale = scale;
        imgElement.style.cursor = scale > 1.0 ? 'zoom-out' : 'zoom-in';
      });
      
      // Reset zoom on double tap in fullscreen
      imgElement.onDoubleClick.listen((event) {
        scale = 1.0;
        lastScale = 1.0;
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
      ..style.maxHeight = '300px'
      ..style.overflow = 'hidden'
      ..style.position = 'relative'
      ..style.display = 'flex'
      ..style.alignItems = 'center';
    
    final imgElement = html.ImageElement()
      ..src = src
      ..style.width = '100%'
      ..style.height = 'auto' // Let image scale naturally
      ..style.maxHeight = '300px'
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
    constraints: const BoxConstraints(
      maxHeight: 300, // Prevent excessive height
      minHeight: 150, // Ensure minimum visibility
    ),
    clipBehavior: Clip.hardEdge, // Clip any overflow
    decoration: const BoxDecoration(), // Required for clipBehavior
    child: Stack(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
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

// Helper function to calculate distance between two touch points
double _calculateDistance(html.Touch touch1, html.Touch touch2) {
  double dx = (touch1.page?.x ?? 0).toDouble() - (touch2.page?.x ?? 0).toDouble();
  double dy = (touch1.page?.y ?? 0).toDouble() - (touch2.page?.y ?? 0).toDouble();
  return math.sqrt(dx * dx + dy * dy);
}