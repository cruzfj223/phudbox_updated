import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/batch.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/info_row.dart';
import '../widgets/status_badge.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<AppState>().logs;

    if (logs.isEmpty) {
      return const Center(
        child: Text('No completed cycles yet.', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      itemCount: logs.length,
      itemBuilder: (context, i) => _LogCard(log: logs[i]),
    );
  }
}

class _LogCard extends StatelessWidget {
  final BatchLog log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batch ID ${log.id} | ${log.color} | ${log.date}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Results:',
                  style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
              StatusBadge(result: log.result),
            ],
          ),
          const SizedBox(height: 8),
          InfoRow(label: 'Instruments:', value: log.instruments),
          InfoRow(label: 'Time:', value: log.time),
          InfoRow(label: 'UV-C Intensity:', value: log.uvIntensity),
          if (log.expiry != null) InfoRow(label: 'Expiry:', value: log.expiry!),
          if (log.error != null)
            InfoRow(label: 'Error:', value: log.error!, valueColor: const Color(0xFFE78585)),
        ],
      ),
    );
  }
}
