import 'package:djarvis_ui/app/djarvis_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds the root application with the Djarvis title', (
    tester,
  ) async {
    await tester.pumpWidget(const DjarvisApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Djarvis');
    expect(app.title, appTitle);
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('publishes the title to the platform window', (tester) async {
    await tester.pumpWidget(const DjarvisApp());

    final title = tester.widget<Title>(find.byType(Title));
    expect(title.title, 'Djarvis');
    expect(tester.takeException(), isNull);
  });
}
