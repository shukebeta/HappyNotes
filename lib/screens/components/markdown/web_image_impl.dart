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
      
      // Add zoom and pan functionality with mouse wheel and touch gestures for fullscreen
      double scale = 1.0;
      double lastScale = 1.0;
      double translateX = 0.0;
      double translateY = 0.0;
      double imageWidth = 0.0;
      double imageHeight = 0.0;
      double containerWidth = 0.0;
      double containerHeight = 0.0;
      
      void updateTransform() {
        // Apply pan boundaries based on image dimensions and zoom level
        double maxTranslateX = 0.0;
        double maxTranslateY = 0.0;
        
        if (scale > 1.0 && imageWidth > 0 && imageHeight > 0) {
          // Calculate actual displayed image dimensions
          double displayWidth = imageWidth;
          double displayHeight = imageHeight;
          
          // If image is contained, calculate the actual display size
          if (containerWidth > 0 && containerHeight > 0) {
            double imageAspectRatio = imageWidth / imageHeight;
            double containerAspectRatio = containerWidth / containerHeight;
            
            if (imageAspectRatio > containerAspectRatio) {
              // Image is wider - constrained by width
              displayWidth = containerWidth;
              displayHeight = containerWidth / imageAspectRatio;
            } else {
              // Image is taller - constrained by height
              displayHeight = containerHeight;
              displayWidth = containerHeight * imageAspectRatio;
            }
          }
          
          // Calculate how much the scaled image extends beyond the container
          double scaledWidth = displayWidth * scale;
          double scaledHeight = displayHeight * scale;
          
          // Much more restrictive - ensure at least 50% of image stays visible
          // This prevents losing the image completely
          double overflowX = math.max(0, scaledWidth - containerWidth);
          double overflowY = math.max(0, scaledHeight - containerHeight);
          
          // Limit pan to only 25% of the overflow, keeping most of image visible
          maxTranslateX = overflowX * 0.25;
          maxTranslateY = overflowY * 0.25;
        }
        
        // Clamp translation to boundaries
        translateX = translateX.clamp(-maxTranslateX, maxTranslateX);
        translateY = translateY.clamp(-maxTranslateY, maxTranslateY);
        
        imgElement.style.transform = 'scale($scale) translate(${translateX}px, ${translateY}px)';
      }
      
      // Mouse wheel zoom
      imgElement.onWheel.listen((event) {
        event.preventDefault();
        scale += event.deltaY > 0 ? -0.1 : 0.1;
        scale = scale.clamp(0.5, 3.0);
        
        // Reset translation when zooming out completely
        if (scale <= 1.0) {
          translateX = 0.0;
          translateY = 0.0;
        }
        
        updateTransform();
        imgElement.style.cursor = scale > 1.0 ? 'grab' : 'zoom-in';
      });
      
      // Get image and container dimensions when image loads
      imgElement.onLoad.listen((event) {
        imageWidth = imgElement.naturalWidth?.toDouble() ?? 0.0;
        imageHeight = imgElement.naturalHeight?.toDouble() ?? 0.0;
        
        // Get container dimensions (approximation for fullscreen)
        containerWidth = html.window.innerWidth?.toDouble() ?? 800.0;
        containerHeight = html.window.innerHeight?.toDouble() ?? 600.0;
      });
      
      // Touch gesture zoom and pan
      Map<int, html.Touch> activeTouches = {};
      double lastTranslateX = 0.0;
      double lastTranslateY = 0.0;
      
      imgElement.onTouchStart.listen((event) {
        event.preventDefault();
        for (var touch in event.changedTouches!) {
          activeTouches[touch.identifier ?? 0] = touch;
        }
      });
      
      imgElement.onTouchMove.listen((event) {
        event.preventDefault();
        
        if (activeTouches.length == 2) {
          // Two-finger pinch zoom
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
              scale = newScale;
              
              // Reset translation when zooming out completely
              if (scale <= 1.0) {
                translateX = 0.0;
                translateY = 0.0;
              }
              
              updateTransform();
            }
          }
        } else if (activeTouches.length == 1 && scale > 1.0) {
          // Single finger pan when zoomed in
          var initialTouch = activeTouches.values.first;
          var currentTouch = event.touches!.first;
          
          double deltaX = (currentTouch.page?.x ?? 0).toDouble() - (initialTouch.page?.x ?? 0).toDouble();
          double deltaY = (currentTouch.page?.y ?? 0).toDouble() - (initialTouch.page?.y ?? 0).toDouble();
          
          translateX = lastTranslateX + deltaX;
          translateY = lastTranslateY + deltaY;
          
          updateTransform();
        }
      });
      
      imgElement.onTouchEnd.listen((event) {
        event.preventDefault();
        for (var touch in event.changedTouches!) {
          activeTouches.remove(touch.identifier ?? 0);
        }
        lastScale = scale;
        lastTranslateX = translateX;
        lastTranslateY = translateY;
        imgElement.style.cursor = scale > 1.0 ? 'grab' : 'zoom-in';
      });
      
      // Reset zoom and pan on double tap in fullscreen
      imgElement.onDoubleClick.listen((event) {
        scale = 1.0;
        lastScale = 1.0;
        translateX = 0.0;
        translateY = 0.0;
        lastTranslateX = 0.0;
        lastTranslateY = 0.0;
        updateTransform();
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