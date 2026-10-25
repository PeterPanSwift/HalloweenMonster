import 'package:flutter/material.dart';

import '../data/monsters.dart';
import '../theme.dart';
import '../widgets/scare_meter.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.monster});

  final Monster monster;

  Monster get _next =>
      monsters[(monsters.indexOf(monster) + 1) % monsters.length];

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: CustomScrollView(
        key: const Key('detailScroll'),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: height * 0.5,
            backgroundColor: Spooky.night,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: BackButton(
                  key: const Key('backButton'),
                  color: Spooky.moon,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'img-${monster.id}',
                    child: Image.asset(monster.image, fit: BoxFit.cover),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.55, 1],
                        colors: [Color(0x00120822), Spooky.night],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              32 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.list(
              children: [
                Text(
                  monster.name,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  monster.englishName,
                  style: const TextStyle(
                    fontFamily: Spooky.titleFont,
                    fontSize: 26,
                    color: Spooky.pumpkin,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Pill(icon: '🗺️', text: monster.origin),
                    _Pill(
                      icon: '😱',
                      child: ScareMeter(level: monster.scareLevel, size: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: const Border(
                      left: BorderSide(color: Spooky.pumpkin, width: 4),
                    ),
                    color: Spooky.pumpkin.withValues(alpha: 0.10),
                  ),
                  child: Text(
                    '「${monster.tagline}」',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Spooky.ember,
                    ),
                  ),
                ),
                _Section(
                  icon: '📜',
                  title: '傳說故事',
                  child: Text(
                    monster.story,
                    style: const TextStyle(fontSize: 16, height: 1.7),
                  ),
                ),
                _Section(
                  icon: '⚡',
                  title: '特殊能力',
                  child: _Chips(items: monster.powers, color: Spooky.violet),
                ),
                _Section(
                  icon: '🛡️',
                  title: '弱點',
                  child: _Chips(
                    items: monster.weaknesses,
                    color: const Color(0xFF3FBF8F),
                  ),
                ),
                _Section(
                  icon: '💡',
                  title: '你知道嗎？',
                  child: Text(
                    monster.funFact,
                    style: const TextStyle(fontSize: 16, height: 1.7),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('nextButton'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Spooky.surfaceHigh,
                    foregroundColor: Spooky.moon,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(monster: _next),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    '下一隻：${_next.name}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '圖片來源：${monster.credit.artist}・${monster.credit.license}\n'
                  'Wikimedia Commons — ${monster.credit.title}',
                  style: const TextStyle(
                    color: Spooky.mist,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, this.text, this.child});

  final String icon;
  final String? text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Spooky.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          child ??
              Text(
                text!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final String icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.items, required this.color});

  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(item, style: const TextStyle(fontSize: 15)),
          ),
      ],
    );
  }
}
