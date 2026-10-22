import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/app_navigation_bar.dart';
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
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/timeline');
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
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
                        ref
                            .read(timelineCategoryProvider.notifier)
                            .setCategory(category);
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
                        if (index < 0 || index >= years.length) {
                          return const SizedBox.shrink();
                        }
                        final year = years[index];
                        final items = grouped[year];
                        if (items == null || items.isEmpty) {
                          return const SizedBox.shrink();
                        }

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
    final mediaLabel = hasAi
        ? 'Ilustrasi AI'
        : photo == null
        ? 'Tanpa foto'
        : 'Foto asli';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.push('/memory/${memory.id}');
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Semantics(
                label: '$mediaLabel untuk ${memory.title}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.small),
                  child: imageUrl == null || imageUrl.isEmpty
                      ? Container(
                          width: AppSpacing.xxl,
                          height: AppSpacing.xxl,
                          color: theme.colorScheme.secondaryContainer,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.auto_stories_outlined,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          width: AppSpacing.xxl,
                          height: AppSpacing.xxl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: AppSpacing.xxl,
                            height: AppSpacing.xxl,
                            color: theme.colorScheme.secondaryContainer,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
                      '${memory.category} · ${_displayDate(memory.memoryDate)} · $mediaLabel',
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
