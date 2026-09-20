import 'dart:io';
import 'dart:typed_data' show Endian;

import 'package:flutter_test/flutter_test.dart';

/// What Google Play refuses a build for, checked here instead of in the
/// console: signing, version, the store's own artwork sizes and the
/// promises the listing makes (§33, §35).
///
/// These are the things that are cheap to break by accident and expensive
/// to find out about from a rejected upload.

/// Width and height from a PNG's IHDR chunk, without decoding the image.
({int width, int height}) _pngSize(File file) {
  final bytes = file.readAsBytesSync().buffer.asByteData();
  return (
    width: bytes.getUint32(16, Endian.big),
    height: bytes.getUint32(20, Endian.big),
  );
}

void main() {
  test('the release build is not signed with the debug key', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    // The template signs release with the debug key. It may stay as the
    // fallback for `flutter run --release`, but only behind key.properties.
    expect(
      gradle.contains('key.properties'),
      isTrue,
      reason:
          'the release signing config must come from android/key.properties',
    );
    expect(
      RegExp(r'release\s*\{\s*\n\s*signingConfig\s*=\s*signingConfigs'
              r'\.getByName\("debug"\)')
          .hasMatch(gradle),
      isFalse,
      reason: 'release must not sign with the debug key unconditionally',
    );
    expect(
      File('android/key.properties').existsSync() ||
          !Platform.environment.containsKey('EMOJIPUZZLE_RELEASE'),
      isTrue,
      reason: 'a real release build needs android/key.properties',
    );
  });

  test('the package id is the published one and says so out loud', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "com.iylabs.emojipuzzle"'));
    expect(gradle, contains('namespace = "com.iylabs.emojipuzzle"'));
    expect(
      gradle.contains('TODO'),
      isFalse,
      reason: 'no template TODOs left in the build file',
    );

    // Changing it after the first upload is impossible, so the id also has
    // to be what the store listing tells the world.
    expect(
      File('docs/store-listing.md').readAsStringSync(),
      contains('com.iylabs.emojipuzzle'),
    );
  });

  test('the version carries a build number Play can order', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*(\S+)', multiLine: true)
        .firstMatch(pubspec)
        ?.group(1);
    expect(version, isNotNull);
    expect(
      RegExp(r'^\d+\.\d+\.\d+\+\d+$').hasMatch(version!),
      isTrue,
      reason: 'a Play upload needs "x.y.z+build", not "$version"',
    );
  });

  test('the store artwork is there, at the sizes Play asks for', () {
    final feature = File('docs/store/feature-graphic-1024x500.png');
    expect(feature.existsSync(), isTrue);
    expect(_pngSize(feature), (width: 1024, height: 500));

    final icon = File('docs/branding/play-store-icon-512.png');
    expect(icon.existsSync(), isTrue);
    expect(_pngSize(icon), (width: 512, height: 512));

    final shots = Directory('docs/store/screenshots')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();
    expect(shots.length, greaterThanOrEqualTo(2), reason: 'Play wants two');
    expect(shots.length, lessThanOrEqualTo(8), reason: 'Play takes eight');
    for (final shot in shots) {
      final size = _pngSize(shot);
      // Play's floor is 320 px on the short side; these are phone shots.
      expect(size.width, greaterThanOrEqualTo(320), reason: shot.path);
      expect(size.height, greaterThan(size.width), reason: 'portrait');
    }
  });

  test('the listing keeps the promises the app has to keep', () {
    final listing = File('docs/store-listing.md').readAsStringSync();

    // §33 — the attribution travels with the artwork.
    expect(listing, contains('OpenMoji'));
    expect(listing, contains('CC BY-SA 4.0'));
    // §35 — Play requires a reachable privacy policy for every app, and a
    // children's app cannot ship without one.
    expect(listing, contains('privacy-policy'));
    expect(File('docs/privacy-policy.md').existsSync(), isTrue);
    // The short description has its own hard limit.
    final short = RegExp(
      r'## Kısa açıklama[^\n]*\n\n(.+)',
    ).firstMatch(listing)?.group(1);
    expect(short, isNotNull);
    expect(
      short!.trim().length,
      lessThanOrEqualTo(80),
      reason: 'Play cuts the short description at 80 characters',
    );
  });

  test('the listing is written in both languages (K-21)', () {
    final listing = File('docs/store-listing.md').readAsStringSync();

    // Play takes one listing per language; English is the second one.
    final english = RegExp(
      r'### Short description[^\n]*\n\n(.+)',
    ).firstMatch(listing)?.group(1);
    expect(english, isNotNull, reason: 'an English listing is expected');
    expect(
      english!.trim().length,
      lessThanOrEqualTo(80),
      reason: 'the English short description has the same 80-character limit',
    );
    expect(listing, contains('English'));

    // The privacy policy is public in both languages too: the store page
    // links one URL for every language.
    final policy = File('docs/privacy-policy.md').readAsStringSync();
    expect(policy, contains('Privacy policy (English)'));
    expect(policy, contains('@'), reason: 'a contact address is required');
  });

  test('both full descriptions fit what Play accepts', () {
    final listing = File('docs/store-listing.md').readAsStringSync();

    /// A section's body: everything up to the next heading of any level.
    String section(String heading) {
      final start = listing.indexOf(heading);
      expect(start, isNot(-1), reason: heading);
      final body = listing.substring(start + heading.length);
      final end = RegExp(r'\n#{2,3} ').firstMatch(body)?.start ?? body.length;
      return body.substring(0, end);
    }

    for (final heading in ['## Uzun açıklama', '### Full description']) {
      final text = section(heading).trim();
      expect(
        text.length,
        lessThanOrEqualTo(4000),
        reason: 'Play cuts a full description at 4000 characters: $heading',
      );
      // K-22 — the listing says what the game exercises; teachers rating a
      // children's app look for it, and it is the honest part to write.
      expect(
        text,
        anyOf(contains('göz koordinasyonu'), contains('Hand-eye')),
        reason: 'the developmental paragraph belongs in $heading',
      );
    }
  });

  test('the app itself carries the maker and a way to reach them (K-21)', () {
    final about =
        File('lib/features/home/screens/about_screen.dart').readAsStringSync();
    expect(about, contains("maker = 'IY Labs'"));
    expect(about, contains('@'));
  });

  test('nothing in the shipped app asks to be seen only in debug', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    // The orientation lock was removed so tablets get the landscape
    // layouts the app already has (§40).
    expect(manifest.contains('screenOrientation'), isFalse);
    expect(manifest.contains('android:debuggable'), isFalse);
  });
}
