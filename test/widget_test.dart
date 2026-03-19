import 'package:flutter_test/flutter_test.dart';

import 'package:ai_music_studio_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KMSApp());
    expect(find.text("Kenny's Music Studio"), findsOneWidget);
  });
}
