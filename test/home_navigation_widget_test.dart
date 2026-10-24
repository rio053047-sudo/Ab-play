import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ab_play/screens/main_navigation_shell.dart';
import 'package:ab_play/viewmodels/auth_viewmodel.dart';
import 'package:ab_play/viewmodels/home_viewmodel.dart';
import 'package:ab_play/services/real_auth_service.dart';

void main() {
  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authService: RealAuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(),
        ),
      ],
      child: const MaterialApp(
        home: MainNavigationShell(),
      ),
    );
  }

  testWidgets('MainNavigationShell renders home lobby and bottom nav items', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify presence of user info and branding
    expect(find.text('AbPlay_Gamer'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
    expect(find.text('My Task'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);

    // Verify bottom nav items
    expect(find.text('Ab-Play'), findsOneWidget);
    expect(find.text('Voice Room'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
  });

  testWidgets('Bottom navigation tab switching works properly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap on 'Voice Room' tab
    await tester.tap(find.text('Voice Room'));
    await tester.pumpAndSettle();

    expect(find.text('Party Voice Rooms'), findsOneWidget);

    // Tap on 'Chats' tab
    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();

    expect(find.text('Messages & Groups'), findsOneWidget);

    // Switch back to Ab-Play Home
    await tester.tap(find.text('Ab-Play'));
    await tester.pumpAndSettle();

    expect(find.text('AbPlay_Gamer'), findsOneWidget);
  });
}
