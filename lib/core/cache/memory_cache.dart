import '../config/app_config.dart';
import 'cache_entry.dart';

class MemoryCache {
  MemoryCache._();

  static final MemoryCache instance = MemoryCache._();

  final Duration defaultTtl = const Duration(minutes: 10);
  final Map<String, CacheEntry<dynamic>> _store = {};
  String? _activeCountry;

  void ensureCountry(AppCountry country) {
    final code = country.name;
    if (_activeCountry == null) {
      _activeCountry = code;
      return;
    }
    if (_activeCountry != code) {
      clear();
      _activeCountry = code;
    }
  }

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (!entry.isValid) {
      _store.remove(key);
      return null;
    }
    final value = entry.value;
    if (value is T) return value;
    return null;
  }

  void set<T>(String key, T value, {Duration? ttl}) {
    _store[key] = CacheEntry<T>(
      value: value,
      savedAt: DateTime.now(),
      ttl: ttl ?? defaultTtl,
    );
  }

  void clear() => _store.clear();
}
