import 'package:firebase/firebase.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

const TEST_URL = 'https://dart-test.firebaseio-demo.com/test/';

// Update TEST_URL to a valid URL and update AUTH_KEY to a corresponding
// key to test authentication.
const AUTH_KEY = null;

const INVALID_TOKEN = 'xbKOOdkZDBExtKM3sZw6gWtFpGgqMkMidXCiAFjm';

final _now = new DateTime.now().toUtc();
final _dateKey = _now.toIso8601String();

final _replaceRegExp = new RegExp(r'[\.]');

final _testKey = '$_dateKey'.replaceAll(_replaceRegExp, '_');

final _testUrl = TEST_URL + _testKey + '/';

void main() {
  useHtmlConfiguration();

  Firebase f;

  setUp(() {
    f = new Firebase(_testUrl);
  });

  tearDown(() {
    if (f != null) {
      f.unauth();
      f = null;
    }
  });

  group('auth', () {

    test('bad auth should fail', () {
      expect(f.auth(INVALID_TOKEN), throwsA((error) {
        expect(error['code'], 'INVALID_TOKEN');
        return true;
      }));
    });

    if (AUTH_KEY != null) {
      test('good auth key', () {
        return f.auth(AUTH_KEY);
      });
    }
  });

  group('non-auth', () {
    test('child', () {
      var child = f.child('trad');
      expect(child.name, 'trad');

      var parent = child.parent();
      expect(parent.name, _testKey);

      var root = child.root();
      expect(root.name, isNull);
    });

    test('set', () {
      var value = {'number value': _now.millisecond};
      return f.set(value).then((v) {
        // TODO: check the value?
      });
    });

    test('set string', () {
      var child = f.child('bar');
      return child.set('foo').then((foo) {
        // TODO: actually test result
      });
    });

    test('update', () {
      // TODO: not sure why this works and the string case does not
      return f.update({'update_works': 'oof'}).then((foo) {
        // TODO: actually test the result
      });
    });

    test('push', () {
      // TODO: actually validate the result
      var pushRef = f.push();
      return pushRef.set('HAHA');
    });

    test('priorities', () {
      // TODO: actually validate the result
      var testRef = f.child('ZZZ');
      return testRef.setWithPriority(1, 1).then((foo) {
        return testRef.setPriority(100);
      });
    });

    test('value', () {
      return f.onValue.first.then((Event e) {
        //TODO actually test the result
      });
    });
  });

  group('once', () {
    test('set a value and get', () {
      var testRef = f.child('once');

      testRef.once('child_added').then(expectAsync((value) {
        var ds = value as DataSnapshot;
        expect(ds.hasChildren, false);
        expect(ds.numChildren, 0);
        expect(ds.name, 'a');
        expect(ds.val(), 'b');
      }));

      return testRef.set({'a': 'b'});
    });

  });

  group('transaction', () {
    test('simple value, nothing exists', () {
      var testRef = f.child('tx1');
      return testRef.transaction((curVal) {
        expect(curVal, isNull);
        return 42;
      }).then((result) {
        expect(result.committed, isTrue);
        expect(result.error, isNull);

        var snapshot = result.snapshot;
        expect(snapshot.hasChildren, false);
        expect(snapshot.numChildren, 0);
        expect(snapshot.val(), 42);
      });
    });

    test('complex value, nothing exists', () {
      var value = const {'int': 42, 'bool': true, 'str': 'string'};
      var testRef = f.child('tx2');
      return testRef.transaction((curVal) {
        expect(curVal, isNull);
        return value;
      }).then((result) {
        expect(result.committed, isTrue);
        expect(result.error, isNull);

        var snapshot = result.snapshot;
        expect(snapshot.hasChildren, true);
        expect(snapshot.numChildren, 3);
        expect(snapshot.val(), value);
      });
    });

    // TODO: transactions seem to be broken - does not send existing value
    skip_test('simple value, existing value', () {
      var testRef = f.child('tx3');
      return testRef.set(42).then((_) {
        return testRef.transaction((curVal) {
          expect(curVal, 42);
          return 42;
        });
      }).then((result) {
        expect(result.committed, isTrue);
        expect(result.error, isNull);

        var snapshot = result.snapshot;
        expect(snapshot.hasChildren, false);
        expect(snapshot.numChildren, 0);
        expect(snapshot.val(), null);
      });
    });
  });
}
