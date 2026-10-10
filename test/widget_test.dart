import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_mobile/main.dart';

void main() {
  testWidgets('Bachat opens with its brand and purpose', (tester) async {
    await tester.pumpWidget(const BachatApp());
    expect(find.text('bachat'), findsOneWidget);
    expect(find.textContaining('A little clarity.'), findsOneWidget);
  });
}
