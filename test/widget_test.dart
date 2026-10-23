import 'package:flutter_test/flutter_test.dart';

import 'package:harnessvm_app/main.dart';

void main() {
  testWidgets('renders chat app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const HarnessVmApp());

    expect(find.text('HarnessVM Chat'), findsOneWidget);
    expect(
      find.text('VM chat endpoint (Tailscale IP or MagicDNS)'),
      findsOneWidget,
    );
    expect(find.text('Send'), findsOneWidget);
  });
}
