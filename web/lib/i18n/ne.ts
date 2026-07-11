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
  shareMasked: 'ढाकिएको प्रति',
  shareView: 'हेर्नुहोस्',
  shareDownload: 'डाउनलोड',

  statusTransientTitle: 'अस्थायी त्रुटि',
  statusTransientMsg: 'केही बेरमा फेरि प्रयास गर्नुहोस्।',
  statusNotFoundTitle: 'लिंक भेटिएन',
  statusNotFoundMsg:
    'लिंकको म्याद सकिएको वा रद्द भएको हुन सक्छ। पठाउनेसँग नयाँ लिंक माग्नुहोस्।',
  statusRetry: 'फेरि प्रयास गर्नुहोस्',

  langLabel: 'भाषा',
};

export default ne;
