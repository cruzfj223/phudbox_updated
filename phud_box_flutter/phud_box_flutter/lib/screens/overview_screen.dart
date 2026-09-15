import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/info_row.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  String _mmss(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final disinfecting = state.status == DeviceStatus.disinfecting;
    final batch = state.activeBatch;
    final etaMin = (state.secondsLeft / 60).ceil();
    final estCycles = state.battery > 0 ? (state.battery / 8).round().clamp(1, 99) : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.battery_full_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.battery}% Battery | Est. $estCycles Cycles',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      const Text('Device ID: MED-UV-001',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: const Icon(Icons.visibility_rounded, color: AppColors.accent, size: 18),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SYSTEM STATUS:',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1)),
                    Text(
                      disinfecting ? 'DISINFECTING' : 'IDLE',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Batch Information:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 10),
                InfoRow(label: 'Batch ID:', value: batch?.id ?? '--'),
                InfoRow(label: 'Batch Color:', value: batch?.color ?? '--'),
                InfoRow(
                    label: 'Instruments:',
                    value: batch != null ? batch.instruments.join(', ') : '--'),
                InfoRow(label: 'UV-C Intensity:', value: batch?.uvIntensity ?? '--'),
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                      Text(
                        disinfecting ? _mmss(state.secondsLeft) : '--:--',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 42,
                            letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remaining Time | ETA: ${disinfecting ? '$etaMin MINS' : '--'}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
