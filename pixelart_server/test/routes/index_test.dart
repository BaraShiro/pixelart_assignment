// ignore_for_file: library_prefixes

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelart_server/pixelart_server.dart';
import 'package:pixelart_shared/pixelart_shared.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../../routes/index.dart' as route;
import '../../routes/pixelart/[id]/index.dart' as pixelArtSlugRoute;
import '../../routes/pixelart/[id]/stream/index.dart'
    as pixelArtSlugStreamRoute;
import '../../routes/pixelart/index.dart' as pixelArtRoute;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('HivePixelArtRepository', () {
    final repository = HivePixelArtRepository();
    const testPixelArt = PixelArt(
      id: 'testId',
      name: 'Test Art',
      description: 'This is a test pixel art',
      width: 10,
      height: 10,
      editors: [],
      pixelMatrix: [],
    );

    setUpAll(() async {
      await repository.initialize(collectionName: 'testCollection');
    });

    tearDownAll(() async {
      await repository.destroy();
    });

    test('create and read a PixelArt', () async {
      final createResult = await repository.create(testPixelArt);
      final readResult = await repository.read(testPixelArt.id);
      expect(createResult.isSuccess, isTrue);
      expect(readResult.isSuccess, isTrue);
      expect(readResult.value, testPixelArt);
    });

    test('update a PixelArt', () async {
      await repository.create(testPixelArt);

      final updatedPixelArt = testPixelArt.copyWith(name: 'Updated Name');
      final updateResult =
          await repository.update(testPixelArt.id, updatedPixelArt);
      expect(updateResult.isSuccess, true);
      expect(updateResult.value?.name, 'Updated Name');
    });

    test('delete a PixelArt', () async {
      await repository.create(testPixelArt);

      final deleteResult = await repository.delete(testPixelArt.id);
      expect(deleteResult.isSuccess, true);

      final readResult = await repository.read(testPixelArt.id);
      expect(readResult.status, CRUDStatus.NotFound);
    });

    test('list all PixelArts', () async {
      await repository.create(testPixelArt);

      final listResult = await repository.list();

      expect(listResult.isSuccess, isTrue);
      expect(listResult.value?.length, isPositive);
    });

    test('watch changes on a PixelArt', () async {
      await repository.delete(testPixelArt.id);

      final stream = await repository.changes(testPixelArt.id);

      final changedArt = testPixelArt.copyWith(name: 'streamTestUpdateNewName');
      final changedArt1 =
          testPixelArt.copyWith(name: 'streamTestUpdateNewName1');
      final changedArt2 =
          testPixelArt.copyWith(name: 'streamTestUpdateNewName2');

      expect(
          stream,
          emitsInOrder(
              [testPixelArt, changedArt, changedArt1, changedArt2, null],),);

      await repository.create(testPixelArt);

      await repository.update(testPixelArt.id, changedArt);

      await repository.update(testPixelArt.id, changedArt1);

      await repository.update(testPixelArt.id, changedArt2);

      await repository.delete(testPixelArt.id);

    });
  });

  group('PixelArt API', () {
    final context = _MockRequestContext();
    const uuid = Uuid();

    final art = PixelArt(
      id: uuid.v4(),
      name: uuid.v4(),
      description: uuid.v4(),
      width: 64,
      height: 64,
      editors: [],
      pixelMatrix: [[]],
    );

    final serializedArt = art.serialize();

    final otherArt = PixelArt(
      id: uuid.v4(),
      name: uuid.v4(),
      description: uuid.v4(),
      width: 64,
      height: 64,
      editors: [],
      pixelMatrix: [[]],
    );

    final serializedOtherArt = otherArt.serialize();

    Future<HivePixelArtRepository> initRepo() async {
      final repository = HivePixelArtRepository();
      await repository.initialize(collectionName: 'pixelart_api_test');
      return repository;
    }

    late Future<HivePixelArtRepository> repoFuture;

    setUpAll(() {
      repoFuture = initRepo();
    });

    tearDownAll(() async {
      final repo = await repoFuture;
      await repo.destroy();
    });

    setUp(() async {
      // Reset the mock before each test
      reset(context);
      when(() => context.read<Future<HivePixelArtRepository>>())
          .thenAnswer((_) => repoFuture);
      // Put something to test against in the repo
      final repo = await repoFuture;
      await repo.create(art);
    });

    tearDown(() async {
      // Empty the repo after each test
      final repo = await repoFuture;
      await repo.deleteAll();
    });

    test('GET / - responds with a welcome message', () async {
      final response = route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        response.body(),
        completion(
            contains('This is an API for crating and editing pixel art :-)'),),
      );
    });

    test('POST / - creates a PixelArt', () async {
      when(() => context.request)
          .thenAnswer((e) => Request.post(Uri.base, body: serializedOtherArt));

      final response = await pixelArtRoute.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));
      final responseBody = await response.body();
      expect(responseBody, serializedOtherArt);
    });

    test('GET /:id - reads a PixelArt', () async {
      when(() => context.request)
          .thenAnswer((e) => Request.get(Uri.base, body: art.id));

      final response = await pixelArtSlugRoute.onRequest(context, art.id);
      expect(response.statusCode, equals(HttpStatus.ok));
      final responseBody = await response.body();
      expect(responseBody, serializedArt);
    });

    test('PUT /:id - updates a PixelArt', () async {
      final newArt = art.copyWith(name: uuid.v4());
      final serializedNewArt = newArt.serialize();
      when(() => context.request)
          .thenAnswer((e) => Request.put(Uri.base, body: serializedNewArt));

      final response = await pixelArtSlugRoute.onRequest(context, newArt.id);
      expect(response.statusCode, equals(HttpStatus.ok));
      final responseBody = await response.body();
      expect(responseBody, serializedNewArt);
    });

    test('DELETE /:id - deletes a PixelArt', () async {
      when(() => context.request)
          .thenAnswer((e) => Request.delete(Uri.base, body: art.id));
      final response = await pixelArtSlugRoute.onRequest(context, art.id);
      expect(response.statusCode, equals(HttpStatus.ok));
    });

    test('DELETE /:id - fails to delete non existing', () async {
      when(() => context.request).thenAnswer((e) => Request.delete(Uri.base));
      final response =
          await pixelArtSlugRoute.onRequest(context, 'nonExistingId');
      expect(response.statusCode, equals(HttpStatus.notFound));
    });

    test('GET / - lists all PixelArts', () async {
      when(() => context.request).thenAnswer((e) => Request.get(
            Uri.base,
          ),);

      final response = await pixelArtRoute.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));

      final responseBody = await response.body();

      final responseJson = jsonDecode(responseBody, reviver: (k, v) =>
        (v is String) ? jsonDecode(v) : v,) as List<dynamic>;

      final parsedList = responseJson.map((val) =>
        PixelArt.fromJson(val as Map<String, dynamic>),).toList();

      expect(parsedList, isA<List<PixelArt>>());
    });

    test('GET / - stream returns 404 for invalid ws request', () async {
      when(() => context.request).thenAnswer((e) => Request.get(Uri.base));

      final response = await pixelArtSlugStreamRoute.onRequest(context, art.id);
      expect(response.statusCode, equals(HttpStatus.notFound));
    });
  });
}
