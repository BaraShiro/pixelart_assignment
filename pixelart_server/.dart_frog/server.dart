// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/index.dart' as index;
import '../routes/pixelart/index.dart' as pixelart_index;
import '../routes/pixelart/[id]/index.dart' as pixelart_$id_index;
import '../routes/pixelart/[id]/stream/index.dart' as pixelart_$id_stream_index;

import '../routes/pixelart/_middleware.dart' as pixelart_middleware;

void main() async {
  final address = InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return serve(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..mount('/pixelart/<id>/stream', (context,id,) => buildPixelart$idStreamHandler(id,)(context))
    ..mount('/pixelart/<id>', (context,id,) => buildPixelart$idHandler(id,)(context))
    ..mount('/pixelart', (context) => buildPixelartHandler()(context))
    ..mount('/', (context) => buildHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildPixelart$idStreamHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(pixelart_middleware.middleware);
  final router = Router()
    ..all('/', (context) => pixelart_$id_stream_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildPixelart$idHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(pixelart_middleware.middleware);
  final router = Router()
    ..all('/', (context) => pixelart_$id_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildPixelartHandler() {
  final pipeline = const Pipeline().addMiddleware(pixelart_middleware.middleware);
  final router = Router()
    ..all('/', (context) => pixelart_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

