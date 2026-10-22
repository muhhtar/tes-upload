import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/memory_model.dart';
import 'memory_providers.dart';

class MemoryDetailScreen extends ConsumerWidget {
  const MemoryDetailScreen({super.key, required this.memoryId});

  final String memoryId;

  Future<void> _deleteMemory(BuildContext context, WidgetRef ref, MemoryModel memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kenangan?'),
        content: const Text(
          'Kenangan ini dan media di dalamnya akan dihapus permanen. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final memoryRepo = ref.read(memoryRepositoryProvider);
        final storageRepo = ref.read(storageRepositoryProvider);

        // Delete associated files from storage
        for (final item in memory.media) {
          if (item.path.isNotEmpty) {
            await storageRepo.deleteFile(item.path);
          }
        }
        if (memory.aiIllustration != null && memory.aiIllustration!.path.isNotEmpty) {
          await storageRepo.deleteFile(memory.aiIllustration!.path);
        }

        await memoryRepo.deleteMemory(memory.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kenangan berhasil dihapus.')),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.pop();
          });
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus kenangan. Coba lagi.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final memoryState = ref.watch(memoryDetailProvider(memoryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kenangan'),
        actions: memoryState.asData?.value != null
            ? [
                IconButton(
                  tooltip: 'Ganti status favorit',
                  icon: Icon(
                    memoryState.asData!.value!.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: memoryState.asData!.value!.isFavorite
                        ? Colors.redAccent
                        : null,
                  ),
                  onPressed: () {
                    final current = memoryState.asData!.value!;
                    ref
                        .read(memoryRepositoryProvider)
                        .toggleFavorite(current.id, !current.isFavorite);
                  },
                ),
                IconButton(
                  tooltip: 'Ubah kenangan',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/memory/$memoryId/edit'),
                ),
                IconButton(
                  tooltip: 'Hapus kenangan',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteMemory(
                    context,
                    ref,
                    memoryState.asData!.value!,
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: memoryState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Kenangan tidak ditemukan atau terjadi kesalahan.',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          data: (memory) {
            if (memory == null) {
              return EmptyStateWidget(
                message: 'Kenangan ini sudah tidak ada.',
                actionLabel: 'Kembali',
                onAction: () => context.pop(),
              );
            }

            final photos = memory.media.where((m) => m.type == 'photo').toList();
            final audio = memory.media.where((m) => m.type == 'audio').firstOrNull;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Display AI Illustration if available
                if (memory.aiIllustration != null) ...[
                  PolaroidFrame(
                    imageUrl: memory.aiIllustration!.url,
                    caption: 'Gaya: ${memory.aiIllustration!.style}',
                    isAi: true,
                    height: 260,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else if (photos.isNotEmpty) ...[
                  // Display photos gallery
                  SizedBox(
                    height: 260,
                    child: PageView.builder(
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        if (index < 0 || index >= photos.length) {
                          return const SizedBox.shrink();
                        }
                        return PolaroidFrame(
                          imageUrl: photos[index].url,
                          caption: 'Foto ${index + 1} dari ${photos.length}',
                          height: 220,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Title & Date
                Text(
                  memory.title,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Chip(
                      label: Text(memory.category),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Chip(
                      label: Text('Suasana: ${memory.mood}'),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    Text(
                      _displayDate(memory.memoryDate),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Audio indicator / player if available
                if (audio != null) ...[
                  Card(
                    color: theme.colorScheme.secondaryContainer,
                    child: ListTile(
                      leading: Icon(
                        Icons.audiotrack,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      title: Text(
                        'Rekaman Suara',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Ukuran: ${(audio.size / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Story
                if (memory.story.isNotEmpty) ...[
                  Text(
                    memory.story,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Action to Lore Studio AI Illustration
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lore Studio AI',
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                memory.aiIllustration == null
                                    ? 'Buat ilustrasi bergaya dari ceritamu'
                                    : 'Buat ulang ilustrasi kenangan',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => context.push('/studio/${memory.id}'),
                          child: Text(
                            memory.aiIllustration == null ? 'Buat' : 'Ubah AI',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
