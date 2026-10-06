import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/core/services/interactions_service.dart';
import 'package:gostory/features/memory/presentation/memory_detail_screen.dart';
import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/interactions_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';

class _CommentAuth extends AuthService {
  @override
  Future<LocalUser> signIn() async =>
      const LocalUser(uid: 'visitor', username: 'gezgin');
}

class _CommentStore extends MemoryStore {
  @override
  Future<void> updateLocalViews(String id, int count) async {}
}

class _PendingComments extends InteractionsService {
  Completer<void> completion = Completer<void>();
  int sends = 0;
  final comments = <MemoryComment>[];

  @override
  Future<void> view(String id, String userId) async {}

  @override
  Future<MemoryInteractions> load(String id, String userId) async =>
      MemoryInteractions(comments: List.of(comments));

  @override
  Stream<MemoryInteractions> watch(String id, String userId) async* {
    yield await load(id, userId);
  }

  @override
  Future<void> comment(
    String id,
    String userId,
    String username,
    String value,
  ) async {
    sends++;
    await completion.future;
    comments.add(
      MemoryComment(
        username: username,
        text: value,
        createdAt: DateTime(2026, 10, 1, 14, 30),
      ),
    );
  }
}

void main() {
  Future<void> showDetail(
    WidgetTester tester,
    _PendingComments service, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_CommentAuth()),
          memoryStoreProvider.overrideWithValue(_CommentStore()),
          interactionsServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: true,),
            child: child!,
          ),
          home: MemoryDetailScreen(
            memory: Memory(
              id: 'memory',
              creatorId: 'author',
              creatorUsername: 'deniz',
              photoUrl: '',
              textNote: 'Güzel bir gün.',
              latitude: 41,
              longitude: 29,
              city: 'İstanbul',
              createdAt: DateTime(2026),
            ),
          ),
        ),
      ),
    );
    addTearDown(service.dispose);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Yorumu gönder').hitTestable(),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('keyboard sends once, shows progress and refreshes the comments',
      (tester) async {
    final service = _PendingComments();
    await showDetail(tester, service);
    final button = find.widgetWithText(FilledButton, 'Yorumu gönder');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '  Harika bir anı!  ');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(service.sends, 1);
    expect(find.text('Gönderiliyor…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    service.completion.complete();
    await tester.pumpAndSettle();
    expect(find.text('Yorumun gönderildi'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(service.comments.single.text, 'Harika bir anı!');
    expect(find.widgetWithText(Card, 'Harika bir anı!'), findsOneWidget);
    expect(find.textContaining('2026'), findsWidgets);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed comment preserves the draft and can be retried',
      (tester) async {
    final service = _PendingComments();
    await showDetail(tester, service);
    await tester.enterText(find.byType(TextField), 'Bir yorum');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Yorumu gönder');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    service.completion.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('İşlem tamamlanamadı. Tekrar dene.'), findsOneWidget);
    expect(find.text('Yorumun gönderildi'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Bir yorum',
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    service.completion = Completer<void>()..complete();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(service.sends, 2);
    expect(find.text('Yorumun gönderildi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'sticky comment controls remain usable on a short screen with large text and keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final service = _PendingComments();
    await showDetail(tester, service, textScale: 2);
    await tester.enterText(find.byType(TextField), 'Bu anıya bir yorum');
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await tester.pumpAndSettle();
    final send = find.widgetWithText(FilledButton, 'Yorumu gönder');
    expect(send.hitTestable(), findsOneWidget);
    expect(tester.getRect(send).bottom, lessThanOrEqualTo(368));
    await tester.tap(send);
    await tester.pump();
    expect(service.sends, 1);
    expect(find.text('Gönderiliyor…').hitTestable(), findsOneWidget);
    service.completion.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Bu anıya bir yorum',);
    expect(tester.takeException(), isNull);
  });
}
