import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trivia_showdown/main.dart';

void main() {
  testWidgets('Retry recovers from a failed request', (tester) async {
    var attempts = 0;
    final client = MockClient((request) async {
      expect(request.url.queryParameters['amount'], '5');
      if (++attempts == 1) {
        return http.Response('Unavailable', 503);
      }

      return http.Response(
        jsonEncode({
          'response_code': 0,
          'results': List.generate(
            5,
            (index) => {
              'question': 'Question ${index + 1} &amp; answer',
              'correct_answer': 'Mars',
              'incorrect_answers': ['Venus', 'Jupiter', 'Mercury'],
            },
          ),
        }),
        200,
      );
    });
    addTearDown(client.close);

    await tester.pumpWidget(TriviaShowdownApp(client: client));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Server error: 503. Please try again.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Question 1 of 5'), findsOneWidget);
    expect(find.text('Question 1 & answer'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}
