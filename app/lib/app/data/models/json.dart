/// Small, null-safe readers for API JSON (numbers may arrive as int or double).
typedef Json = Map<String, dynamic>;

int asInt(Object? value, [int fallback = 0]) => value is num ? value.toInt() : fallback;

int? asIntOrNull(Object? value) => value is num ? value.toInt() : null;

double asDouble(Object? value, [double fallback = 0]) => value is num ? value.toDouble() : fallback;

DateTime? asDate(Object? value) => value is String ? DateTime.tryParse(value) : null;

List<Json> asJsonList(Object? value) =>
    value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

Json asJson(Object? value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
