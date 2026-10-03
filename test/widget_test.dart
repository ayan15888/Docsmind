import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docsmind/main.dart';

void main() {
  testWidgets('DocsMind app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    expect(find.byType(MyApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
