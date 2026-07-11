/// 백엔드 DTO 매핑 모델들. 봉투 언래핑 후의 `data` 를 받는다.
library;

DateTime? _pdate(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
int _pint(dynamic v) => v is num ? v.round() : int.tryParse('$v') ?? 0;

class Profile {
  final String id;
  final String? name;
  final String phone;
  final bool phoneSearchConsent;
  final List<String> industryTags;
  final bool hasBusiness;
  final String? kakaoId; // 카카오 연결 여부
  final String? bizNumber; // 세금계산서 공급자 사업자번호
  final String? bizName; // 세금계산서 공급자 상호
  final String? bizAddress; // 세금계산서 공급자 주소
  final String? payoutBank; // 수금 안내용 입금 계좌 은행 (P3a)
  final String? payoutAccount; // 수금 안내용 입금 계좌번호 (P3a)
  final String? payoutHolder; // 수금 안내용 예금주 (P3a)
  final bool cardEnabled; // QR 명함 공개 여부 (P3b)
  final String? cardIntro; // QR 명함 한 줄 소개 (P3b)

  Profile({
    required this.id,
    required this.name,
    required this.phone,
    required this.phoneSearchConsent,
    required this.industryTags,
    required this.hasBusiness,
    required this.kakaoId,
    required this.bizNumber,
    required this.bizName,
    required this.bizAddress,
    required this.payoutBank,
    required this.payoutAccount,
    required this.payoutHolder,
    required this.cardEnabled,
    required this.cardIntro,
  });

  /// 세금계산서 공급자 정보(사업자번호) 등록 여부.
  bool get supplierReady => (bizNumber ?? '').trim().isNotEmpty;

  /// 카카오 계정 연결 여부.
  bool get kakaoLinked => (kakaoId ?? '').trim().isNotEmpty;

  factory Profile.fromJson(Map j) => Profile(
        id: j['id'].toString(),
        name: j['name'] as String?,
        phone: j['phone']?.toString() ?? '',
        phoneSearchConsent: j['phoneSearchConsent'] == true,
        industryTags:
            (j['industryTags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        hasBusiness: j['hasBusiness'] == true,
        kakaoId: j['kakaoId'] as String?,
        bizNumber: j['bizNumber'] as String?,
        bizName: j['bizName'] as String?,
        bizAddress: j['bizAddress'] as String?,
        payoutBank: j['payoutBank'] as String?,
        payoutAccount: j['payoutAccount'] as String?,
        payoutHolder: j['payoutHolder'] as String?,
        cardEnabled: j['cardEnabled'] == true,
        cardIntro: j['cardIntro'] as String?,
      );
}

/// QR 명함 만료/문제 서류 1건 (소유자 본인에게만 노출 — P3b).
class CardExpiredDoc {
  final String type;
  final DateTime? expiryDate;
  final int? dday; // 만료까지 남은 일수(음수=만료됨)
  const CardExpiredDoc(
      {required this.type, required this.expiryDate, required this.dday});
  factory CardExpiredDoc.fromJson(Map j) => CardExpiredDoc(
        type: j['type']?.toString() ?? '',
        expiryDate: _pdate(j['expiryDate']),
        dday: j['dday'] is num ? (j['dday'] as num).round() : null,
      );
}

/// 내 서류 상태(QR 명함 소유자 본인용 — P3b).
class CardDocStatus {
  final bool valid;
  final int withExpiryCount;
  final int totalCount;
  final List<String> types;
  final List<CardExpiredDoc> expiredDocs;
  const CardDocStatus({
    required this.valid,
    required this.withExpiryCount,
    required this.totalCount,
    required this.types,
    required this.expiredDocs,
  });
  factory CardDocStatus.fromJson(Map j) => CardDocStatus(
        valid: j['valid'] == true,
        withExpiryCount: _pint(j['withExpiryCount']),
        totalCount: _pint(j['totalCount']),
        types:
            (j['types'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        expiredDocs: (j['expiredDocs'] as List?)
                ?.map((e) => CardExpiredDoc.fromJson(e as Map))
                .toList() ??
            const [],
      );
}

/// 내 QR 명함 (GET /me/card — P3b).
class CardData {
  final String token;
  final String url;
  final bool enabled;
  final String? intro;
  final int viewCount;
  final String? name;
  final List<String> industryTags;
  final CardDocStatus docStatus;
  const CardData({
    required this.token,
    required this.url,
    required this.enabled,
    required this.intro,
    required this.viewCount,
    required this.name,
    required this.industryTags,
    required this.docStatus,
  });
  factory CardData.fromJson(Map j) {
    final preview = (j['preview'] as Map?) ?? const {};
    return CardData(
      token: j['token']?.toString() ?? '',
      url: j['url']?.toString() ?? '',
      enabled: j['enabled'] == true,
      intro: j['intro'] as String?,
      viewCount: _pint(j['viewCount']),
      name: preview['name'] as String?,
      industryTags: (preview['industryTags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      docStatus: CardDocStatus.fromJson((j['docStatus'] as Map?) ?? const {}),
    );
  }
}

class AuthResult {
  final String accessToken;
  final bool isNew;
  final Profile profile;
  AuthResult(this.accessToken, this.isNew, this.profile);
  factory AuthResult.fromJson(Map j) => AuthResult(
        j['accessToken'].toString(),
        j['isNew'] == true,
        Profile.fromJson(j['profile'] as Map),
      );
}

class Confirmation {
  final String id;
  final String status;
  final String statusLabel;
  final String date; // YYYY-MM-DD (KST)
  final String siteName;
  final String? businessId;
  final String companyName;
  final String? contact;
  final String workDescription;
  final String startTime; // HH:mm
  final String endTime;
  final String rateType;
  final String rateTypeLabel;
  final int total;
  final Map? equipmentSection;
  final Map? amountCalc;
  final String shareToken;
  final String? signerName;
  final String? teamId; // 팀(반장) 확인서면 팀 id
  final List? teamEntries; // [{name, profileId, quantity, rate, amount}]

  Confirmation({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.date,
    required this.siteName,
    required this.businessId,
    required this.companyName,
    required this.contact,
    required this.workDescription,
    required this.startTime,
    required this.endTime,
    required this.rateType,
    required this.rateTypeLabel,
    required this.total,
    required this.equipmentSection,
    required this.amountCalc,
    required this.shareToken,
    required this.signerName,
    required this.teamId,
    required this.teamEntries,
  });

  factory Confirmation.fromJson(Map j) => Confirmation(
        id: j['id'].toString(),
        status: j['status']?.toString() ?? 'DRAFT',
        statusLabel: j['statusLabel']?.toString() ?? '',
        date: j['date']?.toString() ?? '',
        siteName: j['siteName']?.toString() ?? '',
        businessId: j['businessId'] as String?,
        companyName: j['companyName']?.toString() ?? '',
        contact: j['contact'] as String?,
        workDescription: j['workDescription']?.toString() ?? '',
        startTime: j['startTime']?.toString() ?? '',
        endTime: j['endTime']?.toString() ?? '',
        rateType: j['rateType']?.toString() ?? 'DAILY',
        rateTypeLabel: j['rateTypeLabel']?.toString() ?? '',
        total: _pint(j['total']),
        equipmentSection: j['equipmentSection'] as Map?,
        amountCalc: j['amountCalc'] as Map?,
        shareToken: j['shareToken']?.toString() ?? '',
        signerName: j['signerName'] as String?,
        teamId: j['teamId'] as String?,
        teamEntries: j['teamEntries'] as List?,
      );

  /// 팀(반장) 확인서 여부.
  bool get isTeam => teamId != null && teamId!.isNotEmpty;

  DateTime get dateTime => DateTime.parse(date);

  /// 기본항목(BASE) 정보 — amountCalc.items[0]. 공수 라벨 등에 사용.
  Map? get _baseItem {
    final items = amountCalc?['items'];
    if (items is List && items.isNotEmpty && items.first is Map) {
      return items.first as Map;
    }
    return null;
  }

  /// 기본항목 수량 단위(공수면 '공수', 아니면 null).
  String? get baseUnit {
    final u = _baseItem?['unit'];
    return (u is String && u.isNotEmpty) ? u : null;
  }

  /// 기본항목 수량.
  num get baseQuantity {
    final q = _baseItem?['quantity'];
    return q is num ? q : 0;
  }

  /// 기본항목 단가.
  int get baseRate {
    final r = _baseItem?['rate'];
    return r is num ? r.round() : 0;
  }

  /// 공수 확인서 여부.
  bool get isGongsu => rateType == 'GONGSU';
}

class DayAggregate {
  final String date;
  final int count;
  final int totalAmount;
  DayAggregate(this.date, this.count, this.totalAmount);
  factory DayAggregate.fromJson(Map j) =>
      DayAggregate(j['date'].toString(), _pint(j['count']), _pint(j['totalAmount']));
}

class ConfirmationList {
  final int count;
  final int totalAmount;
  final List<DayAggregate> byDate;
  final List<Confirmation> items;
  ConfirmationList(this.count, this.totalAmount, this.byDate, this.items);
  factory ConfirmationList.fromJson(Map j) => ConfirmationList(
        _pint(j['count']),
        _pint(j['totalAmount']),
        (j['byDate'] as List? ?? [])
            .map((e) => DayAggregate.fromJson(e as Map))
            .toList(),
        (j['items'] as List? ?? [])
            .map((e) => Confirmation.fromJson(e as Map))
            .toList(),
      );

  /// 날짜별 집계 맵 (캘린더 그리드용).
  Map<String, DayAggregate> get byDateMap => {for (final d in byDate) d.date: d};
}

class LedgerSummary {
  final String month;
  final int daysWorked;
  final int totalBilled;
  final int totalOutstanding;
  final int totalPaid;
  final int entryCount;
  final double totalGongsu; // 그 달 공수(GONGSU) 확인서 공수 합계
  LedgerSummary(this.month, this.daysWorked, this.totalBilled,
      this.totalOutstanding, this.totalPaid, this.entryCount, this.totalGongsu);
  factory LedgerSummary.fromJson(Map j) => LedgerSummary(
        j['month']?.toString() ?? '',
        _pint(j['daysWorked']),
        _pint(j['totalBilled']),
        _pint(j['totalOutstanding']),
        _pint(j['totalPaid']),
        _pint(j['entryCount']),
        (j['totalGongsu'] as num?)?.toDouble() ?? 0,
      );
}

class LedgerCompany {
  final String companyName;
  final String? businessId;
  final int days;
  final int total;
  final int paid;
  final int outstanding;
  final DateTime? dueDate;
  final int? dday;
  final String status;
  final String statusLabel;
  LedgerCompany({
    required this.companyName,
    required this.businessId,
    required this.days,
    required this.total,
    required this.paid,
    required this.outstanding,
    required this.dueDate,
    required this.dday,
    required this.status,
    required this.statusLabel,
  });
  factory LedgerCompany.fromJson(Map j) => LedgerCompany(
        companyName: j['companyName']?.toString() ?? '(미지정)',
        businessId: j['businessId'] as String?,
        days: _pint(j['days']),
        total: _pint(j['total']),
        paid: _pint(j['paid']),
        outstanding: _pint(j['outstanding']),
        dueDate: _pdate(j['dueDate']),
        dday: j['dday'] == null ? null : _pint(j['dday']),
        status: j['status']?.toString() ?? 'PENDING',
        statusLabel: j['statusLabel']?.toString() ?? '',
      );
}

class LedgerEntry {
  final String id;
  final String companyName;
  final String? businessId;
  final String? siteName;
  final String? date;
  final int amount;
  final int paid;
  final int outstanding;
  final String status;
  final String statusLabel;
  final int? dday;
  final DateTime? dueDate;
  final List payments;
  final bool derived; // 팀원 몫(반장이 발행) — 읽기전용(입금만 가능)
  final String? sourceConfirmationId;
  final bool autoRemind; // 자동 수금 안내 on/off (P3a)
  final List reminders; // [{at, channel, stage}] 발송 이력 (P3a)
  LedgerEntry({
    required this.id,
    required this.companyName,
    required this.businessId,
    required this.siteName,
    required this.date,
    required this.amount,
    required this.paid,
    required this.outstanding,
    required this.status,
    required this.statusLabel,
    required this.dday,
    required this.dueDate,
    required this.payments,
    required this.derived,
    required this.sourceConfirmationId,
    required this.autoRemind,
    required this.reminders,
  });
  factory LedgerEntry.fromJson(Map j) => LedgerEntry(
        id: j['id'].toString(),
        companyName: j['companyName']?.toString() ?? '(미지정)',
        businessId: j['businessId'] as String?,
        siteName: j['siteName'] as String?,
        date: j['date'] as String?,
        amount: _pint(j['amount']),
        paid: _pint(j['paid']),
        outstanding: _pint(j['outstanding']),
        status: j['status']?.toString() ?? 'PENDING',
        statusLabel: j['statusLabel']?.toString() ?? '',
        dday: j['dday'] == null ? null : _pint(j['dday']),
        dueDate: _pdate(j['dueDate']),
        payments: j['payments'] as List? ?? const [],
        derived: j['derived'] == true,
        sourceConfirmationId: j['sourceConfirmationId'] as String?,
        autoRemind: j['autoRemind'] == true,
        reminders: j['reminders'] as List? ?? const [],
      );
}

/// 지급 신뢰도 배지 (P3a). status EXCELLENT/GOOD 만 배지 노출.
class PaymentBadge {
  final String grade; // EXCELLENT | GOOD
  final num avgDays;
  final int sampleSize;
  const PaymentBadge(
      {required this.grade, required this.avgDays, required this.sampleSize});
  factory PaymentBadge.fromJson(Map j) => PaymentBadge(
        grade: j['grade']?.toString() ?? 'GOOD',
        avgDays: (j['avgDays'] as num?) ?? 0,
        sampleSize: _pint(j['sampleSize']),
      );

  /// null 이면 null 반환하는 안전 파서.
  static PaymentBadge? parse(dynamic v) =>
      v is Map ? PaymentBadge.fromJson(v) : null;
}

/// 팀원(반장 팀 명단의 1명).
class TeamMember {
  final String id;
  final String name;
  final String? profileId; // 가입 연결된 경우
  final bool linked;
  final String? phone;
  final int? defaultRate; // 기본 단가(공수 1일)
  final DateTime? createdAt;
  TeamMember({
    required this.id,
    required this.name,
    required this.profileId,
    required this.linked,
    required this.phone,
    required this.defaultRate,
    required this.createdAt,
  });
  factory TeamMember.fromJson(Map j) => TeamMember(
        id: j['id'].toString(),
        name: j['name']?.toString() ?? '',
        profileId: j['profileId'] as String?,
        linked: j['linked'] == true,
        phone: j['phone'] as String?,
        defaultRate: j['defaultRate'] == null ? null : _pint(j['defaultRate']),
        createdAt: _pdate(j['createdAt']),
      );
}

/// 팀(반장 명단).
class Team {
  final String id;
  final String name;
  final int memberCount;
  final List<TeamMember> members;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  Team({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });
  factory Team.fromJson(Map j) => Team(
        id: j['id'].toString(),
        name: j['name']?.toString() ?? '',
        memberCount: _pint(j['memberCount']),
        members: (j['members'] as List? ?? [])
            .map((e) => TeamMember.fromJson(e as Map))
            .toList(),
        createdAt: _pdate(j['createdAt']),
        updatedAt: _pdate(j['updatedAt']),
      );
}

class ExpiringDoc {
  final String id;
  final String type;
  final int? dday;
  final DateTime? expiryDate;
  final String derivedStatus;
  ExpiringDoc(this.id, this.type, this.dday, this.expiryDate, this.derivedStatus);
  factory ExpiringDoc.fromJson(Map j) => ExpiringDoc(
        j['id'].toString(),
        j['type']?.toString() ?? '서류',
        j['dday'] == null ? null : _pint(j['dday']),
        _pdate(j['expiryDate']),
        j['derivedStatus']?.toString() ?? '',
      );
}

class ConnectionItem {
  final String id;
  final String status;
  final String role; // BUSINESS(내가 사업장) / WORKER(내가 작업자)
  final String businessId;
  final String businessName;
  final String workerId;
  final String workerName;
  ConnectionItem(this.id, this.status, this.role, this.businessId,
      this.businessName, this.workerId, this.workerName);
  factory ConnectionItem.fromJson(Map j) {
    final biz = j['business'] as Map? ?? const {};
    final worker = j['worker'] as Map? ?? const {};
    return ConnectionItem(
      j['id'].toString(),
      j['status']?.toString() ?? '',
      j['role']?.toString() ?? '',
      biz['id']?.toString() ?? '',
      biz['name']?.toString() ?? '',
      worker['id']?.toString() ?? '',
      worker['name']?.toString() ?? '',
    );
  }
}

// ===========================================================================
// S4b: 서류 지갑 / 사업장 모드 / 알림
// ===========================================================================

/// 서류 지갑 항목.
class DocumentItem {
  final String id;
  final String type;
  final String ownerType; // PROFILE / EQUIPMENT
  final String? equipmentId;
  final String status;
  final String derivedStatus; // VALID/EXPIRING_SOON/EXPIRED/NONE
  final int? dday;
  final DateTime? issuedDate;
  final DateTime? expiryDate;
  final bool hasMask;
  final String? mimeType;
  final String? originalFileName;

  DocumentItem({
    required this.id,
    required this.type,
    required this.ownerType,
    required this.equipmentId,
    required this.status,
    required this.derivedStatus,
    required this.dday,
    required this.issuedDate,
    required this.expiryDate,
    required this.hasMask,
    required this.mimeType,
    required this.originalFileName,
  });

  bool get isImage => (mimeType ?? '').startsWith('image/');

  factory DocumentItem.fromJson(Map j) => DocumentItem(
        id: j['id'].toString(),
        type: j['type']?.toString() ?? '서류',
        ownerType: j['ownerType']?.toString() ?? 'PROFILE',
        equipmentId: j['equipmentId'] as String?,
        status: j['status']?.toString() ?? '',
        derivedStatus: j['derivedStatus']?.toString() ?? 'NONE',
        dday: j['dday'] == null ? null : _pint(j['dday']),
        issuedDate: _pdate(j['issuedDate']),
        expiryDate: _pdate(j['expiryDate']),
        hasMask: j['hasMask'] == true,
        mimeType: j['mimeType'] as String?,
        originalFileName: j['originalFileName'] as String?,
      );
}

/// 장비 항목.
class EquipmentItem {
  final String id;
  final String type;
  final String? vehicleNumber;
  final String? spec;
  final int documentCount;
  EquipmentItem(
      this.id, this.type, this.vehicleNumber, this.spec, this.documentCount);
  factory EquipmentItem.fromJson(Map j) => EquipmentItem(
        j['id'].toString(),
        j['type']?.toString() ?? '장비',
        j['vehicleNumber'] as String?,
        j['spec'] as String?,
        _pint((j['_count'] as Map?)?['documents'] ?? 0),
      );
}

/// 묶음 공유 생성 결과.
class ShareResult {
  final String shareToken;
  final String url;
  final DateTime? expiresAt;
  final int documentCount;
  ShareResult(this.shareToken, this.url, this.expiresAt, this.documentCount);
  factory ShareResult.fromJson(Map j) => ShareResult(
        j['shareToken']?.toString() ?? '',
        j['url']?.toString() ?? '',
        _pdate(j['expiresAt']),
        _pint(j['documentCount']),
      );
}

/// 내 공유 목록 항목.
class ShareItem {
  final String id;
  final String shareToken;
  final DateTime? expiresAt;
  final bool active;
  final int viewCount;
  final List<String> docTypes;
  ShareItem(this.id, this.shareToken, this.expiresAt, this.active,
      this.viewCount, this.docTypes);
  factory ShareItem.fromJson(Map j) => ShareItem(
        j['id'].toString(),
        j['shareToken']?.toString() ?? '',
        _pdate(j['expiresAt']),
        j['active'] == true,
        _pint(j['viewCount']),
        (j['documents'] as List? ?? [])
            .map((e) => (e as Map)['type']?.toString() ?? '서류')
            .toList(),
      );
}

/// 사업장.
class BusinessItem {
  final String id;
  final String name;
  final String? businessNumber;
  final String? inviteCode;
  final String? address;
  final String? ownerName; // 대표자명 (P3a 검색결과)
  final PaymentBadge? paymentBadge; // 지급 신뢰도 배지 (P3a)
  BusinessItem(this.id, this.name, this.businessNumber, this.inviteCode,
      this.address,
      {this.ownerName, this.paymentBadge});
  factory BusinessItem.fromJson(Map j) => BusinessItem(
        j['id'].toString(),
        j['name']?.toString() ?? '',
        j['businessNumber'] as String?,
        j['inviteCode'] as String?,
        j['address'] as String?,
        ownerName: j['ownerName'] as String?,
        paymentBadge: PaymentBadge.parse(j['paymentBadge']),
      );
}

/// 작업자 검색 결과.
class WorkerSearchItem {
  final String profileId;
  final String maskedName;
  final List<String> industryTags;
  WorkerSearchItem(this.profileId, this.maskedName, this.industryTags);
  factory WorkerSearchItem.fromJson(Map j) => WorkerSearchItem(
        j['profileId'].toString(),
        j['maskedName']?.toString() ?? '',
        (j['industryTags'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

/// 작업 지시.
class JobItem {
  final String id;
  final String? businessId;
  final String workerProfileId;
  final String site;
  final DateTime scheduledAt;
  final String rateType;
  final int rate;
  final String status; // SCHEDULED/IN_PROGRESS/DONE
  final DateTime? acceptedAt;
  final String role; // BUSINESS/WORKER
  final String? businessName;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  JobItem({
    required this.id,
    required this.businessId,
    required this.workerProfileId,
    required this.site,
    required this.scheduledAt,
    required this.rateType,
    required this.rate,
    required this.status,
    required this.acceptedAt,
    required this.role,
    required this.businessName,
    required this.startedAt,
    required this.finishedAt,
  });

  factory JobItem.fromJson(Map j) {
    final wl = j['workLog'] as Map?;
    return JobItem(
      id: j['id'].toString(),
      businessId: j['businessId'] as String?,
      workerProfileId: j['workerProfileId']?.toString() ?? '',
      site: j['site']?.toString() ?? '',
      scheduledAt:
          DateTime.tryParse(j['scheduledAt']?.toString() ?? '') ?? DateTime.now(),
      rateType: j['rateType']?.toString() ?? 'DAILY',
      rate: _pint(j['rate']),
      status: j['status']?.toString() ?? 'SCHEDULED',
      acceptedAt: _pdate(j['acceptedAt']),
      role: j['role']?.toString() ?? 'WORKER',
      businessName: j['businessName'] as String?,
      startedAt: _pdate(wl?['startedAt']),
      finishedAt: _pdate(wl?['finishedAt']),
    );
  }
}

/// 수신함 항목.
class InboxItem {
  final String id;
  final String status;
  final String date;
  final String site;
  final String companyName;
  final String workerName;
  final int total;
  final String? signerName;
  InboxItem(this.id, this.status, this.date, this.site, this.companyName,
      this.workerName, this.total, this.signerName);
  factory InboxItem.fromJson(Map j) => InboxItem(
        j['id'].toString(),
        j['status']?.toString() ?? '',
        j['date']?.toString() ?? '',
        j['site']?.toString() ?? '',
        j['companyName']?.toString() ?? '',
        j['workerName']?.toString() ?? '',
        _pint(j['total']),
        j['signerName'] as String?,
      );
  bool get signed => status == 'SIGNED';
}

/// 수신함 상세(PaperCard 렌더용).
class BizConfirmationDetail {
  final String id;
  final String status;
  final bool signed;
  final String date;
  final String companyName;
  final String? contact;
  final String workerName;
  final String site;
  final String workContent;
  final String startTime;
  final String endTime;
  final String rateTypeLabel;
  final int total;
  final Map? amountCalc;
  final Map? equipmentSection;
  final String? signerName;
  final String? signedAt;

  BizConfirmationDetail({
    required this.id,
    required this.status,
    required this.signed,
    required this.date,
    required this.companyName,
    required this.contact,
    required this.workerName,
    required this.site,
    required this.workContent,
    required this.startTime,
    required this.endTime,
    required this.rateTypeLabel,
    required this.total,
    required this.amountCalc,
    required this.equipmentSection,
    required this.signerName,
    required this.signedAt,
  });

  factory BizConfirmationDetail.fromJson(Map j) => BizConfirmationDetail(
        id: j['id'].toString(),
        status: j['status']?.toString() ?? '',
        signed: j['signed'] == true,
        date: j['date']?.toString() ?? '',
        companyName: j['companyName']?.toString() ?? '',
        contact: j['contact'] as String?,
        workerName: j['workerName']?.toString() ?? '',
        site: j['site']?.toString() ?? '',
        workContent: j['workContent']?.toString() ?? '',
        startTime: j['startTime']?.toString() ?? '',
        endTime: j['endTime']?.toString() ?? '',
        rateTypeLabel: j['rateTypeLabel']?.toString() ?? '',
        total: _pint(j['total']),
        amountCalc: j['amountCalc'] as Map?,
        equipmentSection: j['equipmentSection'] as Map?,
        signerName: j['signerName'] as String?,
        signedAt: j['signedAt'] as String?,
      );
}

/// 정산: 작업자별 미지급 집계.
class SettlementWorker {
  final String workerProfileId;
  final String workerName;
  final int entryCount;
  final int total;
  final int paid;
  final int outstanding;
  final List<String> ledgerEntryIds;
  SettlementWorker(this.workerProfileId, this.workerName, this.entryCount,
      this.total, this.paid, this.outstanding, this.ledgerEntryIds);
  factory SettlementWorker.fromJson(Map j) => SettlementWorker(
        j['workerProfileId'].toString(),
        j['workerName']?.toString() ?? '',
        _pint(j['entryCount']),
        _pint(j['total']),
        _pint(j['paid']),
        _pint(j['outstanding']),
        (j['ledgerEntryIds'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

/// 알림 항목.
class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map? data;
  final bool read;
  final DateTime? createdAt;
  NotificationItem(this.id, this.type, this.title, this.body, this.data,
      this.read, this.createdAt);
  factory NotificationItem.fromJson(Map j) => NotificationItem(
        j['id'].toString(),
        j['type']?.toString() ?? '',
        j['title']?.toString() ?? '',
        j['body']?.toString() ?? '',
        j['data'] as Map?,
        j['read'] == true,
        _pdate(j['createdAt']),
      );

  /// 폭염 알림의 safety_log id (확인 버튼용).
  String? get safetyLogId => data?['logId']?.toString() ?? data?['safetyLogId']?.toString();

  /// TBM 알림의 참석자 id (확인 버튼용).
  String? get tbmAttendeeId => data?['tbmAttendeeId']?.toString();
}

/// 알림 목록 + 미읽음 수.
class NotificationList {
  final int unreadCount;
  final List<NotificationItem> items;
  NotificationList(this.unreadCount, this.items);
  factory NotificationList.fromJson(Map j) => NotificationList(
        _pint(j['unreadCount']),
        (j['items'] as List? ?? [])
            .map((e) => NotificationItem.fromJson(e as Map))
            .toList(),
      );
}

// ===========================================================================
// P1: 세금계산서 1단계 (홈택스 입력용 데이터)
// ===========================================================================

/// 세금계산서 공급자(나) 정보.
class TaxInvoiceSupplier {
  final String? name;
  final String? bizNumber;
  final String? bizName;
  final String? bizAddress;
  TaxInvoiceSupplier(this.name, this.bizNumber, this.bizName, this.bizAddress);
  factory TaxInvoiceSupplier.fromJson(Map j) => TaxInvoiceSupplier(
        j['name'] as String?,
        j['bizNumber'] as String?,
        j['bizName'] as String?,
        j['bizAddress'] as String?,
      );
}

/// 세금계산서 품목(확인서 1건).
class TaxInvoiceItem {
  final String ledgerId;
  final String date;
  final String content;
  final int supplyAmount;
  TaxInvoiceItem(this.ledgerId, this.date, this.content, this.supplyAmount);
  factory TaxInvoiceItem.fromJson(Map j) => TaxInvoiceItem(
        j['ledgerId'].toString(),
        j['date']?.toString() ?? '',
        j['content']?.toString() ?? '',
        _pint(j['supplyAmount']),
      );
}

/// 세금계산서 상대별 그룹(공급받는자).
class TaxInvoiceGroup {
  final String buyerName;
  final String? buyerBizNumber;
  final bool buyerRegistered;
  final String writeDate;
  final int supplyTotal;
  final int taxTotal;
  final int grandTotal;
  final List<TaxInvoiceItem> items;
  final List<String> ledgerIds;
  TaxInvoiceGroup({
    required this.buyerName,
    required this.buyerBizNumber,
    required this.buyerRegistered,
    required this.writeDate,
    required this.supplyTotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.items,
    required this.ledgerIds,
  });
  factory TaxInvoiceGroup.fromJson(Map j) => TaxInvoiceGroup(
        buyerName: j['buyerName']?.toString() ?? '(미지정)',
        buyerBizNumber: j['buyerBizNumber'] as String?,
        buyerRegistered: j['buyerRegistered'] == true,
        writeDate: j['writeDate']?.toString() ?? '',
        supplyTotal: _pint(j['supplyTotal']),
        taxTotal: _pint(j['taxTotal']),
        grandTotal: _pint(j['grandTotal']),
        items: (j['items'] as List? ?? [])
            .map((e) => TaxInvoiceItem.fromJson(e as Map))
            .toList(),
        ledgerIds:
            (j['ledgerIds'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

// ===========================================================================
// 표준근로계약서 (전자서명)
// ===========================================================================

/// 표준근로계약서 DTO 매핑. GET/POST 응답의 LaborContractDto.
class LaborContract {
  final String id;
  final String status; // DRAFT / SENT / SIGNED
  final String statusLabel;
  final String businessId;
  final String? businessName;
  final String title;
  final String? workerProfileId;
  final bool workerLinked;
  final String workerName;
  final String? workerPhone;
  final String startDate; // YYYY-MM-DD
  final String? endDate;
  final String workplace;
  final String jobDescription;
  final String workStartTime; // HH:mm
  final String workEndTime;
  final String? breakTime;
  final String wageType; // DAILY / HOURLY
  final String wageTypeLabel;
  final int wageAmount;
  final String payday;
  final String payMethod;
  final bool weeklyHolidayAllowance;
  final bool overtimeAllowance;
  final Map? socialInsurance; // {employment, health, pension, industrialAccident}
  final String? specialTerms;
  final bool employerSigned;
  final String? employerSignerName;
  final String? employerSignedAt;
  final bool workerSigned;
  final String? workerSignerName;
  final String? workerSignedAt;
  final String shareToken;
  final DateTime? revokedAt;
  final int viewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LaborContract({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.workerProfileId,
    required this.workerLinked,
    required this.workerName,
    required this.workerPhone,
    required this.startDate,
    required this.endDate,
    required this.workplace,
    required this.jobDescription,
    required this.workStartTime,
    required this.workEndTime,
    required this.breakTime,
    required this.wageType,
    required this.wageTypeLabel,
    required this.wageAmount,
    required this.payday,
    required this.payMethod,
    required this.weeklyHolidayAllowance,
    required this.overtimeAllowance,
    required this.socialInsurance,
    required this.specialTerms,
    required this.employerSigned,
    required this.employerSignerName,
    required this.employerSignedAt,
    required this.workerSigned,
    required this.workerSignerName,
    required this.workerSignedAt,
    required this.shareToken,
    required this.revokedAt,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LaborContract.fromJson(Map j) => LaborContract(
        id: j['id'].toString(),
        status: j['status']?.toString() ?? 'DRAFT',
        statusLabel: j['statusLabel']?.toString() ?? '',
        businessId: j['businessId']?.toString() ?? '',
        businessName: j['businessName'] as String?,
        title: j['title']?.toString() ?? '',
        workerProfileId: j['workerProfileId'] as String?,
        workerLinked: j['workerLinked'] == true,
        workerName: j['workerName']?.toString() ?? '',
        workerPhone: j['workerPhone'] as String?,
        startDate: j['startDate']?.toString() ?? '',
        endDate: j['endDate'] as String?,
        workplace: j['workplace']?.toString() ?? '',
        jobDescription: j['jobDescription']?.toString() ?? '',
        workStartTime: j['workStartTime']?.toString() ?? '',
        workEndTime: j['workEndTime']?.toString() ?? '',
        breakTime: j['breakTime'] as String?,
        wageType: j['wageType']?.toString() ?? 'DAILY',
        wageTypeLabel: j['wageTypeLabel']?.toString() ?? '',
        wageAmount: _pint(j['wageAmount']),
        payday: j['payday']?.toString() ?? '',
        payMethod: j['payMethod']?.toString() ?? '',
        weeklyHolidayAllowance: j['weeklyHolidayAllowance'] == true,
        overtimeAllowance: j['overtimeAllowance'] == true,
        socialInsurance: j['socialInsurance'] as Map?,
        specialTerms: j['specialTerms'] as String?,
        employerSigned: j['employerSigned'] == true,
        employerSignerName: j['employerSignerName'] as String?,
        employerSignedAt: j['employerSignedAt'] as String?,
        workerSigned: j['workerSigned'] == true,
        workerSignerName: j['workerSignerName'] as String?,
        workerSignedAt: j['workerSignedAt'] as String?,
        shareToken: j['shareToken']?.toString() ?? '',
        revokedAt: _pdate(j['revokedAt']),
        viewCount: _pint(j['viewCount']),
        createdAt: _pdate(j['createdAt']),
        updatedAt: _pdate(j['updatedAt']),
      );

  bool get isDraft => status == 'DRAFT';
  bool get isSent => status == 'SENT';
  bool get isSigned => status == 'SIGNED';

  /// 4대보험 개별 적용 여부(누락 시 false).
  bool insEmployment() => socialInsurance?['employment'] == true;
  bool insHealth() => socialInsurance?['health'] == true;
  bool insPension() => socialInsurance?['pension'] == true;
  bool insAccident() => socialInsurance?['industrialAccident'] == true;
}

/// 세금계산서 데이터 응답(월 단위).
class TaxInvoiceData {
  final String month;
  final String writeDate;
  final TaxInvoiceSupplier supplier;
  final bool supplierReady;
  final int groupCount;
  final List<TaxInvoiceGroup> groups;
  final String text; // 홈택스 입력용 복사 텍스트
  TaxInvoiceData({
    required this.month,
    required this.writeDate,
    required this.supplier,
    required this.supplierReady,
    required this.groupCount,
    required this.groups,
    required this.text,
  });
  factory TaxInvoiceData.fromJson(Map j) => TaxInvoiceData(
        month: j['month']?.toString() ?? '',
        writeDate: j['writeDate']?.toString() ?? '',
        supplier: TaxInvoiceSupplier.fromJson(j['supplier'] as Map? ?? const {}),
        supplierReady: j['supplierReady'] == true,
        groupCount: _pint(j['groupCount']),
        groups: (j['groups'] as List? ?? [])
            .map((e) => TaxInvoiceGroup.fromJson(e as Map))
            .toList(),
        text: j['text']?.toString() ?? '',
      );
}

// ===========================================================================
// 간편 TBM (안전점검회의) — P2c
// ===========================================================================

/// 위험요인 항목 — 기본 프리셋 코드(code, 앱이 자기 언어로 번역) 또는 커스텀 원문(text).
class TbmHazard {
  final String? code;
  final String? text;
  const TbmHazard({this.code, this.text});
  factory TbmHazard.fromJson(Map j) => TbmHazard(
        code: j['code'] as String?,
        text: j['text'] as String?,
      );
  Map<String, dynamic> toJson() => {
        if (code != null) 'code': code,
        if (text != null) 'text': text,
      };
}

/// TBM 참석자 + 확인 현황.
class TbmAttendee {
  final String id;
  final String? profileId;
  final bool linked;
  final String name;
  final bool acked;
  final String? ackAt;
  TbmAttendee(this.id, this.profileId, this.linked, this.name, this.acked,
      this.ackAt);
  factory TbmAttendee.fromJson(Map j) => TbmAttendee(
        j['id'].toString(),
        j['profileId'] as String?,
        j['linked'] == true,
        j['name']?.toString() ?? '',
        j['acked'] == true,
        j['ackAt'] as String?,
      );
}

/// TBM 기록.
class TbmRecord {
  final String id;
  final String businessId;
  final String? businessName;
  final String site;
  final String occurredAt; // YYYY-MM-DD HH:mm
  final String date; // YYYY-MM-DD
  final List<TbmHazard> hazards;
  final List<String> hazardLabelsKo;
  final String? measures;
  final String? notes;
  final int photoCount;
  final List<String> photoUrls;
  final int attendeeCount;
  final int ackCount;
  final List<TbmAttendee> attendees;
  final bool editable;
  TbmRecord({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.site,
    required this.occurredAt,
    required this.date,
    required this.hazards,
    required this.hazardLabelsKo,
    required this.measures,
    required this.notes,
    required this.photoCount,
    required this.photoUrls,
    required this.attendeeCount,
    required this.ackCount,
    required this.attendees,
    required this.editable,
  });
  factory TbmRecord.fromJson(Map j) => TbmRecord(
        id: j['id'].toString(),
        businessId: j['businessId']?.toString() ?? '',
        businessName: j['businessName'] as String?,
        site: j['site']?.toString() ?? '',
        occurredAt: j['occurredAt']?.toString() ?? '',
        date: j['date']?.toString() ?? '',
        hazards: (j['hazards'] as List? ?? [])
            .map((e) => TbmHazard.fromJson(e as Map))
            .toList(),
        hazardLabelsKo: (j['hazardLabelsKo'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        measures: j['measures'] as String?,
        notes: j['notes'] as String?,
        photoCount: _pint(j['photoCount']),
        photoUrls:
            (j['photoUrls'] as List? ?? []).map((e) => e.toString()).toList(),
        attendeeCount: _pint(j['attendeeCount']),
        ackCount: _pint(j['ackCount']),
        attendees: (j['attendees'] as List? ?? [])
            .map((e) => TbmAttendee.fromJson(e as Map))
            .toList(),
        editable: j['editable'] == true,
      );
}

/// 작업자 "받은 TBM" 목록 항목 (내 attendeeId + 확인 여부 + 기록).
class TbmReceivedItem {
  final String attendeeId;
  final bool acked;
  final TbmRecord record;
  TbmReceivedItem(this.attendeeId, this.acked, this.record);
  factory TbmReceivedItem.fromJson(Map j) => TbmReceivedItem(
        j['attendeeId'].toString(),
        j['acked'] == true,
        TbmRecord.fromJson(j['record'] as Map),
      );
}

// ─── P2d 연간 소득 리포트 ─────────────────────────────────────────────
/// 월별 추이 포인트.
class IncomeMonthly {
  final String month; // YYYY-MM
  final int billed;
  final int paid;
  final int outstanding;
  final int daysWorked;
  final double gongsu;
  IncomeMonthly(this.month, this.billed, this.paid, this.outstanding,
      this.daysWorked, this.gongsu);
  factory IncomeMonthly.fromJson(Map j) => IncomeMonthly(
        j['month']?.toString() ?? '',
        _pint(j['billed']),
        _pint(j['paid']),
        _pint(j['outstanding']),
        _pint(j['daysWorked']),
        (j['gongsu'] as num?)?.toDouble() ?? 0,
      );
}

/// 상대별 합계.
class IncomeCompany {
  final String companyName;
  final String? businessId;
  final int count;
  final int total;
  final int paid;
  final int outstanding;
  IncomeCompany(this.companyName, this.businessId, this.count, this.total,
      this.paid, this.outstanding);
  factory IncomeCompany.fromJson(Map j) => IncomeCompany(
        j['companyName']?.toString() ?? '(미지정)',
        j['businessId'] as String?,
        _pint(j['count']),
        _pint(j['total']),
        _pint(j['paid']),
        _pint(j['outstanding']),
      );
}

/// 연간 소득 리포트 전체.
class IncomeReport {
  final String from; // YYYY-MM
  final String to; // YYYY-MM
  final int? year;
  final List<IncomeMonthly> monthly;
  final List<IncomeCompany> companies;
  final int totalBilled;
  final int totalPaid;
  final int totalOutstanding;
  final int totalDays;
  final double totalGongsu;
  final int entryCount;
  final int teamPayout;
  final int netBilled;
  IncomeReport({
    required this.from,
    required this.to,
    required this.year,
    required this.monthly,
    required this.companies,
    required this.totalBilled,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.totalDays,
    required this.totalGongsu,
    required this.entryCount,
    required this.teamPayout,
    required this.netBilled,
  });
  factory IncomeReport.fromJson(Map j) {
    final range = (j['range'] as Map?) ?? {};
    final totals = (j['totals'] as Map?) ?? {};
    return IncomeReport(
      from: range['from']?.toString() ?? '',
      to: range['to']?.toString() ?? '',
      year: range['year'] == null ? null : _pint(range['year']),
      monthly: ((j['monthly'] as List?) ?? [])
          .map((e) => IncomeMonthly.fromJson(e as Map))
          .toList(),
      companies: ((j['companies'] as List?) ?? [])
          .map((e) => IncomeCompany.fromJson(e as Map))
          .toList(),
      totalBilled: _pint(totals['totalBilled']),
      totalPaid: _pint(totals['totalPaid']),
      totalOutstanding: _pint(totals['totalOutstanding']),
      totalDays: _pint(totals['totalDays']),
      totalGongsu: (totals['totalGongsu'] as num?)?.toDouble() ?? 0,
      entryCount: _pint(totals['entryCount']),
      teamPayout: _pint(totals['teamPayout']),
      netBilled: _pint(totals['netBilled']),
    );
  }
}

/// 사업장 커스텀 TBM 프리셋 문구.
class TbmPreset {
  final String id;
  final String businessId;
  final String kind; // HAZARD | MEASURE
  final String text;
  TbmPreset(this.id, this.businessId, this.kind, this.text);
  factory TbmPreset.fromJson(Map j) => TbmPreset(
        j['id'].toString(),
        j['businessId']?.toString() ?? '',
        j['kind']?.toString() ?? 'HAZARD',
        j['text']?.toString() ?? '',
      );
}
