import 'dart:convert';

/// Reads claims out of a JWT locally, without a round trip.
///
/// Used to refresh an access token *before* it expires, so a returning user sees
/// data immediately instead of a failed request that only then triggers a refresh.
/// This is a UX optimisation only — the server remains the authority on validity,
/// so a token this code cannot parse is simply treated as "needs refresh".
class JwtUtils {
  /// Decodes the payload, or null if [token] is not a well-formed JWT.
  static Map<String, dynamic>? decodePayload(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// UTC expiry of [token], or null if absent/unparseable.
  static DateTime? expiryOf(String? token) {
    final exp = decodePayload(token)?['exp'];
    if (exp is! int) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  }

  /// True if [token] is missing, unreadable, already expired, or expires within
  /// [leeway]. Unreadable tokens count as expiring so the caller refreshes and
  /// lets the server decide, rather than trusting a token it cannot inspect.
  static bool isExpiringSoon(
    String? token, {
    Duration leeway = const Duration(minutes: 5),
  }) {
    final exp = expiryOf(token);
    if (exp == null) return true;
    return DateTime.now().toUtc().add(leeway).isAfter(exp);
  }
}
