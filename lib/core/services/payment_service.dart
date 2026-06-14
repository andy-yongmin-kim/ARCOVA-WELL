import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 상품 ID - 플랫폼별로 다르게 설정 가능
/// Google Play Console과 App Store Connect에서 동일한 ID 사용 권장
const String kPremiumProductIdAndroid = 'arcova_premium_unlock';
const String kPremiumProductIdIOS = 'arcova_premium_unlock';

/// 현재 플랫폼의 상품 ID 반환
String get kPremiumProductId {
  if (Platform.isIOS) {
    return kPremiumProductIdIOS;
  }
  return kPremiumProductIdAndroid;
}

/// 결제 상태
enum PaymentStatus {
  idle,
  loading,
  purchased,
  error,
}

/// 결제 서비스 - Google Play In-App Purchase
class PaymentService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  /// 결제 가능 여부
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  
  /// 상품 정보
  ProductDetails? _product;
  ProductDetails? get product => _product;
  
  /// 결제 상태 콜백
  Function(PaymentStatus status, String? message)? onStatusChanged;
  
  /// 초기화
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    
    if (!_isAvailable) {
      debugPrint('❌ [PaymentService] In-App Purchase를 사용할 수 없습니다');
      return;
    }
    
    debugPrint('✅ [PaymentService] In-App Purchase 사용 가능');
    
    // 구매 스트림 리스닝
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('❌ [PaymentService] 구매 스트림 에러: $error');
      },
    );
    
    // 상품 정보 로드
    await loadProducts();
    
    // 이전 구매 복원 확인
    await restorePurchases();
  }
  
  /// 상품 정보 로드
  Future<void> loadProducts() async {
    if (!_isAvailable) return;
    
    final response = await _iap.queryProductDetails({kPremiumProductId});
    
    if (response.error != null) {
      debugPrint('❌ [PaymentService] 상품 조회 에러: ${response.error}');
      return;
    }
    
    if (response.productDetails.isEmpty) {
      debugPrint('⚠️ [PaymentService] 상품을 찾을 수 없음: $kPremiumProductId');
      debugPrint('   → Google Play Console에서 상품 ID를 확인하세요');
      return;
    }
    
    _product = response.productDetails.first;
    debugPrint('✅ [PaymentService] 상품 로드 완료: ${_product!.title} - ${_product!.price}');
  }
  
  /// 구매 처리
  Future<bool> purchasePremium() async {
    if (!_isAvailable) {
      onStatusChanged?.call(PaymentStatus.error, '결제 서비스를 사용할 수 없습니다');
      return false;
    }
    
    if (_product == null) {
      onStatusChanged?.call(PaymentStatus.error, '상품 정보를 불러올 수 없습니다');
      return false;
    }
    
    onStatusChanged?.call(PaymentStatus.loading, null);
    
    final purchaseParam = PurchaseParam(productDetails: _product!);
    
    try {
      // 비소모성 상품 구매 (한 번 구매하면 영구)
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (!success) {
        onStatusChanged?.call(PaymentStatus.error, '결제를 시작할 수 없습니다');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ [PaymentService] 구매 에러: $e');
      onStatusChanged?.call(PaymentStatus.error, '결제 중 오류가 발생했습니다');
      return false;
    }
  }
  
  /// 구매 상태 업데이트 처리
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    try {
      for (final purchase in purchases) {
        debugPrint('📦 [PaymentService] 구매 상태: ${purchase.status}');

        switch (purchase.status) {
          case PurchaseStatus.pending:
            onStatusChanged?.call(PaymentStatus.loading, '결제 처리 중...');
            break;

          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            _savePremiumStatus(true);
            onStatusChanged?.call(PaymentStatus.purchased, '프리미엄 기능이 활성화되었습니다!');
            if (purchase.pendingCompletePurchase) {
              _iap.completePurchase(purchase).catchError((e) {
                debugPrint('❌ [PaymentService] completePurchase 에러: $e');
              });
            }
            break;

          case PurchaseStatus.error:
            onStatusChanged?.call(
              PaymentStatus.error,
              purchase.error?.message ?? '결제 중 오류가 발생했습니다',
            );
            break;

          case PurchaseStatus.canceled:
            onStatusChanged?.call(PaymentStatus.idle, null);
            break;
        }
      }
    } catch (e) {
      debugPrint('❌ [PaymentService] 구매 업데이트 처리 에러: $e');
    }
  }
  
  /// 이전 구매 복원
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    
    try {
      await _iap.restorePurchases();
      debugPrint('🔄 [PaymentService] 구매 복원 요청 완료');
    } catch (e) {
      debugPrint('❌ [PaymentService] 구매 복원 에러: $e');
    }
  }
  
  /// 프리미엄 상태 저장 (Hive)
  Future<void> _savePremiumStatus(bool isPaid) async {
    final box = await Hive.openBox('settings');
    await box.put('isPremium', isPaid);
    debugPrint('💾 [PaymentService] 프리미엄 상태 저장: $isPaid');
  }
  
  /// 프리미엄 상태 로드 (Hive)
  static Future<bool> loadPremiumStatus() async {
    final box = await Hive.openBox('settings');
    final isPaid = box.get('isPremium', defaultValue: false) as bool;
    debugPrint('📖 [PaymentService] 프리미엄 상태 로드: $isPaid');
    return isPaid;
  }
  
  /// 리소스 해제
  void dispose() {
    _subscription?.cancel();
  }
}

/// Payment 서비스 Provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final service = PaymentService();
  ref.onDispose(() => service.dispose());
  return service;
});
