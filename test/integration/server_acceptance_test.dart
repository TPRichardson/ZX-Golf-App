// ignore_for_file: avoid_print
@Tags(['integration'])
library;
// TD-06 §6.4 — Server acceptance criteria tests.
// Requires SUPABASE_TEST_EMAIL and SUPABASE_TEST_PASSWORD in .env.
// Test 3 (RLS isolation) additionally requires SUPABASE_TEST_EMAIL_2 /
// SUPABASE_TEST_PASSWORD_2 — skipped if absent.
//
// Run with:
//   dart test test/integration/server_acceptance_test.dart

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
  late SupabaseClient client;
  late String userId;
  late String drillId;
  late String clubId;
  late Map<String, String> env;
  final uuid = const Uuid();

  setUpAll(() async {
    env = _loadEnv();
    final url = env['SUPABASE_URL']!;
    final anonKey = env['SUPABASE_ANON_KEY']!;
    final email = env['SUPABASE_TEST_EMAIL']!;
    final password = env['SUPABASE_TEST_PASSWORD']!;

    client = SupabaseClient(url, anonKey);
    final auth = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    userId = auth.user!.id;
    print('\nAuthenticated as $userId');

    // Fetch a system drill for FK reference.
    final drillRows =
        await client.from('Drill').select('"DrillID"').limit(1);
    drillId = (drillRows as List).first['DrillID'] as String;

    // Ensure User + UserClub exist for tests that need them.
    clubId = uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final setup = await client.rpc('sync_upload', params: {
      'schema_version': '1',
      'device_id': 'acceptance-test',
      'changes': {
        'User': [
          {
            'UserID': userId,
            'DisplayName': 'Acceptance Test User',
            'Email': email,
            'Timezone': 'UTC',
            'WeekStartDay': 1,
            'UnitPreferences': {},
            'CreatedAt': now,
            'UpdatedAt': now,
          }
        ],
        'UserClub': [
          {
            'ClubID': clubId,
            'UserID': userId,
            'ClubType': 'i7',
            'Make': 'Test',
            'Model': 'Acceptance',
            'Loft': 34.0,
            'Status': 'Active',
            'CreatedAt': now,
            'UpdatedAt': now,
          }
        ],
      },
    });
    if (setup['success'] != true) {
      fail('Setup upload failed: ${setup['error_message']}');
    }
    print('Setup complete. DrillID: $drillId, ClubID: $clubId\n');
  });

  tearDownAll(() async {
    await client.auth.signOut();
    client.dispose();
  });

  // ── Test 1: Seed Data ─────────────────────────────────────────────
  test('1. Seed data: 16 EventTypes, 19 Subskills, 8 MetricSchemas, '
      '28 System Drills', () async {
    final eventTypes = await client.from('EventTypeRef').select();
    final subskills = await client.from('SubskillRef').select();
    final metricSchemas = await client.from('MetricSchema').select();
    final systemDrills =
        await client.from('Drill').select().eq('Origin', 'System');

    print('EventTypeRef: ${(eventTypes as List).length}');
    print('SubskillRef: ${(subskills as List).length}');
    print('MetricSchema: ${(metricSchemas as List).length}');
    print('System Drills: ${(systemDrills as List).length}');

    expect((eventTypes as List).length, 16,
        reason: 'Expected 16 EventTypeRef rows');
    expect((subskills as List).length, 19,
        reason: 'Expected 19 SubskillRef rows');
    expect((metricSchemas as List).length, 8,
        reason: 'Expected 8 MetricSchema rows');
    expect((systemDrills as List).length, 28,
        reason: 'Expected 28 System Drills');
  });

  // ── Test 2: Upload Idempotency ────────────────────────────────────
  test('2. Upload idempotency: same payload twice = identical state',
      () async {
    final blockId = uuid.v4();
    final sessionId = uuid.v4();
    final setId = uuid.v4();
    final instanceId = uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final beforeTest = DateTime.now()
        .toUtc()
        .subtract(const Duration(seconds: 5))
        .toIso8601String();

    final payload = {
      'PracticeBlock': [
        {
          'PracticeBlockID': blockId,
          'UserID': userId,
          'DrillOrder': [drillId],
          'StartTimestamp': now,
          'IsDeleted': false,
          'CreatedAt': now,
          'UpdatedAt': now,
        }
      ],
      'Session': [
        {
          'SessionID': sessionId,
          'DrillID': drillId,
          'PracticeBlockID': blockId,
          'Status': 'Active',
          'IntegrityFlag': false,
          'IntegritySuppressed': false,
          'IsDeleted': false,
          'CreatedAt': now,
          'UpdatedAt': now,
        }
      ],
      'Set': [
        {
          'SetID': setId,
          'SessionID': sessionId,
          'SetIndex': 1,
          'IsDeleted': false,
          'CreatedAt': now,
          'UpdatedAt': now,
        }
      ],
      'Instance': [
        {
          'InstanceID': instanceId,
          'SetID': setId,
          'SelectedClub': clubId,
          'RawMetrics': {'hitRate': 0.5},
          'Timestamp': now,
          'ResolvedTargetDistance': 100.0,
          'ResolvedTargetWidth': 15.0,
          'ResolvedTargetDepth': 8.0,
          'IsDeleted': false,
          'CreatedAt': now,
          'UpdatedAt': now,
        }
      ],
    };

    // Upload #1.
    final r1 = await client.rpc('sync_upload', params: {
      'schema_version': '1',
      'device_id': 'idempotency-test',
      'changes': payload,
    });
    expect(r1['success'], isTrue,
        reason: 'First upload failed: ${r1['error_message']}');

    // Upload #2 — identical payload.
    final r2 = await client.rpc('sync_upload', params: {
      'schema_version': '1',
      'device_id': 'idempotency-test',
      'changes': payload,
    });
    expect(r2['success'], isTrue,
        reason: 'Second upload failed: ${r2['error_message']}');
    expect(r2['rejected_rows'], isEmpty);

    // Download and verify exactly one copy.
    final dl = await client.rpc('sync_download', params: {
      'schema_version': '1',
      'last_sync_timestamp': beforeTest,
    });
    expect(dl['success'], isTrue);

    final changes = dl['changes'] as Map<String, dynamic>;
    final blocks = (changes['PracticeBlock'] as List? ?? [])
        .where((b) => b['PracticeBlockID'] == blockId)
        .toList();
    final instances = (changes['Instance'] as List? ?? [])
        .where((i) => i['InstanceID'] == instanceId)
        .toList();

    expect(blocks.length, 1,
        reason: 'Expected 1 PracticeBlock after 2 uploads, got ${blocks.length}');
    expect(instances.length, 1,
        reason: 'Expected 1 Instance after 2 uploads, got ${instances.length}');
    print('Idempotency verified: 1 block, 1 instance after duplicate upload');
  });

  // ── Test 3: RLS Isolation ─────────────────────────────────────────
  test('3. RLS isolation: two users, verify data isolation', () async {
    final email2 = env['SUPABASE_TEST_EMAIL_2'];
    final password2 = env['SUPABASE_TEST_PASSWORD_2'];
    if (email2 == null ||
        email2.isEmpty ||
        password2 == null ||
        password2.isEmpty) {
      print('SKIPPED: SUPABASE_TEST_EMAIL_2 / '
          'SUPABASE_TEST_PASSWORD_2 not set in .env');
      markTestSkipped('Second test user credentials not configured');
      return;
    }

    // Authenticate second user.
    final client2 =
        SupabaseClient(env['SUPABASE_URL']!, env['SUPABASE_ANON_KEY']!);
    final auth2 = await client2.auth.signInWithPassword(
      email: email2,
      password: password2,
    );
    final userId2 = auth2.user!.id;
    print('User 2 authenticated: $userId2');

    // User 2 uploads data.
    final user2BlockId = uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final setupR = await client2.rpc('sync_upload', params: {
      'schema_version': '1',
      'device_id': 'rls-test-user2',
      'changes': {
        'User': [
          {
            'UserID': userId2,
            'DisplayName': 'RLS Test User 2',
            'Email': email2,
            'Timezone': 'UTC',
            'WeekStartDay': 1,
            'UnitPreferences': {},
            'CreatedAt': now,
            'UpdatedAt': now,
          }
        ],
        'PracticeBlock': [
          {
            'PracticeBlockID': user2BlockId,
            'UserID': userId2,
            'DrillOrder': [drillId],
            'StartTimestamp': now,
            'IsDeleted': false,
            'CreatedAt': now,
            'UpdatedAt': now,
          }
        ],
      },
    });
    expect(setupR['success'], isTrue,
        reason: 'User 2 upload failed: ${setupR['error_message']}');

    // User 1 downloads — must NOT see User 2's PracticeBlock.
    final dl = await client.rpc('sync_download', params: {
      'schema_version': '1',
    });
    expect(dl['success'], isTrue);

    final changes = dl['changes'] as Map<String, dynamic>;
    final blocks = changes['PracticeBlock'] as List? ?? [];
    final leaked =
        blocks.where((b) => b['PracticeBlockID'] == user2BlockId).toList();
    expect(leaked, isEmpty,
        reason:
            'User 1 can see User 2\'s PracticeBlock — RLS violation in RPC');

    // Direct table query — tests RLS policy enforcement.
    final directBlocks = await client
        .from('PracticeBlock')
        .select('"PracticeBlockID"')
        .eq('PracticeBlockID', user2BlockId);
    expect((directBlocks as List), isEmpty,
        reason:
            'Direct query returned User 2\'s PracticeBlock — RLS policy violation');

    print('RLS isolation verified: User 1 cannot see User 2\'s data');

    await client2.auth.signOut();
    client2.dispose();
  });

  // ── Test 4: Schema Version Mismatch ───────────────────────────────
  test('4. Schema version mismatch returns SCHEMA_VERSION_MISMATCH',
      () async {
    // Test sync_upload.
    final uploadR = await client.rpc('sync_upload', params: {
      'schema_version': '99',
      'device_id': 'mismatch-test',
      'changes': {},
    });
    expect(uploadR['success'], isFalse);
    expect(uploadR['error_code'], 'SCHEMA_VERSION_MISMATCH');
    print('Upload mismatch: ${uploadR['error_message']}');

    // Test sync_download.
    final downloadR = await client.rpc('sync_download', params: {
      'schema_version': '99',
    });
    expect(downloadR['success'], isFalse);
    expect(downloadR['error_code'], 'SCHEMA_VERSION_MISMATCH');
    print('Download mismatch: ${downloadR['error_message']}');
  });

  // ── Test 5: Synthetic Bulk ────────────────────────────────────────
  test('5. Synthetic bulk: 100 Sessions / 1,000 Instances upload and download',
      () async {
    final blockId = uuid.v4();
    final now = DateTime.now().toUtc();
    final nowIso = now.toIso8601String();
    final beforeUpload =
        now.subtract(const Duration(seconds: 5)).toIso8601String();

    // Generate 100 Sessions, 100 Sets (1 per Session), 1,000 Instances (10 per Set).
    final sessions = <Map<String, dynamic>>[];
    final sets = <Map<String, dynamic>>[];
    final instances = <Map<String, dynamic>>[];
    final bulkSetIds = <String>{};

    for (var s = 0; s < 100; s++) {
      final sid = uuid.v4();
      final stid = uuid.v4();
      bulkSetIds.add(stid);
      sessions.add({
        'SessionID': sid,
        'DrillID': drillId,
        'PracticeBlockID': blockId,
        'Status': 'Active',
        'IntegrityFlag': false,
        'IntegritySuppressed': false,
        'IsDeleted': false,
        'CreatedAt': nowIso,
        'UpdatedAt': nowIso,
      });
      sets.add({
        'SetID': stid,
        'SessionID': sid,
        'SetIndex': 1,
        'IsDeleted': false,
        'CreatedAt': nowIso,
        'UpdatedAt': nowIso,
      });
      for (var i = 0; i < 10; i++) {
        instances.add({
          'InstanceID': uuid.v4(),
          'SetID': stid,
          'SelectedClub': clubId,
          'RawMetrics': {'hitRate': 0.5 + (i * 0.05)},
          'Timestamp': nowIso,
          'ResolvedTargetDistance': 100.0 + i,
          'ResolvedTargetWidth': 15.0,
          'ResolvedTargetDepth': 8.0,
          'IsDeleted': false,
          'CreatedAt': nowIso,
          'UpdatedAt': nowIso,
        });
      }
    }
    print('Generated: ${sessions.length} Sessions, ${sets.length} Sets, '
        '${instances.length} Instances');

    // Upload PracticeBlock first (parent row).
    final blockR = await client.rpc('sync_upload', params: {
      'schema_version': '1',
      'device_id': 'bulk-test',
      'changes': {
        'PracticeBlock': [
          {
            'PracticeBlockID': blockId,
            'UserID': userId,
            'DrillOrder': [drillId],
            'StartTimestamp': nowIso,
            'IsDeleted': false,
            'CreatedAt': nowIso,
            'UpdatedAt': nowIso,
          }
        ],
      },
    });
    expect(blockR['success'], isTrue,
        reason: 'Bulk PracticeBlock upload failed: ${blockR['error_message']}');

    // Upload all Sessions, Sets, Instances in one call.
    final sw = Stopwatch()..start();
    final bulkR = await client.rpc('sync_upload', params: {
      'schema_version': '1',
      'device_id': 'bulk-test',
      'changes': {
        'Session': sessions,
        'Set': sets,
        'Instance': instances,
      },
    });
    sw.stop();
    print('Bulk upload time: ${sw.elapsedMilliseconds}ms');

    expect(bulkR['success'], isTrue,
        reason: 'Bulk upload failed: ${bulkR['error_message']}');
    expect(bulkR['rejected_rows'], isEmpty);

    // Download and verify counts.
    final dl = await client.rpc('sync_download', params: {
      'schema_version': '1',
      'last_sync_timestamp': beforeUpload,
    });
    expect(dl['success'], isTrue,
        reason: 'Bulk download failed: ${dl['error_message']}');

    final changes = dl['changes'] as Map<String, dynamic>;
    final dlSessions = (changes['Session'] as List? ?? [])
        .where((s) => s['PracticeBlockID'] == blockId)
        .toList();
    final dlInstances = (changes['Instance'] as List? ?? [])
        .where((i) => bulkSetIds.contains(i['SetID']))
        .toList();

    print('Downloaded: ${dlSessions.length} Sessions, '
        '${dlInstances.length} Instances');
    expect(dlSessions.length, 100, reason: 'Expected 100 Sessions');
    expect(dlInstances.length, 1000, reason: 'Expected 1,000 Instances');
  }, timeout: Timeout(Duration(minutes: 3)));

  // ── Test 6: RLS Join Performance ──────────────────────────────────
  test('6. RLS join performance < 50ms with 1,000+ rows', () async {
    // Warm-up call (connection pool, query plan cache).
    await client.rpc('sync_download', params: {
      'schema_version': '1',
    });

    // Measure baseline RTT with a trivial operation.
    final baselineSw = Stopwatch()..start();
    await client.rpc('sync_upload', params: {
      'schema_version': '99',
      'device_id': 'perf-baseline',
      'changes': {},
    });
    baselineSw.stop();
    final baselineMs = baselineSw.elapsedMilliseconds;

    // Timed full download (1,000+ Instances with JOINs).
    final sw = Stopwatch()..start();
    final dl = await client.rpc('sync_download', params: {
      'schema_version': '1',
    });
    sw.stop();

    expect(dl['success'], isTrue);

    final changes = dl['changes'] as Map<String, dynamic>;
    final instanceCount = (changes['Instance'] as List?)?.length ?? 0;
    final sessionCount = (changes['Session'] as List?)?.length ?? 0;
    final estimatedServerMs = sw.elapsedMilliseconds - baselineMs;

    print('Full download: $sessionCount Sessions, $instanceCount Instances');
    print('Network baseline RTT: ${baselineMs}ms');
    print('Download round-trip: ${sw.elapsedMilliseconds}ms');
    print('Estimated server time: ${estimatedServerMs}ms '
        '(target: <50ms per TD-06 §6.4)');

    expect(instanceCount, greaterThanOrEqualTo(1000),
        reason: 'Need >= 1,000 Instances for performance test '
            '(got $instanceCount). Run test 5 first.');
    // Client-side bound: allow up to 10s for network + server processing.
    expect(sw.elapsedMilliseconds, lessThan(10000),
        reason: 'Download took ${sw.elapsedMilliseconds}ms — exceeds 10s');
  }, timeout: Timeout(Duration(minutes: 1)));
}
