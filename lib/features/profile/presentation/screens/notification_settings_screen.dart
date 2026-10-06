import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notifications_service.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/widgets/location_access.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _nearby = false;
  bool _busy = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final prefs =
            await ref.read(notificationsServiceProvider).preferences();
        if (mounted) setState(() => _nearby = prefs['nearby'] == true);
      } catch (_) {}
    });
  }

  Future<void> _save(bool enable) async {
    setState(() => _busy = true);
    try {
      final service = ref.read(notificationsServiceProvider);
      if (enable && _nearby) await requestDeviceLocation(context, ref);
      final allowed = enable ? await service.enable(nearby: _nearby) : true;
      if (!enable) await service.disable();
      if (mounted) {
        setState(
          () => _message = allowed
              ? (enable ? 'Bildirimler etkin.' : 'Bildirimler kapatıldı.')
              : 'Bildirim izni verilmedi. Cihaz ayarlarından açabilirsin.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Bildirim kaydı yapılamadı. Bulut bağlantısını ve cihaz izinlerini kontrol et.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bildirimler')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Anına gelen yorumları bildirim olarak al.'),
            SwitchListTile.adaptive(
              title: const Text('Yakın anılar'),
              subtitle: const Text(
                'İzin verdiğin son konumun yakınındaki yeni herkese açık anılar için bildir.',
              ),
              value: _nearby,
              onChanged:
                  _busy ? null : (value) => setState(() => _nearby = value),
            ),
            FilledButton(
              onPressed: _busy ? null : () => _save(true),
              child: const Text('Bildirimleri etkinleştir'),
            ),
            TextButton(
              onPressed: _busy ? null : () => _save(false),
              child: const Text('Bildirimleri kapat'),
            ),
            if (_message != null) StatusNotice(message: _message!),
          ],
        ),
      );
}
