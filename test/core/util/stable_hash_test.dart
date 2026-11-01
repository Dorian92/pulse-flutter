import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/util/stable_hash.dart';

void main() {
  test('stableHashHex is deterministic', () {
    expect(
      stableHashHex('bitcoin,ethereum'),
      stableHashHex('bitcoin,ethereum'),
    );
    expect(stableHashHex('a'), isNot(stableHashHex('b')));
  });

  test('stableHashForSortedIds sorts before hashing', () {
    final a = stableHashForSortedIds(['ethereum', 'bitcoin']);
    final b = stableHashForSortedIds(['bitcoin', 'ethereum']);
    expect(a, b);
    expect(a, hasLength(16));
  });
}
