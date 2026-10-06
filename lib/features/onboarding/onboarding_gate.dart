import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/home_screen.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/design.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart' as app_type;
import '../../core/utils/logger.dart';
import '../../shared/widgets/app_components.dart';
import '../../shared/widgets/motion_widgets.dart';

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
    if (_busy) return;
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
    return _OnboardingFlow(
      onFinish: _finish,
      onSkip: _finish,
      busy: _busy,
      error: _error,
    );
  }
}

class _OnboardingFlow extends StatefulWidget {
  const _OnboardingFlow({
    required this.onFinish,
    required this.onSkip,
    required this.busy,
    this.error,
  });
  final VoidCallback onFinish;
  final VoidCallback onSkip;
  final bool busy;
  final String? error;

  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.add_a_photo_outlined,
      title: 'Bir fotoğraf çek',
      description: 'Paylaş sekmesinden kamerayı aç ve anını yakala.',
      gradientColor: Color(0xFF1A3228),
    ),
    _OnboardingPage(
      icon: Icons.edit_location_alt_outlined,
      title: 'Notunu ve konumunu ekle',
      description:
          'Kısa bir not yaz; konum erişimiyle anını haritaya yerleştir.',
      gradientColor: Color(0xFF1B2E30),
    ),
    _OnboardingPage(
      icon: Icons.explore_outlined,
      title: 'Keşfet ve yeniden bul',
      description:
          'Anıların cihazında saklanır. Haritada başkalarının anılarını keşfet.',
      gradientColor: Color(0xFF2A1F1F),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(page,
          duration: AppMotion.emphasized, curve: AppMotion.standardCurve,);
    }
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _goTo(_page + 1);
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: TextButton(
                  onPressed: widget.busy ? null : widget.onSkip,
                  child: const Text(
                    'Atla',
                    style: TextStyle(
                      fontFamily: app_type.AppTypography.body,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return AnimatedBuilder(
                    animation: _pageController,
                    child: _OnboardingPageView(page: page),
                    builder: (_, child) {
                      final offset = _pageController.hasClients &&
                              _pageController.position.hasContentDimensions
                          ? ((_pageController.page ?? _page.toDouble()) - index)
                              .abs()
                              .clamp(0.0, 1.0)
                          : 0.0;
                      return Opacity(
                          opacity: MediaQuery.disableAnimationsOf(context)
                              ? 1
                              : 1 - offset * .6,
                          child: child,);
                    },
                  );
                },
              ),
            ),
            // Page indicator
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Semantics(
                    selected: index == _page,
                    label: '${index + 1}. sayfa',
                    child: SizedBox.square(
                        dimension: 44,
                        child: TextButton(
                          onPressed: widget.busy
                              ? null
                              : () => _goTo(index),
                          child: AnimatedContainer(
                            duration: AppMotion.duration(context),
                            width: index == _page ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: index == _page
                                    ? AppColors.peach
                                    : AppColors.surfaceVariant,),
                          ),
                        ),),
                  ),
                ),
              ),
            ),
            // Error
            if (widget.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: StatusNotice(
                    message: widget.error!, kind: StatusKind.error,),
              ),
            // Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryAction(
                  label: isLast ? 'Başla' : 'Devam',
                  busy: widget.busy,
                  busyLabel: 'Hazırlanıyor…',
                  onPressed: _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColor,
  });
  final IconData icon;
  final String title;
  final String description;
  final Color gradientColor;
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return AdaptiveStateBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(alignment: Alignment.bottomRight, children: [
            const JournalIllustration(size: 180),
            Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [AppColors.peachLight, AppColors.peach],),),
                child: Icon(page.icon, size: 28, color: AppColors.onPeach),),
          ],),
          const SizedBox(height: AppSpacing.xl),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
