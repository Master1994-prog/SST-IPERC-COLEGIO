import 'package:flutter_test/flutter_test.dart';
import 'package:sst_mobile/app.dart';

void main() {
  testWidgets('La pantalla de bienvenida se muestra correctamente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SstIpercApp());

    expect(find.text('SST - IPERC'), findsOneWidget);
    expect(find.text('Ingresar al sistema'), findsOneWidget);
    expect(find.text('Matrices IPERC'), findsOneWidget);
  });
}
