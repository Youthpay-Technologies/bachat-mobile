import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bachat_mobile/data/backend_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  Future<Uri> serve(void Function(HttpRequest) handler) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(handler);
    addTearDown(() => server.close(force: true));
    return Uri.parse('http://127.0.0.1:${server.port}');
  }

  BackendHttpClient client() {
    final client = BackendHttpClient(
      http.Client(),
      timeout: const Duration(seconds: 1),
    );
    addTearDown(client.close);
    return client;
  }

  test('deadline aborts a connection that never returns headers', () async {
    final uri = await serve((_) {});
    await expectLater(
      client().get(uri),
      throwsA(isA<http.RequestAbortedException>()),
    );
  });

  test(
    'deadline remains active after headers while response body stalls',
    () async {
      final uri = await serve((request) {
        request.response.contentLength = 8;
        request.response.add([123]);
        unawaited(request.response.flush());
      });
      await expectLater(
        client().get(uri),
        throwsA(isA<http.RequestAbortedException>()),
      );
    },
  );

  test('callers can still cancel a request before its deadline', () async {
    final received = Completer<void>();
    final uri = await serve((_) => received.complete());
    final abort = Completer<void>();
    final request = http.AbortableRequest(
      'GET',
      uri,
      abortTrigger: abort.future,
    );
    final pending = client().send(request);
    final check = expectLater(
      pending,
      throwsA(isA<http.RequestAbortedException>()),
    );
    await received.future;
    abort.complete();
    await check;
  });

  test(
    'a timed-out request does not close other requests or replay writes',
    () async {
      var posts = 0;
      final uri = await serve((request) {
        if (request.uri.path == '/stall') return;
        posts++;
        expect(request.headers.value('x-fixture'), 'kept');
        unawaited(() async {
          expect(
            await utf8.decoder.bind(request).join(),
            '{"amount_minor":12550}',
          );
          request.response.headers.contentType = ContentType.json;
          request.response.write('{"saved":true}');
          await request.response.close();
        }());
      });
      final transport = client();
      await expectLater(
        transport.get(uri.resolve('/stall')),
        throwsA(isA<http.RequestAbortedException>()),
      );
      final response = await transport.post(
        uri.resolve('/save'),
        headers: {'x-fixture': 'kept', 'content-type': 'application/json'},
        body: '{"amount_minor":12550}',
      );
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body), {'saved': true});
      expect(posts, 1);
    },
  );
}
