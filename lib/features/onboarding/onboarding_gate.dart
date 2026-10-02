import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/home_screen.dart';
import '../../core/utils/logger.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});
  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _complete;
  bool _busy = false;
  String? _error;

  Future<File> _marker() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}/onboarding_complete');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var complete = false;
    try {
      complete = await (await _marker()).exists();
    } catch (error, stack) {
      AppLogger.error(
        'İlk kullanım bilgisi okunamadı.',
        error: error.runtimeType,
        stackTrace: stack,
      );
    }
    if (mounted) setState(() => _complete = complete);
  }

  Future<void> _finish() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (await _marker()).writeAsString('1', flush: true);
      if (mounted) setState(() => _complete = true);
    } catch (error, stack) {
      AppLogger.error(
        'İlk kullanım bilgisi kaydedilemedi.',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (mounted) {
        setState(
          () => _error =
              'Tercihin kaydedilemedi. Tekrar deneyebilir veya devam edebilirsin.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_complete == true) return const HomeScreen();
    if (_complete == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const SizedBox(height: 40),
            Text(
              'Anılarına bir yer bırak.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            const ListTile(
              leading: Icon(Icons.add_a_photo_outlined),
              title: Text('Bir fotoğraf çek veya seç'),
              subtitle: Text('Paylaş sekmesinden kamerayı aç ve fotoğraf çek.'),
            ),
            const ListTile(
              leading: Icon(Icons.edit_location_alt_outlined),
              title: Text('Notunu ve konumunu ekle'),
              subtitle: Text(
                'Kısa bir not yaz; konum erişimiyle anını haritaya yerleştir.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.photo_library_outlined),
              title: Text('Haritada ve profilinde yeniden bul'),
              subtitle: Text(
                'Anıların bu cihazda saklanır. Henüz bulut yedekleme ve herkese açık paylaşım yok.',
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) Text(_error!),
            FilledButton(
              onPressed: _busy ? null : _finish,
              child: Text(_busy ? 'Hazırlanıyor…' : 'Başla'),
            ),
            if (_error != null)
              TextButton(
                onPressed: () => setState(() => _complete = true),
                child: const Text('Kaydetmeden devam et'),
              ),
          ],
        ),
      ),
    );
  }
}
