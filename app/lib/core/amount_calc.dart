/// backend confirmations/amount.util.ts 와 동일 로직의 클라이언트 미리보기 계산.
/// 저장 시에는 서버 계산값을 사용한다(표시용 재계산만 담당).
library;

const baseRateLabels = {
  'DAILY': '기본(일당)',
  'HOURLY': '기본(시급)',
  'PER_CASE': '기본(건당)',
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
  const AmountLineItem(this.type, this.label, this.rate, this.quantity, this.amount);
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
