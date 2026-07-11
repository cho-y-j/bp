import '../l10n/app_localizations.dart';
import '../models/models.dart';

/// 기본 위험요인 프리셋 코드 (건설 현장 일반) — 백엔드 TBM_DEFAULT_HAZARD_CODES 와 동기.
const tbmDefaultHazardCodes = <String>[
  'HEAVY_EQUIP',
  'FALL_HEIGHT',
  'HEAT_ILLNESS',
  'ELECTRIC_SHOCK',
  'FALLING_OBJECT',
  'COLLAPSE',
  'FIRE_EXPLOSION',
  'DUST_NOISE',
  'SLIP_TRIP',
  'CONFINED_SPACE',
];

/// 기본 위험요인 코드 → 현재 언어 라벨. 알 수 없는 코드는 코드 자체 반환.
String tbmHazardCodeLabel(AppLocalizations l, String code) {
  switch (code) {
    case 'HEAVY_EQUIP':
      return l.tbmHzHeavyEquip;
    case 'FALL_HEIGHT':
      return l.tbmHzFallHeight;
    case 'HEAT_ILLNESS':
      return l.tbmHzHeatIllness;
    case 'ELECTRIC_SHOCK':
      return l.tbmHzElectric;
    case 'FALLING_OBJECT':
      return l.tbmHzFallingObject;
    case 'COLLAPSE':
      return l.tbmHzCollapse;
    case 'FIRE_EXPLOSION':
      return l.tbmHzFire;
    case 'DUST_NOISE':
      return l.tbmHzDustNoise;
    case 'SLIP_TRIP':
      return l.tbmHzSlipTrip;
    case 'CONFINED_SPACE':
      return l.tbmHzConfined;
    default:
      return code;
  }
}

/// 위험요인 항목 → 현재 언어 표시 문구.
///  - code 가 기본 프리셋이면 번역 라벨, 커스텀/직접입력이면 원문(text).
String tbmHazardLabel(AppLocalizations l, TbmHazard h) {
  if (h.code != null && h.code!.isNotEmpty) {
    return tbmHazardCodeLabel(l, h.code!);
  }
  return h.text ?? '';
}

/// 위험요인 배열 → 표시 문구 리스트(빈 항목 제거).
List<String> tbmHazardLabels(AppLocalizations l, List<TbmHazard> hazards) =>
    hazards
        .map((h) => tbmHazardLabel(l, h))
        .where((s) => s.trim().isNotEmpty)
        .toList();
