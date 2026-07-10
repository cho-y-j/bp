import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/mask_geometry.dart';
import '../models/models.dart';
import 'auth.dart';
import 'data.dart';

/// 내 서류 목록.
final documentsProvider = FutureProvider<List<DocumentItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/documents');
  final items = (res as Map)['items'] as List? ?? [];
  return items.map((e) => DocumentItem.fromJson(e as Map)).toList();
});

/// 내 장비 목록.
final equipmentsProvider = FutureProvider<List<EquipmentItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/equipments');
  final list = res is List ? res : (res as Map)['items'] as List? ?? [];
  return list.map((e) => EquipmentItem.fromJson(e as Map)).toList();
});

/// 내 공유 목록.
final mySharesProvider = FutureProvider<List<ShareItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/document-shares');
  final items = (res as Map)['items'] as List? ?? [];
  return items.map((e) => ShareItem.fromJson(e as Map)).toList();
});

void invalidateWallet(WidgetRef ref) {
  ref.invalidate(documentsProvider);
  ref.invalidate(equipmentsProvider);
  ref.invalidate(mySharesProvider);
  ref.invalidate(expiringDocsProvider);
}

/// 서류 지갑 쓰기 액션.
class WalletRepo {
  final ApiClient api;
  WalletRepo(this.api);

  /// 업로드(multipart). [bytes]+[filename]+[mime] 로 전송.
  Future<DocumentItem> upload({
    required Uint8List bytes,
    required String filename,
    required String mime,
    required String type,
    String ownerType = 'PROFILE',
    String? equipmentId,
    String? issueDate,
    String? expiryDate,
  }) async {
    final form = FormData.fromMap({
      'type': type,
      'ownerType': ownerType,
      'equipmentId': ?equipmentId,
      'issueDate': ?issueDate,
      'expiryDate': ?expiryDate,
      'file': MultipartFile.fromBytes(bytes,
          filename: filename, contentType: DioMediaType.parse(mime)),
    });
    final res = await api.postMultipart('/documents', form);
    return DocumentItem.fromJson(res as Map);
  }

  Future<DocumentItem> updateExpiry(String id, String? expiryDate) async {
    final res = await api.patch('/documents/$id',
        body: {'expiryDate': expiryDate});
    return DocumentItem.fromJson(res as Map);
  }

  Future<void> deleteDocument(String id) => api.delete('/documents/$id');

  Future<void> mask(String id, List<MaskRegion> regions) =>
      api.post('/documents/$id/mask',
          body: {'regions': regions.map((r) => r.toJson()).toList()});

  /// 묶음 공유 생성.
  Future<ShareResult> createShare({
    required List<String> documentIds,
    required int expiresInDays,
    List<Map<String, dynamic>>? perDocument,
  }) async {
    final res = await api.post('/document-shares', body: {
      'documentIds': documentIds,
      'expiresInDays': expiresInDays,
      'perDocument': ?perDocument,
    });
    return ShareResult.fromJson(res as Map);
  }

  Future<void> revokeShare(String id) => api.delete('/document-shares/$id');

  // 장비 CRUD
  Future<EquipmentItem> createEquipment(
      {required String type, String? vehicleNumber, String? spec}) async {
    final res = await api.post('/equipments', body: {
      'type': type,
      if (vehicleNumber != null && vehicleNumber.isNotEmpty)
        'vehicleNumber': vehicleNumber,
      if (spec != null && spec.isNotEmpty) 'spec': spec,
    });
    return EquipmentItem.fromJson(res as Map);
  }

  Future<void> deleteEquipment(String id) => api.delete('/equipments/$id');

  /// 인증 blob 으로 서류 원본/미리보기 바이트 수신.
  Future<Uint8List> fileBytes(String id, {String variant = 'original'}) async {
    final bytes = await api.getBytes('/documents/$id/file',
        query: {'variant': variant});
    return Uint8List.fromList(bytes);
  }
}

final walletRepoProvider =
    Provider<WalletRepo>((ref) => WalletRepo(ref.watch(apiClientProvider)));
