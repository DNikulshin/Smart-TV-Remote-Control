import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote/constants/client_identity.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/screens/device_selection/widgets/client_identity_card.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    Future<String?>? address,
    Locale locale = const Locale('en'),
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ClientIdentityCard(address: address)),
      ),
    );
  }

  testWidgets('names the app and the address the TV will see', (tester) async {
    await pumpCard(tester, address: Future.value('192.168.1.42'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(kClientAppName),
      findsOneWidget,
      reason: 'the announced name is what the set lists',
    );
    expect(find.textContaining('192.168.1.42'), findsOneWidget);
  });

  testWidgets('falls back to the name alone with no local address', (
    tester,
  ) async {
    await pumpCard(tester, address: Future<String?>.value());
    await tester.pumpAndSettle();

    expect(find.textContaining(kClientAppName), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('copies the name and the address', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpCard(tester, address: Future.value('10.0.0.7'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pumpAndSettle();

    expect(copied, '$kClientAppName 10.0.0.7');
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('the line is translated', (tester) async {
    await pumpCard(
      tester,
      address: Future.value('192.168.1.42'),
      locale: const Locale('ru'),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('На телевизоре'), findsOneWidget);
  });
}
