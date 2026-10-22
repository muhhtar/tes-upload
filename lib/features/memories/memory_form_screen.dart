import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/utils/validators.dart';
import '../../data/models/memory_model.dart';
import 'memory_providers.dart';

const _categories = [
  'Nasihat',
  'Liburan',
  'Lucu',
  'Keluarga',
  'Teman',
  'Lainnya',
];
const _moods = ['hangat', 'haru', 'lucu', 'rindu', 'bangga'];

class MemoryFormScreen extends ConsumerStatefulWidget {
  const MemoryFormScreen({super.key, this.memoryId});

  final String? memoryId;

  @override
  ConsumerState<MemoryFormScreen> createState() => _MemoryFormScreenState();
}

class _MemoryFormScreenState extends ConsumerState<MemoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  late DateTime _memoryDate;
  String _precision = 'day';
  String _category = _categories.first;
  String _mood = _moods.first;
  bool _isSaving = false;
  bool _isLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _memoryDate = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded && widget.memoryId != null) {
      _loadExistingMemory();
    }
  }

  void _loadExistingMemory() {
    final memoryState = ref.read(memoryDetailProvider(widget.memoryId!));
    final memory = memoryState.asData?.value;
    if (memory != null) {
      _titleController.text = memory.title;
      _storyController.text = memory.story;
      if (_categories.contains(memory.category)) {
        _category = memory.category;
      }
      if (_moods.contains(memory.mood)) {
        _mood = memory.mood;
      }
      if (['year', 'month', 'day'].contains(memory.memoryDate.precision)) {
        _precision = memory.memoryDate.precision;
      }
      _memoryDate = DateTime(
        memory.memoryDate.year,
        memory.memoryDate.month ?? 1,
        memory.memoryDate.day ?? 1,
      );
      _isLoaded = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _memoryDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Pilih tanggal kenangan',
    );
    if (selected != null && mounted) {
      setState(() => _memoryDate = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final memoryDate = MemoryDate(
      year: _memoryDate.year,
      month: _precision == 'year' ? null : _memoryDate.month,
      day: _precision == 'day' ? _memoryDate.day : null,
      precision: _precision,
    );

    try {
      final repo = ref.read(memoryRepositoryProvider);
      if (widget.memoryId == null) {
        await repo.createMemory(
          title: _titleController.text,
          story: _storyController.text,
          memoryDate: memoryDate,
          category: _category,
          mood: _mood,
        );
      } else {
        await repo.updateMemory(
          id: widget.memoryId!,
          title: _titleController.text,
          story: _storyController.text,
          memoryDate: memoryDate,
          category: _category,
          mood: _mood,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.memoryId == null
                ? 'Kenanganmu berhasil disimpan!'
                : 'Kenanganmu berhasil diperbarui!',
          ),
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    } on FirebaseException catch (error) {
      _showError(memoryErrorMessage(error));
    } on StateError catch (error) {
      _showError(error.message.toString());
    } on ArgumentError catch (error) {
      _showError(
        error.message?.toString() ?? 'Periksa lagi isi kenanganmu ya.',
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Memory form',
          context: ErrorDescription('while saving a memory'),
        ),
      );
      _showError('Kenangan belum berhasil disimpan. Coba lagi ya.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _errorMessage = message;
    });
  }

  String get _formattedDate {
    final month = _memoryDate.month.toString().padLeft(2, '0');
    final day = _memoryDate.day.toString().padLeft(2, '0');
    return switch (_precision) {
      'year' => '${_memoryDate.year}',
      'month' => '$month/${_memoryDate.year}',
      _ => '$day/$month/${_memoryDate.year}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.memoryId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah kenangan' : 'Kenangan baru'),
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: _isSaving ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: AppSpacing.lg,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Simpan perubahan' : 'Simpan kenangan'),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                isEdit ? 'Perbarui cerita kenanganmu.' : 'Tulis ceritanya, biar tetap ada.',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_errorMessage case final message?) ...[
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      message,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ],
              TextFormField(
                controller: _titleController,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Judul kenangan',
                  hintText: 'Contoh: Liburan pertama bareng teman',
                  prefixIcon: Icon(Icons.bookmark_outline),
                ),
                validator: Validators.memoryTitle,
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                'Tulis kenanganmu',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _storyController,
                minLines: 5,
                maxLines: 10,
                maxLength: 5000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Ceritain kenangannya',
                  hintText: 'Apa yang terjadi? Kenapa momen ini berarti?',
                  alignLabelWithHint: true,
                ),
                validator: Validators.memoryStory,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Tanggal perkiraan', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _precision,
                      decoration: const InputDecoration(
                        labelText: 'Ketelitian',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'year', child: Text('Tahun saja')),
                        DropdownMenuItem(value: 'month', child: Text('Bulan')),
                        DropdownMenuItem(value: 'day', child: Text('Tanggal')),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _precision = value);
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _chooseDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(_formattedDate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _category = value);
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _mood,
                decoration: const InputDecoration(
                  labelText: 'Suasana hati',
                  prefixIcon: Icon(Icons.mood_outlined),
                ),
                items: _moods
                    .map(
                      (mood) => DropdownMenuItem(
                        value: mood,
                        child: Text(mood[0].toUpperCase() + mood.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _mood = value);
                      },
              ),

              if (isEdit) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => context.push('/studio/${widget.memoryId}'),
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('🎨 Buat Ilustrasi Visual AI (Lore Studio)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String memoryErrorMessage(FirebaseException error) {
  return switch (error.code) {
    'permission-denied' =>
      'Kenangan belum bisa disimpan. Cek akses akunmu lalu coba lagi.',
    'unavailable' || 'network-request-failed' =>
      'Koneksi lagi bermasalah. Coba simpan lagi saat online ya.',
    _ => 'Kenangan belum berhasil disimpan. Coba lagi ya.',
  };
}
