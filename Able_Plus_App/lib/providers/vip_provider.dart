import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


/// Demo VIP is persisted only as an active subscription period.
/// Card fields entered in the presentation form never leave the device.
class VipStatus {
  final String providerId;
  final String providerType;
  final DateTime expiresAt;

  const VipStatus({
    required this.providerId,
    required this.providerType,
    required this.expiresAt,
  });

  bool get isActive => expiresAt.isAfter(DateTime.now().toUtc());
  String get key => '$providerType:$providerId';
}

String vipKey(String role, String id) => '$role:$id';

/// One bulk subscription read for any screen containing multiple providers.
/// This prevents an additional query for every post/card.
final activeVipProvidersProvider =
    FutureProvider.autoDispose<Map<String, VipStatus>>((ref) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now().toUtc().toIso8601String();
  late final List<dynamic> rows;
  try {
    rows = await supabase
        .from('vip_subscriptions')
        .select('tutor_id, business_id, charity_id, expires_at')
        .eq('status', 'active')
        .gt('expires_at', now);
  } catch (_) {
    // Keep the existing app usable before the optional demo VIP migration is
    // applied. Activation still shows the SQL error visibly on the payment page.
    return <String, VipStatus>{};
  }

  final result = <String, VipStatus>{};
  for (final raw in rows) {
    final row = raw as Map<String, dynamic>;
    final expires = DateTime.tryParse(row['expires_at']?.toString() ?? '');
    if (expires == null) continue;

    for (final entry in <String, dynamic>{
      'tutor': row['tutor_id'],
      'business': row['business_id'],
      'charity': row['charity_id'],
    }.entries) {
      if (entry.value == null) continue;
      final status = VipStatus(
        providerId: entry.value.toString(),
        providerType: entry.key,
        expiresAt: expires.toUtc(),
      );
      result[status.key] = status;
    }
  }
  return result;
});

final currentVipStatusProvider = FutureProvider.autoDispose<VipStatus?>((ref) async {
  final supabase = Supabase.instance.client;
  if (supabase.auth.currentUser == null) return null;
  final rows = await supabase.rpc('current_viewer');
  if (rows is! List || rows.isEmpty) return null;
  final row = rows.first as Map<String, dynamic>;
  final role = row['account_type']?.toString() ?? 'client';
  final id = row['id']?.toString() ?? '';
  if (role == 'client' || id.isEmpty) return null;
  final active = await ref.watch(activeVipProvidersProvider.future);
  return active[vipKey(role, id)];
});

class VipActivationResult {
  final DateTime startedAt;
  final DateTime expiresAt;

  const VipActivationResult({required this.startedAt, required this.expiresAt});
}

/// Activates 30-day demo VIP using an RPC with no card/payment parameters.
/// The payment form is visual-only; only subscription dates are saved.
Future<VipActivationResult> activateDemoVip() async {
  final response = await Supabase.instance.client.rpc('activate_demo_vip');
  final row = response is List && response.isNotEmpty
      ? response.first as Map<String, dynamic>
      : response as Map<String, dynamic>;
  return VipActivationResult(
    startedAt: DateTime.parse(row['started_at'].toString()).toLocal(),
    expiresAt: DateTime.parse(row['expires_at'].toString()).toLocal(),
  );
}
