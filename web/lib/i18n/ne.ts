import type { MessageKey } from './ko';

/** 네팔어 (ne-NP, 데바나가리) — 일용직·제조 확장 대비. 쉬운 구어체. */
const ne: Record<MessageKey, string> = {
  brand: '작업온',
  kickerConfirmation: 'कामको पुष्टि पत्र',
  kickerShare: 'कागजात सेट',

  paperStamp: 'कामको पुष्टि पत्र',
  paperDate: 'काम गरेको मिति',
  paperTime: 'समय',
  paperSite: 'साइट',
  paperWorker: 'कामदार',
  paperOrderer: 'काम दिने',
  paperWork: 'कामको विवरण',
  paperEquipment: 'उपकरण',
  paperGuide: 'निर्देशक',
  amtBase: 'आधार',
  unitGongsu: 'gongsu',
  amtOvertime: 'ओभरटाइम',
  amtEarly: 'बिहान जल्दी',
  amtNight: 'रात',
  amtAllnight: 'रातभर',
  paperVat: 'भ्याट ({rate}%)',
  paperTotal: 'पाउने रकम',
  paperMemo: 'टिप्पणी',
  paperSignHead: 'काम दिनेको हस्ताक्षर',
  paperSignedBy: '{name} ले हस्ताक्षर गर्नुभयो',
  paperSignConfirmed: 'हस्ताक्षर भयो',

  paperTeam: 'टोली सूची',
  paperTeamName: 'नाम',
  paperTeamGongsu: 'कार्यदिन',
  paperTeamRate: 'दर',
  paperTeamAmount: 'रकम',
  paperTeamTotal: 'टोली कामको जम्मा',

  kickerContract: 'मानक श्रम सम्झौता',
  lcStamp: 'मानक श्रम सम्झौता',
  lcParties: 'सम्झौताका पक्षहरू',
  lcEmployer: 'रोजगारदाता (पक्ष क)',
  lcWorker: 'कामदार (पक्ष ख)',
  lcBizNumber: 'व्यवसाय दर्ता नम्बर',
  lcPeriod: 'श्रम सम्झौता अवधि',
  lcPeriodOpen: 'निश्चित अवधि नभएको · दैनिक',
  lcWorkplace: 'कार्यस्थल',
  lcJob: 'कामको विवरण',
  lcWorkTime: 'कार्य समय',
  lcBreak: 'विश्राम',
  lcWage: 'ज्याला',
  lcWageDaily: 'दैनिक ज्याला',
  lcWageHourly: 'घण्टा ज्याला',
  lcPayday: 'ज्याला भुक्तानी दिन',
  lcPayMethod: 'भुक्तानी विधि',
  lcAllowance: 'भत्ता',
  lcWeeklyHoliday:
    'साप्ताहिक बिदा भत्ता: हप्ताको तोकिएको कार्यदिन पूर्ण उपस्थित भएमा साप्ताहिक बिदा भत्ता दिइन्छ।',
  lcWeeklyHolidayNone: 'साप्ताहिक बिदा भत्ता: लागू हुँदैन (दैनिक/अल्पकालीन)।',
  lcOvertime:
    'ओभरटाइम, रात्री र बिदाको काममा श्रम ऐन अनुसार सामान्य ज्यालाको ५०% थप दिइन्छ।',
  lcOvertimeNone: 'ओभरटाइम/रात्री/बिदा थप भत्ता: छुट्टै तोकिएको छैन।',
  lcInsurance: 'सामाजिक बीमा लागू',
  lcInsEmployment: 'रोजगार बीमा',
  lcInsHealth: 'स्वास्थ्य बीमा',
  lcInsPension: 'राष्ट्रिय पेन्सन',
  lcInsAccident: 'दुर्घटना बीमा',
  lcApplied: 'लागू',
  lcNotApplied: 'लागू छैन',
  lcSpecial: 'विशेष सर्त',
  lcMasterNote:
    'यस सम्झौताको मूल प्रति कोरियाली भाषामा हो। अनुवाद बुझ्न सहयोगका लागि मात्र हो; व्याख्यामा भिन्नता भएमा कोरियाली प्रति मान्य हुन्छ।',
  lcEmployerSigned: 'रोजगारदाताले हस्ताक्षर गर्नुभयो',
  lcSignHeading: 'कृपया श्रम सम्झौतामा हस्ताक्षर गर्नुहोस्',
  lcSignLegal:
    'हस्ताक्षर गर्दा माथिका श्रम सर्तहरूमा सहमति जनाइन्छ र कानुनी मान्यता भएको अभिलेखका रूपमा रहन्छ।',
  lcSignFootnote:
    'हस्ताक्षर गरेपछि सम्झौता तुरुन्तै मान्य हुन्छ र दुवै पक्षमा राखिन्छ।',
  lcSignDoneReceived: 'श्रम सम्झौता हस्ताक्षर प्राप्त भयो',
  lcViewPdf: 'हस्ताक्षरित सम्झौता PDF हेर्नुहोस्',

  signHeading: 'यहाँ हस्ताक्षर गर्नुहोस्',
  signNameLabel: 'हस्ताक्षर गर्नेको नाम',
  signNamePlaceholder: 'जस्तै) राम बहादुर',
  signSignLabel: 'हस्ताक्षर',
  signPadHint: 'यहाँ औंला वा माउसले हस्ताक्षर गर्नुहोस्',
  signPadAria: 'हस्ताक्षर क्षेत्र',
  signRedraw: 'फेरि गर्नुहोस्',
  signSubmit: 'हस्ताक्षर गरी पुष्टि गर्नुहोस्',
  signSubmitting: 'पठाउँदै…',
  signFootnote: 'हस्ताक्षर गर्नेबित्तिकै दुवै पक्षका लागि पुष्टि पत्र मान्य हुन्छ',
  signLegal:
    'हस्ताक्षर गर्नुभयो भने माथिको कामको विवरण र पाउने रकममा सहमत हुनुभएको मानिन्छ। यो कानुनी रूपमा मान्य पुष्टि हो।',
  signErrName: 'हस्ताक्षर गर्नेको नाम लेख्नुहोस्।',
  signErrSign: 'कृपया हस्ताक्षर गर्नुहोस्।',
  signErrSubmit: 'हस्ताक्षर पठाउन सकिएन। केही बेरमा फेरि प्रयास गर्नुहोस्।',

  signDoneTitle: 'हस्ताक्षर पूरा भयो',
  signDoneBy: '{name} ले हस्ताक्षर गर्नुभयो',
  signDoneReceived: 'हस्ताक्षर प्राप्त भयो',
  signViewPdf: 'हस्ताक्षर गरिएको पुष्टि पत्र (PDF) हेर्नुहोस्',

  joinTitle: 'यो पुष्टि पत्र 작업온 मा व्यवस्थापन गर्नुहोस्',
  joinDesc:
    'प्राप्त पुष्टि पत्र र भुक्तानी विवरण स्वतः खातामा जम्मा हुन्छ। ठेकेदार हुनुहुन्छ भने प्राप्ति, भुक्तानी र सुरक्षा व्यवस्थापन एकै ठाउँमा।',
  joinCta: '작업온 सुरु गर्नुहोस्',

  shareCount: 'साझा गरिएका कागजात {n} वटा',
  shareValidUntil: '{date} सम्म हेर्न मिल्ने',
  shareExpiry: 'म्याद {date}',
  shareNoExpiry: 'म्याद छैन',
  docExpired: 'म्याद सकियो',
  shareMasked: 'ढाकिएको प्रति',
  shareView: 'हेर्नुहोस्',
  shareDownload: 'डाउनलोड',

  statusTransientTitle: 'अस्थायी त्रुटि',
  statusTransientMsg: 'केही बेरमा फेरि प्रयास गर्नुहोस्।',
  statusNotFoundTitle: 'लिंक भेटिएन',
  statusNotFoundMsg:
    'लिंकको म्याद सकिएको वा रद्द भएको हुन सक्छ। पठाउनेसँग नयाँ लिंक माग्नुहोस्।',
  statusRetry: 'फेरि प्रयास गर्नुहोस्',

  // QR 명함 공개 프로필 (P3b)
  kickerCard: 'कामदार कार्ड',
  cardValidDocs: 'कागजात मान्य',
  cardValidDocsDesc: 'म्याद तोकिएका सबै कागजात मान्य छन्।',
  cardIndustryTitle: 'पेशा',
  cardEquipmentTitle: 'उपकरण',
  cardJoined: '작업온 सामेल मिति',
  cardConnectTitle: 'यो कामदारसँग जोडिनुहोस्',
  cardConnectDesc:
    '작업온 एपमा फोन नम्बरबाट खोजेर जडान अनुरोध पठाउनुहोस्।',
  cardStoreIos: 'App Store',
  cardStoreAndroid: 'Google Play',

  langLabel: 'भाषा',
};

export default ne;
