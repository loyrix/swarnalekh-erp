import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/security/data/models/activity_log.dart';
import 'package:swarnbook/features/security/data/security_repository.dart';

void main() {
  group('ActivityLog.fromJson', () {
    test('parses action, entity, user and timestamp', () {
      final log = ActivityLog.fromJson({
        'id': 'log-1',
        'action': 'update',
        'entityType': 'inventory',
        'entityId': 'i1',
        'ipAddress': '10.0.0.1',
        'createdAt': '2026-06-10T09:30:00.000Z',
        'user': {'name': 'Asha', 'role': 'owner'},
      });
      expect(log.id, 'log-1');
      expect(log.action, 'update');
      expect(log.entityType, 'inventory');
      expect(log.userName, 'Asha');
      expect(log.userRole, 'owner');
      expect(log.isBackup, isFalse);
      expect(log.createdAt?.year, 2026);
    });

    test('safe defaults when fields missing', () {
      final log = ActivityLog.fromJson({'id': 'x'});
      expect(log.action, 'activity');
      expect(log.entityType, 'system');
      expect(log.userName, isNull);
      expect(log.createdAt, isNull);
    });

    test('flags backup exports', () {
      final log = ActivityLog.fromJson({'id': 'b', 'action': 'backup_export'});
      expect(log.isBackup, isTrue);
    });
  });

  group('ActivityLogPage.fromJson', () {
    test('parses logs, total and finds the latest backup', () {
      final page = ActivityLogPage.fromJson({
        'total': 2,
        'generatedAt': '2026-06-10T10:00:00.000Z',
        'logs': [
          {'id': 'a', 'action': 'create', 'entityType': 'invoices'},
          {'id': 'b', 'action': 'backup_export', 'entityType': 'backup'},
          'invalid',
        ],
      });
      expect(page.logs, hasLength(2));
      expect(page.total, 2);
      expect(page.latestBackup?.id, 'b');
    });

    test('empty page has no backup', () {
      final page = ActivityLogPage.fromJson(const {});
      expect(page.logs, isEmpty);
      expect(page.latestBackup, isNull);
    });
  });

  group('SecurityQuery', () {
    test('always sends the limit and omits all-filters', () {
      const q = SecurityQuery();
      final params = q.toQueryParameters();
      expect(params['limit'], 50);
      expect(params.containsKey('entityType'), isFalse);
      expect(params.containsKey('action'), isFalse);
      expect(q.hasActiveFilters, isFalse);
    });

    test('includes active filters and trimmed search', () {
      const q = SecurityQuery(
        search: '  ring ',
        entityType: 'inventory',
        action: 'delete',
      );
      final params = q.toQueryParameters();
      expect(params['search'], 'ring');
      expect(params['entityType'], 'inventory');
      expect(params['action'], 'delete');
      expect(q.hasActiveFilters, isTrue);
    });

    test('value equality keys the provider family', () {
      const a = SecurityQuery(entityType: 'invoices');
      final b = const SecurityQuery().copyWith(entityType: 'invoices');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
