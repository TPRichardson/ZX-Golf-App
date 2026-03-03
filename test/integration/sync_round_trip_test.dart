// ignore_for_file: avoid_print
@Tags(['integration'])
library;
// Integration test: live Supabase sync round-trip.
// Requires SUPABASE_TEST_EMAIL and SUPABASE_TEST_PASSWORD in .env.
//
// Run with:
//   dart test test/integration/sync_round_trip_test.dart

import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

/// Load .env file from project root into a map.
Map<String, String> _loadEnv() {
  final file = File('.env');
  if (!file.existsSync()) {
    throw StateError('.env file not found in project root');
  }
  final map = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx < 0) continue;
    map[trimmed.substring(0, idx)] = trimmed.substring(idx + 1);
  }
  return map;
}

void main() {
  SupabaseClient? client;

  setUpAll(() async {
    final env = _loadEnv();

    final url = env['SUPABASE_URL'];
    final anonKey = env['SUPABASE_ANON_KEY'];
    final email = env['SUPABASE_TEST_EMAIL'];
    final password = env['SUPABASE_TEST_PASSWORD'];

    if (url == null || url.isEmpty) fail('SUPABASE_URL not set in .env');
    if (anonKey == null || anonKey.isEmpty) {
      fail('SUPABASE_ANON_KEY not set in .env');
    }
    if (email == null || email.isEmpty) {
      fail('SUPABASE_TEST_EMAIL not set in .env');
    }
    if (password == null || password.isEmpty) {
      fail('SUPABASE_TEST_PASSWORD not set in .env');
    }

    // Use SupabaseClient directly (no Flutter plugins required).
    client = SupabaseClient(url, anonKey);

    // Authenticate with test user.
    print('\n--- Authenticating as $email ---');
    final authResponse = await client!.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final userId = authResponse.user?.id;
    if (userId == null) fail('Authentication failed: no user ID returned');
    print('Authenticated. UserID: $userId');
  });

  tearDownAll(() async {
    if (client != null) {
      await client!.auth.signOut();
      client!.dispose();
      print('--- Signed out ---\n');
    }
  });

  test('sync round-trip: upload PracticeBlock/Session/Set/Instance, '
      'download and verify', () async {
    final c = client!;
    final uuid = const Uuid();
    final userId = c.auth.currentUser!.id;
    final now = DateTime.now().toUtc();
    final nowIso = now.toIso8601String();

    // Generate unique IDs for this test run.
    final practiceBlockId = uuid.v4();
    final sessionId = uuid.v4();
    final setId = uuid.v4();
    final instanceId = uuid.v4();
    final clubId = uuid.v4();

    // Use a known system drill. Query one from seed data.
    print('\n--- Fetching a system drill for FK reference ---');
    final drillRows =
        await c.from('Drill').select('"DrillID"').limit(1);
    if ((drillRows as List).isEmpty) {
      fail('No drills found in Drill table. Has seed data been loaded?');
    }
    final drillId = drillRows[0]['DrillID'] as String;
    print('Using DrillID: $drillId');

    // === UPLOAD PHASE 1: User + UserClub (must exist before Instance FK) ===
    print('\n--- Upload phase 1: User + UserClub ---');
    final setupResponse = await c.rpc('sync_upload', params: {
      'schema_version': '1',
      'device_id': 'integration-test-device',
      'changes': {
        'User': [
          {
            'UserID': userId,
            'DisplayName': 'Integration Test User',
            'Email': c.auth.currentUser!.email,
            'Timezone': 'UTC',
            'WeekStartDay': 1,
            'UnitPreferences': {},
            'CreatedAt': nowIso,
            'UpdatedAt': nowIso,
          }
        ],
        'UserClub': [
          {
            'ClubID': clubId,
            'UserID': userId,
            'ClubType': 'i7',
            'Make': 'Test',
            'Model': 'Integration',
            'Loft': 34.0,
            'Status': 'Active',
            'CreatedAt': nowIso,
            'UpdatedAt': nowIso,
          }
        ],
      },
    });
    print('Setup response: ${jsonEncode(setupResponse)}');
    expect(setupResponse['success'], isTrue,
        reason: 'Setup upload failed: ${setupResponse['error_message']}');

    // === UPLOAD PHASE 2: Practice data ===
    print('\n--- Upload phase 2: PracticeBlock/Session/Set/Instance ---');
    final payload = {
      'PracticeBlock': [
        {
          'PracticeBlockID': practiceBlockId,
          'UserID': userId,
          'SourceRoutineID': null,
          'DrillOrder': [drillId],
          'StartTimestamp': nowIso,
          'EndTimestamp': null,
          'ClosureType': null,
          'IsDeleted': false,
          'CreatedAt': nowIso,
          'UpdatedAt': nowIso,
        }
      ],
      'Session': [
        {
          'SessionID': sessionId,
          'DrillID': drillId,
          'PracticeBlockID': practiceBlockId,
          'CompletionTimestamp': null,
          'Status': 'Active',
          'IntegrityFlag': false,
          'IntegritySuppressed': false,
          'UserDeclaration': null,
          'SessionDuration': null,
          'IsDeleted': false,
          'CreatedAt': nowIso,
          'UpdatedAt': nowIso,
        }
      ],
      'Set': [
        {
          'SetID': setId,
          'SessionID': sessionId,
          'SetIndex': 1,
          'IsDeleted': false,
          'CreatedAt': nowIso,
          'UpdatedAt': nowIso,
        }
      ],
      'Instance': [
        {
          'InstanceID': instanceId,
          'SetID': setId,
          'SelectedClub': clubId,
          'RawMetrics': {'hitRate': 0.7, 'totalAttempts': 10, 'totalHits': 7},
          'Timestamp': nowIso,
          'ResolvedTargetDistance': 150.0,
          'ResolvedTargetWidth': 20.0,
          'ResolvedTargetDepth': 10.0,
          'IsDeleted': false,
          'CreatedAt': nowIso,
          'UpdatedAt': nowIso,
        }
      ],
    };

    final uploadResponse = await c.rpc('sync_upload', params: {
      'schema_version': '1',
      'device_id': 'integration-test-device',
      'changes': payload,
    });

    print('Upload response: ${jsonEncode(uploadResponse)}');
    expect(uploadResponse['success'], isTrue,
        reason: 'Upload failed: ${uploadResponse['error_message']}');
    expect(uploadResponse['rejected_rows'], isEmpty,
        reason: 'Some rows were rejected: ${uploadResponse['rejected_rows']}');
    print('Upload succeeded. Server timestamp: '
        '${uploadResponse['server_timestamp']}');

    // === DOWNLOAD ===
    // Use a timestamp before our upload to ensure we get our data back.
    final beforeUpload =
        now.subtract(const Duration(seconds: 10)).toIso8601String();
    print('\n--- Downloading since $beforeUpload ---');

    final downloadResponse = await c.rpc('sync_download', params: {
      'schema_version': '1',
      'last_sync_timestamp': beforeUpload,
    });

    print('Download success: ${downloadResponse['success']}');
    expect(downloadResponse['success'], isTrue,
        reason: 'Download failed: ${downloadResponse['error_message']}');

    final changes = downloadResponse['changes'] as Map<String, dynamic>;
    print('Tables in download: ${changes.keys.toList()}');

    // === VERIFY PracticeBlock ===
    final blocks = changes['PracticeBlock'] as List?;
    expect(blocks, isNotNull, reason: 'PracticeBlock not in download');
    final block = (blocks!).firstWhere(
      (b) => b['PracticeBlockID'] == practiceBlockId,
      orElse: () => null,
    );
    expect(block, isNotNull,
        reason: 'Uploaded PracticeBlock not found in download');
    expect(block['UserID'], userId);
    print('PracticeBlock verified: $practiceBlockId');

    // === VERIFY Session ===
    final sessions = changes['Session'] as List?;
    expect(sessions, isNotNull, reason: 'Session not in download');
    final session = (sessions!).firstWhere(
      (s) => s['SessionID'] == sessionId,
      orElse: () => null,
    );
    expect(session, isNotNull,
        reason: 'Uploaded Session not found in download');
    expect(session['DrillID'], drillId);
    expect(session['PracticeBlockID'], practiceBlockId);
    print('Session verified: $sessionId');

    // === VERIFY Set ===
    final sets = changes['Set'] as List?;
    expect(sets, isNotNull, reason: 'Set not in download');
    final set_ = (sets!).firstWhere(
      (s) => s['SetID'] == setId,
      orElse: () => null,
    );
    expect(set_, isNotNull,
        reason: 'Uploaded Set not found in download');
    expect(set_['SessionID'], sessionId);
    expect(set_['SetIndex'], 1);
    print('Set verified: $setId');

    // === VERIFY Instance ===
    final instances = changes['Instance'] as List?;
    expect(instances, isNotNull, reason: 'Instance not in download');
    final instance = (instances!).firstWhere(
      (i) => i['InstanceID'] == instanceId,
      orElse: () => null,
    );
    expect(instance, isNotNull,
        reason: 'Uploaded Instance not found in download');
    expect(instance['SetID'], setId);
    expect(instance['SelectedClub'], clubId);
    final rawMetrics = instance['RawMetrics'] is String
        ? jsonDecode(instance['RawMetrics'] as String)
        : instance['RawMetrics'];
    expect(rawMetrics['hitRate'], 0.7);
    expect(rawMetrics['totalAttempts'], 10);
    expect(rawMetrics['totalHits'], 7);
    expect((instance['ResolvedTargetDistance'] as num).toDouble(), 150.0);
    print('Instance verified: $instanceId');

    print('\n=== SYNC ROUND-TRIP TEST PASSED ===\n');
  });
}
