import 'dart:convert';

/// FNV-1a 64-bit digest rendered as fixed-width hex (stable across VM runs).
String stableHashHex(String input) {
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(input)) {
    hash ^= byte;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

/// Hash for a sorted list of CoinGecko ids (cache keys).
String stableHashForSortedIds(List<String> ids) {
  final sorted = [...ids]..sort();
  return stableHashHex(sorted.join(','));
}
