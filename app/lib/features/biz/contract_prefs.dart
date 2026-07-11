import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 계약서 폼 "자주 쓰는 값" 로컬 저장 — 다음 작성 시 프리필.
/// (draft_store 패턴을 따르되 단순 Map 1건만 보관.)
class ContractCommonValues {
  final String workplace;
  final String wageType; // DAILY / HOURLY
  final String wageAmount;
  final String payday;
  final String payMethod;
  final bool insEmployment;
  final bool insHealth;
  final bool insPension;
  final bool insAccident;

  const ContractCommonValues({
    this.workplace = '',
    this.wageType = 'DAILY',
    this.wageAmount = '',
    this.payday = '',
    this.payMethod = '',
    this.insEmployment = false,
    this.insHealth = false,
    this.insPension = false,
    this.insAccident = false,
  });

  Map<String, dynamic> toJson() => {
        'workplace': workplace,
        'wageType': wageType,
        'wageAmount': wageAmount,
        'payday': payday,
        'payMethod': payMethod,
        'insEmployment': insEmployment,
        'insHealth': insHealth,
        'insPension': insPension,
        'insAccident': insAccident,
      };

  factory ContractCommonValues.fromJson(Map j) => ContractCommonValues(
        workplace: j['workplace']?.toString() ?? '',
        wageType: j['wageType']?.toString() ?? 'DAILY',
        wageAmount: j['wageAmount']?.toString() ?? '',
        payday: j['payday']?.toString() ?? '',
        payMethod: j['payMethod']?.toString() ?? '',
        insEmployment: j['insEmployment'] == true,
        insHealth: j['insHealth'] == true,
        insPension: j['insPension'] == true,
        insAccident: j['insAccident'] == true,
      );
}

class ContractPrefs {
  static const _key = 'labor_contract_common_values';

  static Future<ContractCommonValues?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is Map) return ContractCommonValues.fromJson(m);
    } catch (_) {}
    return null;
  }

  static Future<void> save(ContractCommonValues v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(v.toJson()));
  }
}
