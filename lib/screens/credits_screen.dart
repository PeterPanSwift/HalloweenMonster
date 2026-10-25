import 'package:flutter/material.dart';

import '../data/monsters.dart';
import '../theme.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('圖片與字型來源')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '本 App 的妖怪圖片皆取自 Wikimedia Commons，'
              '為公有領域（Public domain / CC0）或依創用 CC 授權條款使用。',
              style: TextStyle(color: Spooky.mist, height: 1.6),
            ),
          ),
          for (final m in monsters)
            Card(
              color: Spooky.surface,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    m.image,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: SelectableText(
                  '${m.credit.artist}・${m.credit.license}\n${m.credit.url}',
                  style: const TextStyle(fontSize: 12, color: Spooky.mist),
                ),
              ),
            ),
          const Card(
            color: Spooky.surface,
            child: ListTile(
              contentPadding: EdgeInsets.all(10),
              leading: Text('🔤', style: TextStyle(fontSize: 36)),
              title: Text(
                'Creepster 字型',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Sideshow・SIL Open Font License 1.1',
                style: TextStyle(fontSize: 12, color: Spooky.mist),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
