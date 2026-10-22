import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/common_widgets.dart';
import '../memories/memory_providers.dart';

const _styles = [
  {
    'key': 'watercolor',
    'label': 'Cat Air',
    'desc': 'Nuansa lembut & hangat ala lukisan cat air sepia.',
    'icon': Icons.palette_outlined,
  },
  {
    'key': 'pencil',
    'label': 'Sketsa Pensil',
    'desc': 'Goresan pensil halus di kertas krem yang hangat.',
    'icon': Icons.edit_note_outlined,
  },
  {
    'key': 'vintage',
    'label': 'Foto Klasik',
    'desc': 'Gaya foto terawat ala tahun 90-an dengan grain film.',
    'icon': Icons.camera_roll_outlined,
  },
  {
    'key': 'storybook',
    'label': 'Buku Cerita',
    'desc': 'Ilustrasi cerita dongeng yang imajinatif & ceria.',
    'icon': Icons.auto_stories_outlined,
  },
];

class LoreStudioScreen extends ConsumerStatefulWidget {
  const LoreStudioScreen({super.key, required this.memoryId});

  final String memoryId;

  @override
  ConsumerState<LoreStudioScreen> createState() => _LoreStudioScreenState();
}

class _LoreStudioScreenState extends ConsumerState<LoreStudioScreen> {
  String _selectedStyle = 'watercolor';
  bool _isGenerating = false;
  String? _previewUrl;
  String? _errorMessage;

  final List<String> _loadingMessages = const [
    'Lagi nyeduh warna...',
    'Bentar, lagi gambar lore kamu...',
    'Menghidupkan kenanganmu...',
    'Sedikit sentuhan terakhir...',
  ];
  int _loadingMsgIndex = 0;

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _previewUrl = null;
      _loadingMsgIndex = 0;
    });

    try {
      final repo = ref.read(illustrationRepositoryProvider);
      final result = await repo.generateIllustration(
        memoryId: widget.memoryId,
        style: _selectedStyle,
      );

      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _previewUrl = result['url'] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _discard() async {
    try {
      await ref.read(memoryRepositoryProvider).removeIllustration(widget.memoryId);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) context.pop();
    }
  }

  void _keep() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ilustrasi AI berhasil diterapkan!')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lore Studio AI'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Ubah ceritamu jadi ilustrasi AI',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pilih gaya gambar yang cocok dengan kenanganmu.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            if (_isGenerating) ...[
              Container(
                height: 260,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      _loadingMessages[_loadingMsgIndex],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ] else if (_previewUrl != null) ...[
              PolaroidFrame(
                imageUrl: _previewUrl!,
                caption: 'Gaya: $_selectedStyle',
                isAi: true,
                height: 260,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _discard,
                      child: const Text('Buang'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _generate,
                      child: const Text('Ulangi'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _keep,
                      child: const Text('Pakai'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            Text(
              'Pilihan Gaya Ilustrasi',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),

            ..._styles.map((style) {
              final isSelected = _selectedStyle == style['key'];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    style['icon'] as IconData,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    style['label'] as String,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(style['desc'] as String),
                  trailing: Radio<String>(
                    value: style['key'] as String,
                    groupValue: _selectedStyle,
                    onChanged: _isGenerating
                        ? null
                        : (val) {
                            if (val != null) setState(() => _selectedStyle = val);
                          },
                  ),
                  onTap: _isGenerating
                      ? null
                      : () {
                          setState(() => _selectedStyle = style['key'] as String);
                        },
                ),
              );
            }),

            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generate,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_previewUrl != null ? 'Buat Ulang Ilustrasi' : 'Buat Ilustrasi AI'),
            ),
          ],
        ),
      ),
    );
  }
}
