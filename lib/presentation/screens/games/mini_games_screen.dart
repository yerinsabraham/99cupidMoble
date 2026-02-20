import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/firebase_collections.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/game_session_model.dart';
import '../../../data/services/game_service.dart';
import 'live_game_screen.dart';

/// Mini-Games Screen — fun couple games to break the ice
/// Accessible from chat or Discover tab.  Secondary feature — don't lead with it.
class MiniGamesScreen extends StatefulWidget {
  /// Optional: send the result back to chat
  final void Function(String message)? onSendToChat;

  const MiniGamesScreen({super.key, this.onSendToChat});

  @override
  State<MiniGamesScreen> createState() => _MiniGamesScreenState();
}

class _MiniGamesScreenState extends State<MiniGamesScreen> {
  final _random = Random();

  // ──────────────────────────────────────────────
  // GAME DATA
  // ──────────────────────────────────────────────

  static const List<String> _wouldYouRather = [
    "Would you rather travel to the future or the past?",
    "Would you rather always be 10 minutes late or 20 minutes early?",
    "Would you rather have the ability to fly or be invisible?",
    "Would you rather live in a big city or on a tropical island?",
    "Would you rather give up social media or movies for a year?",
    "Would you rather always speak your mind or never speak again?",
    "Would you rather explore space or the deep ocean?",
    "Would you rather have unlimited money or unlimited time?",
    "Would you rather be a famous musician or a famous actor?",
    "Would you rather cook every meal or eat out every meal?",
    "Would you rather meet your future self or your past self?",
    "Would you rather have a rewind or a pause button for life?",
    "Would you rather live without music or without TV?",
    "Would you rather be fluent in all languages or play every instrument?",
    "Would you rather have a personal chef or a personal driver?",
  ];

  static const List<String> _truthQuestions = [
    "What's the most embarrassing thing that's ever happened to you on a date?",
    "What's one thing you've never told anyone?",
    "What's your biggest dating deal-breaker?",
    "Have you ever stalked someone's social media before a date?",
    "What's the cheesiest pick-up line you've ever used or heard?",
    "What's your guilty pleasure that you'd be embarrassed about?",
    "What's the longest you've gone without showering?",
    "Have you ever pretended to like something to impress someone?",
    "What's the strangest compliment you've ever received?",
    "What's a weird habit you have that no one knows about?",
    "If you could change one thing about yourself, what would it be?",
    "What's the most adventurous thing you've ever done?",
    "Have you ever had a crush on a friend's partner?",
    "What's the most romantic thing you've ever done?",
    "What's a secret skill you have that surprises people?",
  ];

  static const List<String> _dares = [
    "Send a selfie with the silliest face you can make!",
    "Type the next 3 messages using only emojis.",
    "Share the last photo in your camera roll.",
    "Send a voice note singing your favorite song.",
    "Tell me your best joke — make me laugh!",
    "Describe me in 3 emojis.",
    "Send a screenshot of your home screen.",
    "Compliment me in the most creative way possible.",
    "Share a childhood photo of yourself.",
    "Make up a short poem about our conversation.",
    "Record yourself doing your best accent impression.",
    "Send the 5th photo in your gallery (no cheating!).",
    "Use a pickup line on me and make it convincing!",
  ];

  static const List<Map<String, dynamic>> _thisOrThat = [
    {'a': 'Coffee ☕', 'b': 'Tea 🍵'},
    {'a': 'Morning Person 🌅', 'b': 'Night Owl 🌙'},
    {'a': 'Dogs 🐕', 'b': 'Cats 🐈'},
    {'a': 'Mountains ⛰️', 'b': 'Beach 🏖️'},
    {'a': 'Book 📚', 'b': 'Movie 🎬'},
    {'a': 'Call 📞', 'b': 'Text 💬'},
    {'a': 'Sweet 🍰', 'b': 'Savory 🍕'},
    {'a': 'Indoor Date 🏠', 'b': 'Outdoor Date 🌳'},
    {'a': 'Cook Together 🍳', 'b': 'Order In 🥡'},
    {'a': 'Road Trip 🚗', 'b': 'Fly Somewhere ✈️'},
    {'a': 'Spontaneous 🎲', 'b': 'Planned 📋'},
    {'a': 'Comedy 😂', 'b': 'Romance 💕'},
    {'a': 'Early Dinner 🕕', 'b': 'Late Dinner 🕘'},
    {'a': 'City Lights 🌃', 'b': 'Starry Sky ✨'},
  ];

  static const List<String> _twentyQuestions = [
    "What is your love language?",
    "What does your perfect date look like?",
    "Are you a planner or spontaneous?",
    "What's the most important quality in a partner?",
    "Do you believe in love at first sight?",
    "What's your biggest green flag?",
    "How do you handle disagreements?",
    "What's your idea of a perfect Sunday?",
    "What are you most looking for in a relationship?",
    "Do you want kids someday?",
    "What's a non-negotiable for you in a relationship?",
    "How important is family to you?",
    "What makes you feel most loved?",
    "Are you an introvert or extrovert?",
    "What's the most important lesson you've learned from past relationships?",
    "How do you show someone you care?",
    "What does commitment mean to you?",
    "What are your top 3 values in life?",
    "What's your biggest relationship fear?",
    "Where do you see yourself in 5 years?",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softIvory,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.deepPlum),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Fun Games',
          style: TextStyle(
            color: AppColors.deepPlum,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Break the ice with fun games!',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.deepPlum.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),

            // ── PLAY WITH SOMEONE BUTTON ──
            _buildPlayWithSomeoneButton(context),
            const SizedBox(height: 12),

            // ── ACTIVE GAMES ──
            _buildActiveGamesSection(),
            const SizedBox(height: 8),

            // ── SOLO PRACTICE SECTION LABEL ──
            Text(
              'SOLO PRACTICE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.deepPlum.withOpacity(0.45),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),

            _buildGameCard(
              emoji: '🤔',
              title: 'Would You Rather',
              subtitle: 'Pick between two tough choices',
              color: const Color(0xFFFF6B6B),
              onTap: () => _playWouldYouRather(context),
            ),
            _buildGameCard(
              emoji: '🎯',
              title: 'Truth or Dare',
              subtitle: 'Classic ice-breaker game',
              color: const Color(0xFF4ECDC4),
              onTap: () => _playTruthOrDare(context),
            ),
            _buildGameCard(
              emoji: '⚡',
              title: 'This or That',
              subtitle: 'Quick-fire preferences',
              color: const Color(0xFFFFBE0B),
              onTap: () => _playThisOrThat(context),
            ),
            _buildGameCard(
              emoji: '💕',
              title: '20 Questions',
              subtitle: 'Get to know each other deeply',
              color: AppColors.cupidPink,
              onTap: () => _playTwentyQuestions(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepPlum,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.deepPlum.withOpacity(0.6),
                      )),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // GAME MODALS
  // ──────────────────────────────────────────────

  void _playWouldYouRather(BuildContext ctx) {
    _showGameSheet(
      ctx,
      title: 'Would You Rather',
      emoji: '🤔',
      color: const Color(0xFFFF6B6B),
      getQuestion: () => _wouldYouRather[_random.nextInt(_wouldYouRather.length)],
    );
  }

  void _playTruthOrDare(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TruthOrDareSheet(
        truths: _truthQuestions,
        dares: _dares,
        onSendToChat: widget.onSendToChat,
      ),
    );
  }

  void _playThisOrThat(BuildContext ctx) {
    final pair = _thisOrThat[_random.nextInt(_thisOrThat.length)];
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚡', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            const Text('This or That',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepPlum,
                )),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _thisOrThatButton(
                      pair['a']! as String, const Color(0xFFFF6B6B), () {
                    Navigator.pop(ctx);
                    if (widget.onSendToChat != null) {
                      widget.onSendToChat!(
                          "This or That: ${pair['a']} vs ${pair['b']} — I pick ${pair['a']}! What about you?");
                    }
                  }),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('VS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepPlum,
                      )),
                ),
                Expanded(
                  child: _thisOrThatButton(
                      pair['b']! as String, const Color(0xFF4ECDC4), () {
                    Navigator.pop(ctx);
                    if (widget.onSendToChat != null) {
                      widget.onSendToChat!(
                          "This or That: ${pair['a']} vs ${pair['b']} — I pick ${pair['b']}! What about you?");
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _playThisOrThat(context);
              },
              child: const Text('Another one!',
                  style: TextStyle(color: AppColors.cupidPink)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _thisOrThatButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  void _playTwentyQuestions(BuildContext ctx) {
    _showGameSheet(
      ctx,
      title: '20 Questions',
      emoji: '💕',
      color: AppColors.cupidPink,
      getQuestion: () => _twentyQuestions[_random.nextInt(_twentyQuestions.length)],
    );
  }

  void _showGameSheet(
    BuildContext ctx, {
    required String title,
    required String emoji,
    required Color color,
    required String Function() getQuestion,
  }) {
    String question = getQuestion();

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPlum,
                  )),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepPlum,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setSheetState(() => question = getQuestion());
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Shuffle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cupidPink,
                        side: const BorderSide(color: AppColors.cupidPink),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (widget.onSendToChat != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onSendToChat!(question);
                        },
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Send'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cupidPink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // MULTIPLAYER — PLAY WITH SOMEONE
  // ──────────────────────────────────────────────

  Widget _buildPlayWithSomeoneButton(BuildContext ctx) {
    return GestureDetector(
      onTap: () => _showInvitePlayerSheet(ctx),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B1A4A), Color(0xFFFF5FA8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.cupidPink.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('👥', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Play with Someone',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Invite a match to play together in real time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGamesSection() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<List<GameSession>>(
      stream: GameService.streamActiveGames(currentUserId),
      builder: (context, snapshot) {
        final games = snapshot.data ?? [];
        if (games.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACTIVE GAMES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.deepPlum.withOpacity(0.45),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            ...games.map((game) {
              final otherName = game.getOtherPlayerName(currentUserId);
              final isMyTurn = game.isMyTurn(currentUserId);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveGameScreen(sessionId: game.id!),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMyTurn ? AppColors.cupidPink : AppColors.warmBlush,
                      width: isMyTurn ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.cupidPink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _emojiForGameType(game.gameType),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${GameService.gameTypeLabel(game.gameType)} with $otherName',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepPlum,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Round ${game.currentRound}/${game.totalRounds} • ${isMyTurn ? 'Your turn!' : "$otherName\'s turn"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isMyTurn
                                    ? AppColors.cupidPink
                                    : AppColors.deepPlum.withOpacity(0.5),
                                fontWeight: isMyTurn ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMyTurn)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cupidPink,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'PLAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      else
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _showInvitePlayerSheet(BuildContext ctx) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvitePlayerSheet(
        currentUserId: currentUserId,
        onInvite: (chatUser, gameType) async {
          Navigator.pop(ctx);
          await _startMultiplayerGame(chatUser, gameType);
        },
      ),
    );
  }

  Future<void> _startMultiplayerGame(
    Map<String, dynamic> chatUser,
    String gameType,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final sessionId = await GameService.createGameSession(
        gameType: gameType,
        player1Id: currentUser.uid,
        player2Id: chatUser['userId'] as String,
        player1Name: currentUser.displayName ?? 'You',
        player2Name: chatUser['userName'] as String,
        player1Photo: currentUser.photoURL,
        player2Photo: chatUser['userPhoto'] as String?,
        chatId: chatUser['chatId'] as String?,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveGameScreen(sessionId: sessionId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create game: $e')),
      );
    }
  }

  String _emojiForGameType(String gameType) {
    switch (gameType) {
      case 'would_you_rather':
        return '🤔';
      case 'truth_or_dare':
        return '🎯';
      case 'this_or_that':
        return '⚡';
      case '20_questions':
        return '💕';
      default:
        return '🎮';
    }
  }
}

// ──────────────────────────────────────────────
// INVITE PLAYER BOTTOM SHEET
// ──────────────────────────────────────────────

class _InvitePlayerSheet extends StatefulWidget {
  final String currentUserId;
  final void Function(Map<String, dynamic> chatUser, String gameType) onInvite;

  const _InvitePlayerSheet({
    required this.currentUserId,
    required this.onInvite,
  });

  @override
  State<_InvitePlayerSheet> createState() => _InvitePlayerSheetState();
}

class _InvitePlayerSheetState extends State<_InvitePlayerSheet> {
  String _selectedGameType = 'would_you_rather';

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text('👥', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Play with Someone',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepPlum,
                        ),
                      ),
                      Text(
                        'Choose a game and a person to play with',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Game type selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildGameTypeChip('would_you_rather', '🤔 Would You Rather'),
                  _buildGameTypeChip('truth_or_dare', '🎯 Truth or Dare'),
                  _buildGameTypeChip('this_or_that', '⚡ This or That'),
                  _buildGameTypeChip('20_questions', '💕 20 Questions'),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Chat users list
          Flexible(
            child: _buildChatUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTypeChip(String value, String label) {
    final isSelected = _selectedGameType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.cupidPink,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.cupidPink : AppColors.deepPlum.withOpacity(0.2),
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.deepPlum,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _selectedGameType = value),
      ),
    );
  }

  Widget _buildChatUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseCollections.chats)
          .where('participants', arrayContains: widget.currentUserId)
          .orderBy('lastMessageAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.cupidPink),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💬', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'No chats yet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start swiping and match with someone to play together!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.deepPlum.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final chat = ChatModel.fromFirestore(docs[index]);
            final otherName = chat.getOtherUserName(widget.currentUserId);
            final otherPhoto = chat.getOtherUserPhoto(widget.currentUserId);
            final otherId = chat.getOtherUserId(widget.currentUserId);

            return GestureDetector(
              onTap: () => widget.onInvite({
                'userId': otherId,
                'userName': otherName,
                'userPhoto': otherPhoto,
                'chatId': chat.id,
              }, _selectedGameType),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softIvory,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warmBlush),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: otherPhoto != null && otherPhoto.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(otherPhoto),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: otherPhoto == null || otherPhoto.isEmpty
                            ? AppColors.warmBlush
                            : null,
                      ),
                      child: otherPhoto == null || otherPhoto.isEmpty
                          ? Center(
                              child: Text(
                                otherName.isNotEmpty
                                    ? otherName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.cupidPink,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.deepPlum,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Tap to invite',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.deepPlum.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cupidPink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Invite',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
class _TruthOrDareSheet extends StatefulWidget {
  final List<String> truths;
  final List<String> dares;
  final void Function(String message)? onSendToChat;

  const _TruthOrDareSheet({
    required this.truths,
    required this.dares,
    this.onSendToChat,
  });

  @override
  State<_TruthOrDareSheet> createState() => _TruthOrDareSheetState();
}

class _TruthOrDareSheetState extends State<_TruthOrDareSheet> {
  final _random = Random();
  String? _currentQuestion;
  bool _isTruth = true;

  void _pickTruth() {
    setState(() {
      _isTruth = true;
      _currentQuestion = widget.truths[_random.nextInt(widget.truths.length)];
    });
  }

  void _pickDare() {
    setState(() {
      _isTruth = false;
      _currentQuestion = widget.dares[_random.nextInt(widget.dares.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          const Text('Truth or Dare',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.deepPlum,
              )),
          const SizedBox(height: 24),

          // Truth / Dare buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _pickTruth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Truth',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _pickDare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Dare',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),

          if (_currentQuestion != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (_isTruth
                        ? const Color(0xFF4ECDC4)
                        : const Color(0xFFFF6B6B))
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isTruth
                          ? const Color(0xFF4ECDC4)
                          : const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isTruth ? 'TRUTH' : 'DARE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentQuestion!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepPlum,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onSendToChat != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    final prefix = _isTruth ? 'Truth' : 'Dare';
                    widget.onSendToChat!(
                        '$prefix: $_currentQuestion');
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send to Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cupidPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
