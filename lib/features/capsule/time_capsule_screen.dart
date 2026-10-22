import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/time_capsule_model.dart';
import 'capsule_providers.dart';

class TimeCapsuleScreen extends ConsumerStatefulWidget {
  const TimeCapsuleScreen({super.key});

  @override
  ConsumerState<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends ConsumerState<TimeCapsuleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateCapsuleDialog() {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedUnlockDate = DateTime.now().add(const Duration(days: 30));
    String selectedMood = 'hangat';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.hourglass_bottom,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Buat Kapsul Waktu',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tulis pesan atau catatan rahasia untuk kamu buka di masa depan.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Kapsul Waktu',
                        hintText: 'Contoh: Pesan untuk diriku di tahun depan',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Rahasia',
                        hintText: 'Tulis apa saja yang ingin kamu baca nanti...',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Tanggal Membuka: ${DateFormat('dd MMMM yyyy').format(selectedUnlockDate)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedUnlockDate,
                              firstDate: DateTime.now().add(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedUnlockDate = picked);
                            }
                          },
                          child: const Text('Ubah'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty ||
                              noteController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Judul dan catatan wajib diisi.'),
                              ),
                            );
                            return;
                          }

                          await ref
                              .read(timeCapsuleRepositoryProvider)
                              .createCapsule(
                                title: titleController.text,
                                note: noteController.text,
                                unlockAt: selectedUnlockDate,
                                mood: selectedMood,
                              );

                          if (context.mounted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) Navigator.pop(context);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kapsul waktu berhasil dibuat! ⏳'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.lock_clock),
                        label: const Text('Kunci Kapsul Waktu'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCapsule(TimeCapsuleModel capsule) {
    if (capsule.isLocked) {
      final daysRemaining = capsule.unlockAt.difference(DateTime.now()).inDays + 1;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.lock_clock,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(capsule.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kapsul waktu ini masih terkunci! 🔒',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Baru bisa dibuka pada ${DateFormat('dd MMMM yyyy').format(capsule.unlockAt)} (sekitar $daysRemaining hari lagi).',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } else {
      // Unlocked!
      if (!capsule.isOpened) {
        ref.read(timeCapsuleRepositoryProvider).openCapsule(capsule.id);
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: Colors.green,
          ),
          title: Text(capsule.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Catatan Kapsul Waktu:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  capsule.note,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai Membaca'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capsulesState = ref.watch(timeCapsulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kapsul Waktu'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.lock_outline), text: 'Terkunci'),
            Tab(icon: Icon(Icons.lock_open_outlined), text: 'Terbuka'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCapsuleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Kapsul Baru'),
      ),
      body: SafeArea(
        child: capsulesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => const Center(
            child: Text('Gagal memuat kapsul waktu.'),
          ),
          data: (capsules) {
            final locked = capsules.where((c) => c.isLocked).toList();
            final unlocked = capsules.where((c) => !c.isLocked).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                // Locked Tab
                locked.isEmpty
                    ? EmptyStateWidget(
                        message: 'Belum ada kapsul waktu yang terkunci.',
                        icon: Icons.hourglass_empty,
                        actionLabel: 'Buat Kapsul Waktu',
                        onAction: _showCreateCapsuleDialog,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: locked.length,
                        itemBuilder: (context, index) {
                          if (index < 0 || index >= locked.length) {
                            return const SizedBox.shrink();
                          }
                          final item = locked[index];
                          final daysLeft =
                              item.unlockAt.difference(DateTime.now()).inDays + 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.lock_clock,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(item.title),
                              subtitle: Text(
                                'Membuka ${DateFormat('dd MMM yyyy').format(item.unlockAt)} (sisa $daysLeft hari)',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openCapsule(item),
                            ),
                          );
                        },
                      ),

                // Unlocked Tab
                unlocked.isEmpty
                    ? const EmptyStateWidget(
                        message: 'Belum ada kapsul waktu yang sudah waktunya dibuka.',
                        icon: Icons.mark_email_read_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: unlocked.length,
                        itemBuilder: (context, index) {
                          if (index < 0 || index >= unlocked.length) {
                            return const SizedBox.shrink();
                          }
                          final item = unlocked[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: const Icon(
                                  Icons.key,
                                  color: Colors.green,
                                ),
                              ),
                              title: Text(item.title),
                              subtitle: Text(
                                item.isOpened ? 'Sudah Dibaca' : 'Bisa Dibuka Sekarang! 🎉',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _openCapsule(item),
                            ),
                          );
                        },
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
