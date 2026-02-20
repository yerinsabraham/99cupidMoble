import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/game_session_model.dart';
import '../../../data/services/game_service.dart';

/// Live multiplayer game screen — both players see the same session in real time.
/// Player 1 answers → Player 2 sees the update and answers → next round.
class LiveGameScreen extends StatefulWidget {
  final String sessionId;

  const LiveGameScreen({super.key, required this.sessionId});

  @override
  State<LiveGameScreen> createState() => _LiveGameScreenState();
}

class _LiveGameScreenState extends State<LiveGameScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _hasAnsweredThisRound = false;
  int _lastRoundAnswered = 0;

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
          'Live Game',
          style: TextStyle(
            color: AppColors.deepPlum,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<GameSession?>(
        stream: GameService.streamGameSession(widget.sessionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.cupidPink));
          }

          final session = snapshot.data;
          if (session == null) {
            return const Center(
              child: Text('Game session not found', style: TextStyle(color: AppColors.deepPlum)),
            );
          }

          // Reset answer state when round changes
          if (session.currentRound != _lastRoundAnswered && _hasAnsweredThisRound) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _hasAnsweredThisRound = false;
              });
            });
          }

          if (session.status == 'completed') {
            return _buildCompletedView(session);
          }

          return _buildActiveGameView(session);
        },
      ),
    );
  }

  // ── ACTIVE GAME VIEW ──

  Widget _buildActiveGameView(GameSession session) {
    final isMyTurn = session.isMyTurn(_currentUserId);
    final otherName = session.getOtherPlayerName(_currentUserId);
    final myName = _currentUserId == session.player1Id
        ? session.player1Name
        : session.player2Name;

    // Check if I already answered this round
    final myAnswersThisRound = session.rounds
        .where((r) => r['round'] == session.currentRound && r['playerId'] == _currentUserId)
        .toList();
    final alreadyAnswered = myAnswersThisRound.isNotEmpty || _hasAnsweredThisRound;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Player Avatars ──
          _buildPlayersHeader(session, isMyTurn),
          const SizedBox(height: 16),

          // ── Round Progress ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Round ${session.currentRound} of ${session.totalRounds}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepPlum.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: session.currentRound / session.totalRounds,
                    backgroundColor: AppColors.warmBlush,
                    valueColor: const AlwaysStoppedAnimation(AppColors.cupidPink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Game Type Badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cupidPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              GameService.gameTypeLabel(session.gameType),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.cupidPink,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Question Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
              children: [
                Text(
                  _emojiForGameType(session.gameType),
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  session.currentQuestion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepPlum,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Turn Status / Answer Section ──
          if (alreadyAnswered) ...[
            _buildWaitingForOther(otherName),
          ] else if (isMyTurn) ...[
            _buildAnswerSection(session, myName),
          ] else ...[
            _buildWaitingForTurn(otherName),
          ],

          // ── Previous Rounds ──
          if (session.rounds.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildPreviousRounds(session),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayersHeader(GameSession session, bool isMyTurn) {
    final iAmPlayer1 = _currentUserId == session.player1Id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildPlayerBubble(
            name: iAmPlayer1 ? session.player1Name : session.player2Name,
            photo: iAmPlayer1 ? session.player1Photo : session.player2Photo,
            isActive: isMyTurn,
            label: 'You',
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warmBlush,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.cupidPink,
              ),
            ),
          ),
          const Spacer(),
          _buildPlayerBubble(
            name: iAmPlayer1 ? session.player2Name : session.player1Name,
            photo: iAmPlayer1 ? session.player2Photo : session.player1Photo,
            isActive: !isMyTurn,
            label: iAmPlayer1 ? session.player2Name : session.player1Name,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBubble({
    required String name,
    String? photo,
    required bool isActive,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.cupidPink : Colors.grey.shade300,
              width: isActive ? 3 : 1,
            ),
            image: photo != null
                ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover)
                : null,
            color: photo == null ? AppColors.warmBlush : null,
          ),
          child: photo == null
              ? Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cupidPink,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label.length > 10 ? '${label.substring(0, 10)}...' : label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.cupidPink : AppColors.deepPlum.withOpacity(0.6),
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.cupidPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Playing',
              style: TextStyle(fontSize: 10, color: AppColors.cupidPink, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerSection(GameSession session, String myName) {
    if (session.gameType == 'this_or_that') {
      return _buildThisOrThatAnswer(session, myName);
    }
    return _buildTextAnswer(session, myName);
  }

  Widget _buildThisOrThatAnswer(GameSession session, String myName) {
    final parts = session.currentQuestion.split(' vs ');
    final optionA = parts.isNotEmpty ? parts[0].trim() : 'Option A';
    final optionB = parts.length > 1 ? parts[1].trim() : 'Option B';

    return Column(
      children: [
        Text(
          "It's your turn! Pick one:",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.deepPlum.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildChoiceButton(optionA, const Color(0xFFFF6B6B), () {
                _submitAnswer(session, myName, optionA);
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChoiceButton(optionB, const Color(0xFF4ECDC4), () {
                _submitAnswer(session, myName, optionB);
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextAnswer(GameSession session, String myName) {
    final controller = TextEditingController();

    return Column(
      children: [
        Text(
          "It's your turn! Type your answer:",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.deepPlum.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepPlum.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.black, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Your answer...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cupidPink, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                _submitAnswer(session, myName, text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cupidPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Submit Answer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingForOther(String otherName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.warmBlush,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.cupidPink,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "You've answered!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.deepPlum.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Waiting for $otherName to answer...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.deepPlum.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForTurn(String otherName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('⏳', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            "$otherName's turn",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.deepPlum,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Waiting for them to answer first...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.deepPlum.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── PREVIOUS ROUNDS ──

  Widget _buildPreviousRounds(GameSession session) {
    // Group answers by round
    final Map<int, List<Map<String, dynamic>>> roundMap = {};
    for (final r in session.rounds) {
      final round = r['round'] as int;
      roundMap.putIfAbsent(round, () => []);
      roundMap[round]!.add(r);
    }

    final completedRounds = roundMap.entries
        .where((e) => e.value.length >= 2)
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (completedRounds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previous Rounds',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.deepPlum.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        ...completedRounds.map((entry) {
          final round = entry.key;
          final answers = entry.value;
          final question = answers.first['question'] as String;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warmBlush),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round $round',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepPlum.withOpacity(0.4),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 10),
                ...answers.map((a) {
                  final isMe = a['playerId'] == _currentUserId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.cupidPink.withOpacity(0.1)
                                : const Color(0xFF6C5CE7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isMe ? 'You' : (a['playerName'] as String),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isMe ? AppColors.cupidPink : const Color(0xFF6C5CE7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            a['answer'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.deepPlum.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── COMPLETED VIEW ──

  Widget _buildCompletedView(GameSession session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'Game Complete!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.deepPlum,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Great game with ${session.getOtherPlayerName(_currentUserId)}!',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.deepPlum.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          _buildPreviousRounds(session),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cupidPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Back to Games',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──

  void _submitAnswer(GameSession session, String myName, String answer) {
    setState(() {
      _hasAnsweredThisRound = true;
      _lastRoundAnswered = session.currentRound;
    });

    GameService.submitAnswer(
      sessionId: widget.sessionId,
      playerId: _currentUserId,
      playerName: myName,
      answer: answer,
    );
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
