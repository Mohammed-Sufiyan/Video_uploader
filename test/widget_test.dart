import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_video_uploader/main.dart';

void main() {
  testWidgets('Basic app loads and shows main widget',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VideoUploaderApp());

    // Verify main widget is present (adjust widget finder as needed)
    expect(find.byType(VideoUploaderApp), findsOneWidget);

    // Example: Check for a common visible widget in your dashboard
    // e.g., check for a Text widget with title 'Video Uploader'
    expect(find.text('Video Uploader'), findsWidgets);
  });
}
