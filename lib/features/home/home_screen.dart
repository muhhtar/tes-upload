import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/widgets/app_navigation_bar.dart';
import '../../data/models/memory_model.dart';
import '../auth/auth_error_message.dart';
import '../auth/auth_providers.dart';
import '../memories/memory_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _navigate(BuildContext context, String path) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.push(path);
    });
  }

  void _goTo(BuildContext context, String path) {
    context.go(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).asData?.value;
    final userId = user?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final memories = ref.watch(recentMemoriesProvider);
    final firstName = user?.displayName?.trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lore'),
        actions: [
          IconButton(
            tooltip: theme.brightness == Brightness.dark
                ? 'Ganti ke tema terang'
                : 'Ganti ke tema gelap',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Linimasa Kenangan',
            onPressed: () => _goTo(context, '/timeline'),
            icon: const Icon(Icons.timeline_outlined),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            onPressed: () => _goTo(context, '/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Keluar dari akun',
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              _goTo(context, '/home');
              break;
            case 1:
              _goTo(context, '/timeline');
              break;
            case 2:
              _goTo(context, '/settings');
              break;
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigate(context, '/memories/new'),
        icon: const Icon(Icons.add),
        label: const Text('Kenangan baru'),
      ),
      body: SafeArea(
        child: memories.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _LoadError(
            error: error,
            onRetry: () => ref.invalidate(recentMemoriesProvider),
          ),
          data: (items) {
            final greeting = _greeting(DateTime.now().hour);
            final name = firstName == null || firstName.isEmpty
                ? 'kamu'
                : firstName;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.fabClearance,
              ),
              children: [
                Text(
                  '$greeting, $name!',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Cerita kecilmu pantas disimpan.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                _LoreTodayCard(
                  memory: _pickTodayMemory(items, userId),
                  onCreate: () => _navigate(context, '/memories/new'),
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Kategori', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        const [
                          'Nasihat',
                          'Liburan',
                          'Lucu',
                          'Keluarga',
                          'Teman',
                          'Lainnya',
                        ].map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: ActionChip(
                              label: Text(category),
                              onPressed: () {
                                ref
                                    .read(timelineCategoryProvider.notifier)
                                    .setCategory(category);
                                _goTo(context, '/timeline');
                              },
                            ),
                          );
                        }).toList(),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Terbaru', style: theme.textTheme.titleLarge),
                    TextButton(
                      onPressed: () => _goTo(context, '/timeline'),
                      child: const Text('Lihat semua'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (items.isEmpty)
                  const _EmptyMemories()
                else
                  ...items
                      .take(5)
                      .map(
                        (memory) => _RecentMemoryCard(
                          memory: memory,
                          onTap: () =>
                              _navigate(context, '/memory/${memory.id}'),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 11) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 19) return 'Sore';
    return 'Malam';
  }

  MemoryModel? _pickTodayMemory(List<MemoryModel> memories, String userId) {
    if (memories.isEmpty) return null;
    final now = DateTime.now();
    final dayIndex = now.difference(DateTime(now.year)).inDays;
    final rawIndex = (dayIndex + userId.hashCode) % memories.length;
    final index = rawIndex < 0 ? rawIndex + memories.length : rawIndex;
    return memories[index];
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) context.go('/login');
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;
      _showSignOutError(context, error);
    } on GoogleSignInException catch (error) {
      if (!context.mounted) return;
      _showSignOutError(context, error);
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      _showSignOutError(context, error);
    }
  }

  void _showSignOutError(BuildContext context, Object error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
  }
}

class _LoreTodayCard extends StatelessWidget {
  const _LoreTodayCard({required this.memory, required this.onCreate});

  final MemoryModel? memory;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memory = this.memory;
    final illustration = memory?.aiIllustration;
    final photo = memory?.media
        .where((item) => item.type == 'photo')
        .firstOrNull;
    final imageUrl = illustration?.url ?? photo?.url;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: memory == null
            ? null
            : () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.push('/memory/${memory.id}');
                });
              },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Lore Hari Ini', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (memory == null) ...[
                Text(
                  'Belum ada kenangan buat dikenang lagi. Yuk, simpan yang pertama!',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: onCreate,
                  child: const Text('Tulis kenangan'),
                ),
              ] else ...[
                Semantics(
                  label: 'Gambar kenangan ${memory.title}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.small),
                    child: imageUrl == null || imageUrl.isEmpty
                        ? Container(
                            height: AppSpacing.xxl * 3,
                            color: theme.colorScheme.secondaryContainer,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.auto_stories_outlined,
                              size: AppSpacing.xxl,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            height: AppSpacing.xxl * 3,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: AppSpacing.xxl * 3,
                                  color: theme.colorScheme.secondaryContainer,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(memory.title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_displayMemoryDate(memory.memoryDate)} · ${memory.category} · ${memory.mood}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  memory.story.isEmpty
                      ? 'Satu momen yang berarti buat kamu.'
                      : memory.story,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _displayMemoryDate(MemoryDate date) {
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

class _RecentMemoryCard extends StatelessWidget {
  const _RecentMemoryCard({required this.memory, required this.onTap});

  final MemoryModel memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            Icons.book_outlined,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(memory.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${memory.category} · ${_displayMemoryYear(memory.memoryDate)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  String _displayMemoryYear(MemoryDate date) {
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

class _EmptyMemories extends StatelessWidget {
  const _EmptyMemories();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Belum ada kenangan di sini. Tekan “Kenangan baru” buat mulai nyimpen cerita.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry, this.error});

  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kenangan belum bisa dimuat. Coba cek koneksi lalu ulangi ya.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (error != null && kDebugMode) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
