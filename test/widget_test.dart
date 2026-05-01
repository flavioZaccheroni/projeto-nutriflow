import 'package:flutter_test/flutter_test.dart';

import 'package:nutriflow_pro/main.dart';

void main() {
  testWidgets('shows login page', (WidgetTester tester) async {
    await tester.pumpWidget(const NutriFlowApp());

    expect(find.text('NutriFlow'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
