class CacheEntry<T> {
  final T value;
  final DateTime savedAt;
  final Duration ttl;

  CacheEntry({
    required this.value,
    required this.savedAt,
    required this.ttl,
  });

  bool get isValid => DateTime.now().difference(savedAt) < ttl;
}
