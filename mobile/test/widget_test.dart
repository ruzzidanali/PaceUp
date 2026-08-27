import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('PaceUp app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PaceUpApp());

    expect(find.text('PaceUp'), findsOneWidget);
  });
}
