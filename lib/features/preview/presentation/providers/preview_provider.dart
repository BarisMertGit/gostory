// path: lib/features/preview/presentation/providers/preview_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/memory_creation_events.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/memories_provider.dart';
import '../../../../shared/widgets/location_chip.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../domain/memory_draft.dart';

/// Manages the preview state: note text, validation, and submission.
class PreviewNotifier extends StateNotifier<PreviewState> {
  PreviewNotifier({
    required this.photoPath,
    this.loadUser,
    this.saveDraft,
    this.onCreationEvent,
  }) : super(const PreviewState.initial());

  final String photoPath;
  final void Function(MemoryCreationEvent)? onCreationEvent;
  void _event(MemoryCreationPhase phase, {String? reason}) {
    try {
      onCreationEvent?.call(
        MemoryCreationEvent(
          phase: phase,
          isPublic: state.isPublic,
          reason: reason,
        ),
      );
    } catch (_) {
      // Observability must never interrupt a local save.
    }
  }

  final Future<void> Function(MemoryDraft)? saveDraft;
  final Future<LocalUser> Function()? loadUser;

  void setPublic(bool value) {
    if (!state.isSubmitting) state = state.copyWith(isPublic: value);
  }

  /// Updates the note text and revalidates.
  void updateNote(String text) {
    final trimmed = text.trim();
    final error = text.isEmpty ? null : text.noteValidationError;

    state = state.copyWith(
      noteText: text,
      validationError: error,
      isValid: trimmed.isValidNote,
    );
  }

  /// Attempts to submit the memory draft.
  ///
  /// Persists through the injected archive writer; failures stay on screen.
  Future<bool> submit() async {
    if (state.isSubmitting || state.isSubmitted) return false;
    final trimmed = state.noteText.trim();

    if (!trimmed.isValidNote) {
      state = state.copyWith(
        validationError: trimmed.noteValidationError ?? 'Bir not bırakmalısın.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true);
    _event(MemoryCreationPhase.started);

    LocalUser? user;
    try {
      user = await loadUser?.call();
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'preview_provider',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (!mounted) return false;
      _event(MemoryCreationPhase.failed, reason: 'profile_unavailable');
      state = state.copyWith(
        isSubmitting: false,
        validationError: 'Profil yüklenemedi. Tekrar dene.',
      );
      return false;
    }
    if (!mounted) return false;

    // Preserve the author identity when building the archive entry.
    final draft = MemoryDraft(
      photoPath: photoPath,
      note: trimmed,
      isPublic: state.isPublic,
      creatorId: user?.uid,
      creatorUsername: user?.username,
    );

    try {
      if (saveDraft != null) {
        await saveDraft!(draft);
      } else {
        throw StateError('Kayıt altyapısı bağlı değil.');
      }
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'preview_provider',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (!mounted) return false;
      _event(MemoryCreationPhase.failed, reason: 'local_save_failed');
      state = state.copyWith(
        isSubmitting: false,
        validationError: error is ValidationException
            ? error.message
            : 'Anı kaydedilemedi. Fotoğrafı, konumu ve boş alanı kontrol edip tekrar dene.',
      );
      return false;
    }

    if (!mounted) return false;
    state = state.copyWith(
      isSubmitting: false,
      isSubmitted: true,
    );

    _event(MemoryCreationPhase.saved);
    return true;
  }

  /// Resets the preview state for a new photo.
  void reset() {
    state = const PreviewState.initial();
  }
}

/// The state of the preview screen.
class PreviewState {
  const PreviewState({
    required this.noteText,
    required this.isValid,
    required this.isSubmitting,
    required this.isSubmitted,
    this.validationError,
    this.isPublic = false,
  });

  const PreviewState.initial()
      : noteText = '',
        isPublic = false,
        isValid = false,
        isSubmitting = false,
        isSubmitted = false,
        validationError = null;

  final String noteText;
  final bool isPublic;
  final bool isValid;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? validationError;

  PreviewState copyWith({
    String? noteText,
    bool? isPublic,
    bool? isValid,
    bool? isSubmitting,
    bool? isSubmitted,
    String? validationError,
  }) {
    return PreviewState(
      noteText: noteText ?? this.noteText,
      isPublic: isPublic ?? this.isPublic,
      isValid: isValid ?? this.isValid,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      validationError: validationError,
    );
  }
}

/// Provider factory — each preview screen gets its own notifier
/// scoped to a specific photo path.
final previewProvider = StateNotifierProvider.autoDispose
    .family<PreviewNotifier, PreviewState, String>(
  (ref, photoPath) => PreviewNotifier(
    photoPath: photoPath,
    onCreationEvent: ref.read(memoryCreationEventsProvider).emit,
    loadUser: () => ref.read(authServiceProvider).signIn(),
    saveDraft: (draft) async {
      final point = ref.read(draftLocationProvider);
      await ref.read(memoryStoreProvider).save(
            MemoryDraft(
              photoPath: draft.photoPath,
              note: draft.note,
              isPublic: draft.isPublic,
              creatorId: draft.creatorId,
              creatorUsername: draft.creatorUsername,
              latitude: point?.latitude,
              longitude: point?.longitude,
            ),
          );
      ref.invalidate(personalMemoriesProvider);
      ref.invalidate(mapProvider);
    },
  ),
);
