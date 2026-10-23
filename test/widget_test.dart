import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_play/main.dart';
import 'package:ab_play/widgets/social_button.dart';

void main() {
  testWidgets('Ab-Play login screen renders branding and login buttons', (WidgetTester tester) async {
    // Set a phone screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AbPlayApp());
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Ab-Play'), findsOneWidget);
    expect(find.text('Party Game & Voice Chat'), findsOneWidget);

    // Verify Help Action
    expect(find.text('Help'), findsOneWidget);

    // Verify Main Social Buttons
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Sign in with Facebook'), findsOneWidget);

    // Verify Circular Icon Buttons (Apple and X)
    expect(find.byType(CircularIconButton), findsNWidgets(2));

    // Verify Legal RichText
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('By signing in, you agree to our Terms of Service'),
      ),
      findsOneWidget,
    );
  });
}
