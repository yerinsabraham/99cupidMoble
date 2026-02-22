import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../games/cultural_games_screen.dart';
import '../games/mini_games_screen.dart';
import '../../widgets/chat/conversation_starters_sheet.dart';

/// Explore Screen — Always-visible tab showcasing 99Cupid's differentiating features.
/// Apple reviewers and new users can access Cultural Games, AI Conversation Starters,
/// Fun Games, and Inclusive Dating features WITHOUT needing a match.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softIvory,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Explore',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepPlum,
                          ),
                        ),
                        const Spacer(),
                        Image.asset(
                          'assets/icons/applogo.png',
                          width: 36,
                          height: 36,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What makes 99Cupid different',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.deepPlum.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── LEAD CARD: Cultural Exchange ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _LeadFeatureCard(
                  icon: Icons.public,
                  badge: 'FEATURED',
                  badgeColor: AppColors.cupidPink,
                  title: 'Cultural Exchange',
                  subtitle:
                      'Explore world cultures through trivia, customs & love traditions. '
                      '15 trivia questions across 6 regions — learn something new!',
                  buttonLabel: 'Play Now',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B1A4A), Color(0xFFFF5FA8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CulturalGamesScreen(),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Section label ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'START A CONVERSATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepPlum.withOpacity(0.45),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // ── AI Conversation Starters ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FeatureCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Conversation Starters',
                  subtitle:
                      'Cultural, Deep, Fun, and Travel prompts — break the ice perfectly',
                  color: const Color(0xFF6C5CE7),
                  onTap: () => _showConversationStarters(context),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Mini Games ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FeatureCard(
                  icon: Icons.sports_esports,
                  title: 'Fun Games',
                  subtitle:
                      'Truth or Dare, Would You Rather, This or That, 20 Questions',
                  color: const Color(0xFF00B894),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MiniGamesScreen(),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Inclusive Dating ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'OUR COMMITMENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepPlum.withOpacity(0.45),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepPlum.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.cupidPink.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.accessibility_new,
                              color: AppColors.cupidPink,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Inclusive Dating',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepPlum,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '99Cupid is built for everyone. We celebrate all abilities, backgrounds, '
                        'and identities. Set your accessibility preferences, show an optional '
                        'inclusive badge, and match with people who share your values.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.deepPlum.withOpacity(0.7),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _PillTag(label: 'Physical'),
                          _PillTag(label: 'Visual'),
                          _PillTag(label: 'Hearing'),
                          _PillTag(label: 'Cognitive'),
                          _PillTag(label: 'Mental Health'),
                          _PillTag(label: 'Chronic Illness'),
                          _PillTag(label: 'Neurodivergent'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.push('/edit-profile?section=inclusive_dating'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.cupidPink),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Set My Accessibility Preferences',
                            style: TextStyle(
                              color: AppColors.cupidPink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Why We're Different ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'WHY 99CUPID IS DIFFERENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepPlum.withOpacity(0.45),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            SliverList(
              delegate: SliverChildListDelegate([
                _DifferentiatorTile(
                  icon: Icons.public,
                  iconBg: const Color(0xFF0984E3),
                  title: 'Cross-Cultural Connection',
                  body:
                      'Our Cultural Exchange games teach you about your match\'s background — '
                      'turning first conversations into cultural adventures.',
                ),
                _DifferentiatorTile(
                  icon: Icons.accessibility_new,
                  iconBg: AppColors.cupidPink,
                  title: 'Disability-Inclusive Matching',
                  body:
                      'Set visibility preferences for disability info, show an inclusive badge, '
                      'and filter by dating preference — features no mainstream dating app offers.',
                ),
                _DifferentiatorTile(
                  icon: Icons.auto_awesome,
                  iconBg: const Color(0xFF6C5CE7),
                  title: 'Meaningful First Messages',
                  body:
                      'AI-curated conversation starters based on cultural context replace '
                      'the dreaded "hey" with something actually interesting.',
                ),
                _DifferentiatorTile(
                  icon: Icons.sports_esports,
                  iconBg: const Color(0xFF00B894),
                  title: 'Games That Build Connection',
                  body:
                      'Fun ice-breaker games integrated directly into chat — because the '
                      'best connections start with laughter and curiosity.',
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showConversationStarters(BuildContext context) {
    showConversationStarters(
      context,
      onSend: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: "$msg"'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// HELPER WIDGETS
// ──────────────────────────────────────────────────────────

class _LeadFeatureCard extends StatelessWidget {
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Gradient gradient;
  final VoidCallback onTap;

  const _LeadFeatureCard({
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.cupidPink.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  icon,
                  color: Colors.white,
                  size: 40,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    buttonLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 16, color: badgeColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepPlum.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPlum,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.deepPlum.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

class _DifferentiatorTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String body;

  const _DifferentiatorTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepPlum.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconBg, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepPlum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.deepPlum.withOpacity(0.65),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String label;
  const _PillTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cupidPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cupidPink.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.cupidPink,
        ),
      ),
    );
  }
}
