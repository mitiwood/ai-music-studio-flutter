import 'package:flutter_test/flutter_test.dart';
import 'package:ai_music_studio_app/app.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    await tester.pumpWidget(const KMSApp());
    expect(find.byType(KMSApp), findsOneWidget);
  });
}
