import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/wallet.dart';
import '../../widgets/common.dart';
import 'upload_sheet.dart';

class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final equipments = ref.watch(equipmentsProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('장비 관리')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEquipment(context, ref),
        backgroundColor: c.primary,
        foregroundColor: c.primaryInk,
        icon: const Icon(Icons.add_rounded),
        label: const Text('장비 추가',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: equipments.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ErrorRetry(
                      boxed: false,
                      onRetry: () => ref.invalidate(equipmentsProvider)))),
          data: (list) => list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.agriculture_outlined, size: 64, color: c.ink3),
                      const SizedBox(height: 12),
                      Text('등록된 장비가 없어요',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.ink)),
                      const SizedBox(height: 4),
                      Text('굴삭기·지게차 등 장비를 등록하고 서류를 묶으세요',
                          style: TextStyle(fontSize: 14, color: c.ink2)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final eq = list[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                                color: c.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12)),
                            child:
                                Icon(Icons.agriculture_rounded, color: c.accentText),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(eq.vehicleNumber ?? eq.type,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: c.ink)),
                                const SizedBox(height: 2),
                                Text(
                                    '${eq.type}${eq.spec != null ? ' · ${eq.spec}' : ''} · 서류 ${eq.documentCount}건',
                                    style:
                                        TextStyle(fontSize: 13, color: c.ink2)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await runUploadFlow(context, ref);
                            },
                            child: const Text('서류'),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: c.ink3),
                            onPressed: () async {
                              await ref
                                  .read(walletRepoProvider)
                                  .deleteEquipment(eq.id);
                              invalidateWallet(ref);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _addEquipment(BuildContext context, WidgetRef ref) async {
    final typeCtl = TextEditingController();
    final vnoCtl = TextEditingController();
    final specCtl = TextEditingController();
    final c = context.c;
    try {
      final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 18,
            right: 18,
            top: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('장비 추가',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 14),
            _field(ctx, typeCtl, '장비 종류 (예: 굴삭기)'),
            const SizedBox(height: 10),
            _field(ctx, vnoCtl, '차량번호 (선택)'),
            const SizedBox(height: 10),
            _field(ctx, specCtl, '규격 (예: 06W) (선택)'),
            const SizedBox(height: 18),
            PrimaryButton(
                label: '추가',
                onPressed: () => Navigator.pop(ctx, true)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
      if (ok == true && typeCtl.text.trim().isNotEmpty) {
        await ref.read(walletRepoProvider).createEquipment(
              type: typeCtl.text.trim(),
              vehicleNumber: vnoCtl.text.trim(),
              spec: specCtl.text.trim(),
            );
        invalidateWallet(ref);
      }
    } finally {
      typeCtl.dispose();
      vnoCtl.dispose();
      specCtl.dispose();
    }
  }

  Widget _field(BuildContext context, TextEditingController ctl, String hint) {
    final c = context.c;
    return TextField(
      controller: ctl,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: c.fieldBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
      ),
    );
  }
}
