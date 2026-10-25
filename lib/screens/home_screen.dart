import 'dart:math';

import 'package:flutter/material.dart';

import '../data/monsters.dart';
import '../theme.dart';
import '../widgets/night_sky.dart';
import '../widgets/scare_meter.dart';
import 'credits_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final _random = Random();

  void _open(BuildContext context, Monster monster) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(monster: monster)));
  }

  @override
  Widget build(BuildContext context) {
    final featured = monsters.firstWhere((m) => m.id == 'headless_horseman');
    return Scaffold(
      body: CustomScrollView(
        key: const Key('monsterList'),
        slivers: [
          SliverToBoxAdapter(child: _Header(onInfo: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreditsScreen()));
          })),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _FeaturedCard(monster: featured, onTap: () => _open(context, featured)),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text('🎃', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text('妖怪圖鑑', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Spacer(),
                  Text('共 10 隻', style: TextStyle(color: Spooky.mist)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            sliver: SliverGrid.builder(
              itemCount: monsters.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.74,
              ),
              itemBuilder: (context, i) => _MonsterCard(
                monster: monsters[i],
                onTap: () => _open(context, monsters[i]),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('randomButton'),
        backgroundColor: Spooky.pumpkin,
        foregroundColor: Colors.white,
        onPressed: () => _open(context, monsters[_random.nextInt(monsters.length)]),
        icon: const Text('🔮', style: TextStyle(fontSize: 20)),
        label: const Text('隨機召喚', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onInfo});

  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return NightSky(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, top + 12, 8, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 28),
                  Text(
                    'Halloween\nMonsters',
                    style: TextStyle(
                      fontFamily: Spooky.titleFont,
                      fontSize: 46,
                      height: 1.0,
                      color: Spooky.pumpkin,
                      shadows: [Shadow(color: Color(0xAAFF7A1A), blurRadius: 18)],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('萬聖節妖怪圖鑑',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  SizedBox(height: 4),
                  Text('認識那些在萬聖夜出沒的傳說生物', style: TextStyle(color: Spooky.mist)),
                ],
              ),
            ),
            IconButton(
              key: const Key('creditsButton'),
              tooltip: '圖片來源',
              onPressed: onInfo,
              icon: const Icon(Icons.info_outline, color: Spooky.moon),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.monster, required this.onTap});

  final Monster monster;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('featuredCard'),
      onTap: onTap,
      child: Container(
        height: 190,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Spooky.pumpkin.withValues(alpha: 0.35), blurRadius: 24)],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(tag: 'featured-${monster.id}', child: Image.asset(monster.image, fit: BoxFit.cover)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0x00120822), Color(0xEE120822)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Spooky.pumpkin,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('今夜最恐怖',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
                  ),
                  const Spacer(),
                  Text(monster.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  Text(monster.tagline, style: const TextStyle(color: Spooky.moon, fontSize: 13)),
                  const SizedBox(height: 6),
                  ScareMeter(level: monster.scareLevel, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonsterCard extends StatelessWidget {
  const _MonsterCard({required this.monster, required this.onTap});

  final Monster monster;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Spooky.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('card-${monster.id}'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'img-${monster.id}',
                child: Image.asset(monster.image, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(monster.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(
                    monster.englishName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Spooky.ember, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  ScareMeter(level: monster.scareLevel, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
