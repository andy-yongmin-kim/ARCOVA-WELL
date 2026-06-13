import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'payment_service.dart';

/// 유료 구독 상태 관리
/// - Hive에 상태 저장 (앱 재시작해도 유지)
/// - PaymentService와 연동
class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    _loadStatus();
  }

  bool get isPaid => state;

  /// 저장된 상태 로드
  Future<void> _loadStatus() async {
    final isPaid = await PaymentService.loadPremiumStatus();
    state = isPaid;
  }

  /// 결제 완료 후 호출
  Future<void> markPaid() async {
    state = true;
    await _saveStatus(true);
  }

  /// 상태 초기화 (테스트용)
  Future<void> reset() async {
    state = false;
    await _saveStatus(false);
  }

  /// 상태 저장
  Future<void> _saveStatus(bool isPaid) async {
    final box = await Hive.openBox('settings');
    await box.put('isPremium', isPaid);
  }
}

/// 유료 기능 사용 가능 여부 Provider
final premiumStatusProvider =
    StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});
