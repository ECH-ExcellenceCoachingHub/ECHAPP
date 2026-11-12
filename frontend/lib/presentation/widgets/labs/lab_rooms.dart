import 'package:flutter/material.dart';

/// The six 3D lab rooms (Unity scenes). `environment` matches LabScenario.environment.
class LabRoom {
  final String environment;
  final String title;
  final String tagline;
  final IconData icon;
  final List<Color> gradient;
  final String image;
  const LabRoom(this.environment, this.title, this.tagline, this.icon, this.gradient, this.image);

  static const all = <LabRoom>[
    LabRoom('ChemLab', 'Chemistry Wet Lab', 'Safety, glassware, indicators and titrations', Icons.science_rounded, [Color(0xFF10B981), Color(0xFF047857)], 'assets/labs/ChemLab.jpg'),
    LabRoom('PhysicsLab', 'Physics Lab', 'Circuits, meters and pendulums', Icons.bolt_rounded, [Color(0xFF3B82F6), Color(0xFF1D4ED8)], 'assets/labs/PhysicsLab.jpg'),
    LabRoom('BioLab', 'Biology Lab', 'Microscopes, slides and real cells', Icons.biotech_rounded, [Color(0xFF84CC16), Color(0xFF3F6212)], 'assets/labs/BioLab.jpg'),
    LabRoom('CyberSOC', 'Cyber Operations Center', 'Passwords, phishing, firewalls and incidents', Icons.shield_rounded, [Color(0xFFF43F5E), Color(0xFF9F1239)], 'assets/labs/CyberSOC.jpg'),
    LabRoom('ServerRoom', 'Network & Server Room', 'Cabling, IP addressing and subnetting', Icons.lan_rounded, [Color(0xFF8B5CF6), Color(0xFF5B21B6)], 'assets/labs/ServerRoom.jpg'),
    LabRoom('CodingBench', 'Coding & AI Studio', 'Python, debugging, algorithms and AI', Icons.code_rounded, [Color(0xFFF59E0B), Color(0xFFB45309)], 'assets/labs/CodingBench.jpg'),
  ];

  static LabRoom of(String environment) => all.firstWhere((r) => r.environment == environment, orElse: () => all.first);
}

/// Difficulty ladder used across the labs UI.
class LabDifficulty {
  final int level;
  final String label;
  final String blurb;
  final Color color;
  const LabDifficulty(this.level, this.label, this.blurb, this.color);

  static const levels = <LabDifficulty>[
    LabDifficulty(1, 'Beginner', 'Guided step by step, plenty of hints', Color(0xFF10B981)),
    LabDifficulty(2, 'Easy', 'Short activities with helpful hints', Color(0xFF22C55E)),
    LabDifficulty(3, 'Intermediate', 'Full experiments and calculations', Color(0xFF3B82F6)),
    LabDifficulty(4, 'Advanced', 'Fewer hints, more reasoning', Color(0xFFF59E0B)),
    LabDifficulty(5, 'Expert', 'Exam conditions — little or no help', Color(0xFFEF4444)),
  ];

  static LabDifficulty of(int level) => levels[(level.clamp(1, 5)) - 1];
}

/// Small coloured difficulty pill with "signal bars".
class DifficultyChip extends StatelessWidget {
  final int level;
  final bool compact;
  const DifficultyChip(this.level, {super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final d = LabDifficulty.of(level);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(color: d.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20), border: Border.all(color: d.color.withValues(alpha: 0.5))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (int i = 1; i <= 5; i++)
          Container(
            width: 3,
            height: 4.0 + i * 2,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(color: i <= level ? d.color : d.color.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(1)),
          ),
        const SizedBox(width: 5),
        Text(d.label, style: TextStyle(color: d.color, fontSize: compact ? 11 : 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
