import 'dart:async';

import '../material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'app_logo.dart';
import 'responsive.dart';

/// Layout shared by the auth screens (Create account, OTP, Password, Sign in):
/// a blue header with the logo and feature carousel, and a white card for the form.
/// On tablets the header becomes a left panel and the card sits on the right.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.initialSlide = 0});

  final Widget child;

  /// Which carousel slide the screen starts on (each Figma screen shows a different one).
  final int initialSlide;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.brandBlue,
          body: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= Breakpoints.wide
                ? _WideLayout(initialSlide: initialSlide, child: child)
                : _CompactLayout(initialSlide: initialSlide, child: child),
          ),
        ),
      );
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.child, required this.initialSlide});

  final Widget child;
  final int initialSlide;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  children: [
                    const AppLogo(size: 30),
                    const SizedBox(height: 22),
                    FeatureCarousel(initialSlide: initialSlide),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _AuthCard(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + MediaQuery.paddingOf(context).bottom),
              topOnly: true,
              child: child,
            ),
          ),
        ],
      );
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.child, required this.initialSlide});

  final Widget child;
  final int initialSlide;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            flex: 5,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(size: 40),
                      const SizedBox(height: 40),
                      FeatureCarousel(initialSlide: initialSlide, large: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: ColoredBox(
              color: AppColors.background,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _AuthCard(padding: const EdgeInsets.all(28), child: child),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

/// White card with the thin blue-to-green accent along its top edge.
class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child, required this.padding, this.topOnly = false});

  final Widget child;
  final EdgeInsets padding;
  final bool topOnly;

  @override
  Widget build(BuildContext context) {
    final radius = topOnly ? const BorderRadius.vertical(top: Radius.circular(24)) : BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.cardAccent, borderRadius: radius),
      child: Container(
        margin: const EdgeInsets.only(top: 3),
        padding: padding,
        decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
        child: child,
      ),
    );
  }
}

/// The three onboarding slides shown in the blue header.
class FeatureCarousel extends StatefulWidget {
  const FeatureCarousel({super.key, this.initialSlide = 0, this.large = false});

  final int initialSlide;
  final bool large;

  @override
  State<FeatureCarousel> createState() => _FeatureCarouselState();
}

class _FeatureCarouselState extends State<FeatureCarousel> {
  static const _slides = [
    _Slide('Flexible Loan Options', 'Loan types to cater to different financial needs', _SlideArt.options),
    _Slide('Instant Loan Approval', 'Users will receive approval within minutes', _SlideArt.approval),
    _Slide('24x7 Customer Care', 'Dedicated customer support team', _SlideArt.support),
  ];

  late final PageController _pages = PageController(initialPage: widget.initialSlide);
  late int _index = widget.initialSlide;
  Timer? _autoPlay;

  @override
  void initState() {
    super.initState();
    _autoPlay = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pages.hasClients) return;
      _pages.animateToPage((_index + 1) % _slides.length,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.large ? 1.25 : 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 222 * scale,
          child: PageView.builder(
            controller: _pages,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => _SlideView(slide: _slides[i], scale: scale),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: i == _index ? 1 : 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

enum _SlideArt { options, approval, support }

class _Slide {
  const _Slide(this.title, this.subtitle, this.art);

  final String title;
  final String subtitle;
  final _SlideArt art;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.scale});

  final _Slide slide;
  final double scale;

  // The artwork takes whatever height the text leaves and scales down to fit, so narrow
  // phones or large accessibility font sizes never overflow.
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: _art())),
          SizedBox(height: 18 * scale),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 16 * scale, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12 * scale),
          ),
        ],
      );

  Widget _art() => switch (slide.art) {
        _SlideArt.options => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                _tile(Icons.directions_car_outlined),
                SizedBox(width: 16 * scale),
                _tile(Icons.two_wheeler_outlined),
              ]),
              SizedBox(height: 16 * scale),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _tile(Icons.laptop_outlined),
                SizedBox(width: 16 * scale),
                _tile(Icons.smartphone_outlined),
              ]),
            ],
          ),
        _SlideArt.approval => _bigTile(Icons.receipt_long_outlined, Icons.verified_outlined),
        _SlideArt.support => _bigTile(Icons.support_agent_outlined, Icons.star_border_rounded),
      };

  Widget _tile(IconData icon) => Container(
        width: 64 * scale,
        height: 64 * scale,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 32 * scale),
      );

  Widget _bigTile(IconData icon, IconData accent) => Container(
        width: 148 * scale,
        height: 148 * scale,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: Colors.white, size: 54 * scale)),
            Positioned(
              right: 8 * scale,
              bottom: 8 * scale,
              child: Icon(accent, color: Colors.white.withValues(alpha: 0.3), size: 52 * scale),
            ),
          ],
        ),
      );
}
