/// backend confirmations/amount.util.ts 와 동일 로직의 클라이언트 미리보기 계산.
/// 저장 시에는 서버 계산값을 사용한다(표시용 재계산만 담당).
library;

const baseRateLabels = {
  'DAILY': '기본(일당)',
  'HOURLY': '기본(시급)',
  'PER_CASE': '기본(건당)',
  'GONGSU': '기본(공수)',
};

/// 기본항목 수량 단위(있으면 "1.5공수" 처럼 표기). 공수(GONGSU)만 '공수'.
const baseRateUnits = {
  'GONGSU': '공수',
};

const additionalItemLabels = {
  'OVERTIME': '연장',
  'EARLY': '조출',
  'NIGHT': '야간',
  'ALLNIGHT': '철야',
  'OTHER': '기타',
};

class AmountLineItem {
  final String type;
  final String label;
  final int rate;
  final num quantity;
  final int amount;
  final String? unit; // 수량 단위(있으면 "1.5공수"). 공수 기본항목만 '공수'.
  const AmountLineItem(this.type, this.label, this.rate, this.quantity, this.amount,
      {this.unit});
}

class AmountCalcResult {
  final List<AmountLineItem> items;
  final int subtotal;
  final double vatRate;
  final int vat;
  final int total;
  const AmountCalcResult(this.items, this.subtotal, this.vatRate, this.vat, this.total);
}

class AdditionalItemInput {
  final String type;
  final String? label;
  final num rate;
  final num quantity;
  const AdditionalItemInput({
    required this.type,
    this.label,
    required this.rate,
    required this.quantity,
  });
}

int _money(num n) {
  if (n.isNaN || n.isInfinite) return 0;
  return n.round();
}

/// 수량을 사람이 읽는 문자열로. 정수면 소수점 없이. (예: 1.5 → "1.5", 2 → "2")
String formatQty(num n) => n == n.roundToDouble() ? '${n.round()}' : '$n';

/// 수량 + 단위 표기. 공수면 "1.5공수", 아니면 그냥 수량. (백엔드 PDF 라벨과 동일)
String formatQtyUnit(num n, String? unit) =>
    unit != null && unit.isNotEmpty ? '${formatQty(n)}$unit' : formatQty(n);

/// 공수(GONGSU) 수량 유효성 검사 — 백엔드 `validateGongsuQuantity` 와 동일 로직.
/// 0보다 크고 0.1 단위여야 한다. 유효하면 0.1로 정규화한 값, 아니면 null.
double? validateGongsuQuantity(num quantity) {
  final q = quantity.toDouble();
  if (q.isNaN || q.isInfinite || q <= 0) return null;
  final scaled = (q * 10).round();
  if (scaled <= 0) return null;
  if ((q * 10 - scaled).abs() > 1e-6) return null; // 0.1 단위가 아님
  return scaled / 10;
}

AmountCalcResult calcAmount({
  required String rateType,
  required num rate,
  required num quantity,
  List<AdditionalItemInput> additionalItems = const [],
  double vatRate = 0,
}) {
  final items = <AmountLineItem>[];
  final baseRate = rate < 0 ? 0 : rate;
  final baseQty = quantity < 0 ? 0 : quantity;
  items.add(AmountLineItem(
    'BASE',
    baseRateLabels[rateType] ?? rateType,
    _money(baseRate),
    baseQty,
    _money(baseRate * baseQty),
    unit: baseRateUnits[rateType],
  ));

  for (final raw in additionalItems) {
    final r = raw.rate < 0 ? 0 : raw.rate;
    final q = raw.quantity < 0 ? 0 : raw.quantity;
    final label = raw.type == 'OTHER'
        ? ((raw.label?.trim().isNotEmpty ?? false)
            ? raw.label!.trim()
            : additionalItemLabels['OTHER']!)
        : (additionalItemLabels[raw.type] ?? raw.type);
    items.add(AmountLineItem(raw.type, label, _money(r), q, _money(r * q)));
  }

  final subtotal = _money(items.fold<int>(0, (s, it) => s + it.amount));
  final vr = vatRate > 0 ? vatRate : 0.0;
  final vat = _money(subtotal * vr);
  final total = subtotal + vat;
  return AmountCalcResult(items, subtotal, vr.toDouble(), vat, total);
}
