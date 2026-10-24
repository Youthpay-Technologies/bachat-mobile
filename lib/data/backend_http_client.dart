import 'dart:async';

import 'package:http/http.dart' as http;

/// Bounds both response headers and body, and cancels stalled network work.
/// Retries remain the SDK's responsibility; this client never replays a write.
class BackendHttpClient extends http.BaseClient {
  BackendHttpClient(this._inner, {this.timeout = const Duration(seconds: 20)});
  final http.Client _inner;
  final Duration timeout;
  final _deadlines = <Timer>{};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final deadline = Completer<void>();
    final timer = Timer(timeout, deadline.complete);
    _deadlines.add(timer);
    final callerAbort = request is http.Abortable ? request.abortTrigger : null;
    final abort = callerAbort == null
        ? deadline.future
        : Future.any<void>([deadline.future, callerAbort]);
    try {
      final response = await _inner.send(_BoundedRequest(request, abort));
      return http.StreamedResponse(
        _readBody(response.stream, timer),
        response.statusCode,
        contentLength: response.contentLength,
        request: request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (_) {
      _cancel(timer);
      rethrow;
    }
  }

  Stream<List<int>> _readBody(Stream<List<int>> stream, Timer timer) async* {
    try {
      yield* stream;
    } finally {
      _cancel(timer);
    }
  }

  void _cancel(Timer timer) {
    timer.cancel();
    _deadlines.remove(timer);
  }

  @override
  void close() {
    for (final timer in _deadlines) {
      timer.cancel();
    }
    _deadlines.clear();
    _inner.close();
  }
}

class _BoundedRequest extends http.BaseRequest with http.Abortable {
  _BoundedRequest(this.original, this.abortTrigger)
    : super(original.method, original.url) {
    followRedirects = original.followRedirects;
    maxRedirects = original.maxRedirects;
    persistentConnection = original.persistentConnection;
    contentLength = original.contentLength;
    headers.addAll(original.headers);
  }
  final http.BaseRequest original;
  @override
  final Future<void> abortTrigger;

  @override
  http.ByteStream finalize() {
    super.finalize();
    final body = original.finalize();
    // Multipart requests may add their boundary header while finalizing.
    headers.addAll(original.headers);
    return body;
  }
}
