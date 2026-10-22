import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/memory_model.dart';
import 'memory_providers.dart';

const _categories = [
  'Semua',
  'Nasihat',
  'Liburan',
  'Lucu',
  'Keluarga',
  'Teman',
  'Lainnya',
];

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(timelineCategoryProvider);
    final memoriesState = ref.watch(timelineMemoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Linimasa Kenangan'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(category),
                      onSelected: (_) {
                        ref.read(timelineCategoryProvider.notifier).state = category;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: memoriesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Gagal memuat linimasa. Coba cek koneksi lalu ulangi.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                data: (memories) {
                  if (memories.isEmpty) {
                    return EmptyStateWidget(
                      message: selectedCategory == 'Semua'
                          ? 'Belum ada kenangan. Yuk, simpan kenangan pertamamu!'
                          : 'Belum ada kenangan di kategori "$selectedCategory".',
                      actionLabel: 'Kenangan baru',
                      onAction: () => context.push('/memories/new'),
                    );
                  }

                  // Group memories by year
                  final grouped = <int, List<MemoryModel>>{};
                  for (final memory in memories) {
                    final year = memory.memoryDate.year;
                    grouped.putIfAbsent(year, () => []).add(memory);
                  }

                  final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(timelineMemoriesProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: years.length,
                      itemBuilder: (context, index) {
                        final year = years[index];
                        final items = grouped[year]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '$year',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Divider(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...items.map(
                              (memory) => _TimelineItemCard(memory: memory),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItemCard extends StatelessWidget {
  const _TimelineItemCard({required this.memory});

  final MemoryModel memory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAi = memory.aiIllustration != null;
    final photo = memory.media.where((m) => m.type == 'photo').firstOrNull;
    final imageUrl = hasAi ? memory.aiIllustration!.url : photo?.url;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: () => context.push('/memory/${memory.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: theme.colorScheme.secondaryContainer,
                      child: const Icon(Icons.bookmark_outline),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            memory.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (memory.isFavorite)
                          const Icon(
                            Icons.favorite,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      '${memory.category} · ${_displayDate(memory.memoryDate)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (memory.story.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        memory.story,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayDate(MemoryDate date) {
    if (date.precision == 'year' || date.month == null) {
      return '${date.year}';
    }
    final month = date.month.toString().padLeft(2, '0');
    if (date.precision != 'day' || date.day == null) {
      return '$month/${date.year}';
    }
    return '${date.day.toString().padLeft(2, '0')}/$month/${date.year}';
  }
}
