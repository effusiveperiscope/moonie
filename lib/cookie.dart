import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:rhttp/rhttp.dart';

// Dart's cookie handling disallows spaces even though many websites use them (violates RFC 6265)
// This is the workaround: Using an http client that doesn't support cookies
// The other http client is in the standard library so is very hard to modify/monkeypatch

class RhttpClientAdapter implements HttpClientAdapter {
  RhttpClientAdapter();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final requestUri = options.uri;

    HttpHeaders headers = HttpHeaders.rawMap(options.headers.map(
      (k, v) => MapEntry(k, v),
    ));

    final response = await Rhttp.get(requestUri.toString(), headers: headers);
    return ResponseBody.fromString(response.body, response.statusCode);
  }

  @override
  void close({bool force = false}) {}
}

Dio myDio() {
  final dio = Dio();
  dio.httpClientAdapter = RhttpClientAdapter();
  return dio;
}
