import 'package:dukan_ko/controllers/app_state.dart';
import 'package:dukan_ko/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dukanko app starts on the login screen', (tester) async {
    await tester.pumpWidget(DukankoApp(state: AppState()));

    expect(find.text('Dukanko'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
