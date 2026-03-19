import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/app_provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPlan;
  bool _processing = false;

  static const List<Map<String, dynamic>> _plans = [
    {
      'id': 'basic',
      'name': 'Basic',
      'price': 4900,
      'credits': 30,
      'desc': '월 30곡 생성',
      'color': Color(0xFF3B82F6),
      'icon': Icons.music_note,
    },
    {
      'id': 'pro',
      'name': 'Pro',
      'price': 9900,
      'credits': 100,
      'desc': '월 100곡 생성 + 고음질',
      'color': Color(0xFFA855F7),
      'icon': Icons.star,
      'popular': true,
    },
    {
      'id': 'unlimited',
      'name': 'Unlimited',
      'price': 19900,
      'credits': 999999,
      'desc': '무제한 생성 + 모든 기능',
      'color': Color(0xFFFFD000),
      'icon': Icons.all_inclusive,
    },
  ];

  Future<void> _startPayment(Map<String, dynamic> plan) async {
    final provider = context.read<AppProvider>();
    if (!provider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다'), backgroundColor: AppTheme.red),
      );
      return;
    }

    setState(() {
      _processing = true;
      _selectedPlan = plan['id'] as String;
    });

    try {
      // Toss Payments 결제 URL 생성
      final orderId = 'kms_${DateTime.now().millisecondsSinceEpoch}';
      final price = plan['price'] as int;
      final planName = plan['name'] as String;

      // Toss Payments 결제창 URL (웹 결제)
      final paymentUrl = Uri.parse(
        '${AppConstants.apiBaseUrl}/api/payments/checkout'
        '?orderId=$orderId'
        '&amount=$price'
        '&plan=${plan['id']}'
        '&orderName=KMS $planName 플랜'
        '&userName=${provider.currentUser?.name ?? ""}'
        '&userEmail=${provider.currentUser?.email ?? ""}',
      );

      if (await canLaunchUrl(paymentUrl)) {
        await launchUrl(paymentUrl, mode: LaunchMode.externalApplication);
        // 결제 후 돌아오면 결제 확인
        if (mounted) {
          await _confirmPayment(orderId, price, plan['id'] as String);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('결제 페이지를 열 수 없습니다'), backgroundColor: AppTheme.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('결제 오류: $e'), backgroundColor: AppTheme.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
          _selectedPlan = null;
        });
      }
    }
  }

  Future<void> _confirmPayment(String orderId, int amount, String planId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiPaymentsConfirm}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'amount': amount,
          'plan': planId,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결제가 완료되었습니다!'), backgroundColor: AppTheme.green),
        );
      }
    } catch (e) {
      debugPrint('[Payment] 결제 확인 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('크레딧 충전', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 플랜 정보
            Consumer<AppProvider>(
              builder: (context, provider, _) {
                final currentPlan = provider.currentUser?.plan ?? 'free';
                final planInfo = AppConstants.plans[currentPlan] ?? AppConstants.plans['free']!;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: AppTheme.yellow, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '현재 플랜: ${planInfo['label']}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${provider.credits} 크레딧 남음',
                              style: const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '플랜 선택',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Toss Payments로 안전하게 결제됩니다',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            // 플랜 카드 목록
            ..._plans.map((plan) => _buildPlanCard(plan)),
            const SizedBox(height: 24),
            // 안내 문구
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bg3,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('안내사항',
                      style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                  SizedBox(height: 6),
                  Text(
                    '- 결제 후 즉시 크레딧이 충전됩니다\n'
                    '- 미사용 크레딧은 이월됩니다\n'
                    '- 환불은 고객센터로 문의해 주세요',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 12, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isPopular = plan['popular'] == true;
    final planColor = plan['color'] as Color;
    final isSelected = _selectedPlan == plan['id'];
    final price = plan['price'] as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _processing ? null : () => _startPayment(plan),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPopular ? planColor.withValues(alpha: 0.5) : AppTheme.border,
              width: isPopular ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              if (isPopular)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: planColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '인기',
                    style: TextStyle(color: planColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: planColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(plan['icon'] as IconData, color: planColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan['name'] as String,
                          style: TextStyle(
                            color: planColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan['desc'] as String,
                          style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatPrice(price)}원',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const Text('/월', style: TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              if (isSelected && _processing)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(color: AppTheme.accent),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
