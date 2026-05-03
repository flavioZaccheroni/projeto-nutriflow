import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../data/models/history_event_model.dart';
import '../../../../data/repositories/history_repository.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = HistoryRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Historico')),
      body: StreamBuilder<List<HistoryEventModel>>(
        stream: repository.watchAll(),
        builder: (context, snapshot) {
          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum evento registrado ainda.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ResponsiveCenter(
            maxWidth: Responsive.contentMaxWidth(context),
            child: ListView.separated(
              padding: Responsive.pagePadding(context),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green.shade800,
                      child: Icon(_iconFor(event.type)),
                    ),
                    title: Text(event.description),
                    subtitle: Text(_formatDateTime(event.createdAt)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    if (type.startsWith('patient')) {
      return Icons.person_outline;
    }
    if (type.startsWith('meal_plan')) {
      return Icons.restaurant_menu;
    }
    return Icons.history;
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
