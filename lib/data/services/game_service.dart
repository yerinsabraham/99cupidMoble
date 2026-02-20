import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_collections.dart';
import '../../data/models/game_session_model.dart';

/// Service to manage real-time multiplayer game sessions via Firestore
class GameService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final _random = Random();

  // ──────────────────────────────────────────────
  // GAME QUESTIONS POOL
  // ──────────────────────────────────────────────

  static const List<String> wouldYouRather = [
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

  static const List<String> truthQuestions = [
    "What's the most embarrassing thing that's ever happened to you on a date?",
    "What's one thing you've never told anyone?",
    "What's your biggest dating deal-breaker?",
    "Have you ever stalked someone's social media before a date?",
    "What's the cheesiest pick-up line you've ever used or heard?",
    "What's something about yourself that surprises people?",
    "What's your guilty pleasure?",
    "Have you ever pretended to like something to impress a date?",
    "What's the strangest compliment you've ever received?",
    "What's a weird habit you have?",
    "What's the most romantic thing you've ever done?",
    "If you could change one thing about yourself, what would it be?",
    "What's the most adventurous thing you've ever done?",
    "What's a secret skill you have?",
    "What's your biggest green flag in a partner?",
  ];

  static const List<Map<String, String>> thisOrThat = [
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
    {'a': 'Early Date 🕕', 'b': 'Late Date 🕘'},
    {'a': 'City Lights 🌃', 'b': 'Starry Sky ✨'},
  ];

  static const List<String> twentyQuestions = [
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
    "What's the most important lesson from past relationships?",
    "How do you show someone you care?",
    "What does commitment mean to you?",
    "What are your top 3 values in life?",
    "What's your biggest relationship fear?",
    "Where do you see yourself in 5 years?",
  ];

  /// Get a random question for the given game type
  static String getRandomQuestion(String gameType, {List<String>? usedQuestions}) {
    List<String> pool;
    switch (gameType) {
      case 'would_you_rather':
        pool = wouldYouRather;
        break;
      case 'truth_or_dare':
        pool = truthQuestions;
        break;
      case 'this_or_that':
        final pair = thisOrThat[_random.nextInt(thisOrThat.length)];
        return "${pair['a']} vs ${pair['b']}";
      case '20_questions':
        pool = twentyQuestions;
        break;
      default:
        pool = wouldYouRather;
    }

    // Filter out already-used questions
    if (usedQuestions != null && usedQuestions.isNotEmpty) {
      final available = pool.where((q) => !usedQuestions.contains(q)).toList();
      if (available.isNotEmpty) {
        return available[_random.nextInt(available.length)];
      }
    }
    return pool[_random.nextInt(pool.length)];
  }

  /// Create a new game session and notify the other player via chat
  static Future<String> createGameSession({
    required String gameType,
    required String player1Id,
    required String player2Id,
    required String player1Name,
    required String player2Name,
    String? player1Photo,
    String? player2Photo,
    String? chatId,
  }) async {
    final question = getRandomQuestion(gameType);

    final session = GameSession(
      gameType: gameType,
      player1Id: player1Id,
      player2Id: player2Id,
      player1Name: player1Name,
      player2Name: player2Name,
      player1Photo: player1Photo,
      player2Photo: player2Photo,
      status: 'active',
      currentTurn: player1Id, // Creator goes first
      currentQuestion: question,
      currentRound: 1,
      totalRounds: 5,
      chatId: chatId,
    );

    final docRef = await _firestore
        .collection(FirebaseCollections.gameSessions)
        .add(session.toFirestore());

    // Send a game invite message in their chat
    if (chatId != null) {
      await _firestore
          .collection(FirebaseCollections.chats)
          .doc(chatId)
          .collection(FirebaseCollections.messages)
          .add({
        'senderId': player1Id,
        'text': '🎮 $player1Name invited you to play ${_gameTypeLabel(gameType)}! Tap to join.',
        'type': 'game_invite',
        'gameSessionId': docRef.id,
        'gameType': gameType,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update last message in chat
      await _firestore.collection(FirebaseCollections.chats).doc(chatId).update({
        'lastMessage': '🎮 Game invite: ${_gameTypeLabel(gameType)}',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }

    return docRef.id;
  }

  /// Submit an answer for the current round
  static Future<void> submitAnswer({
    required String sessionId,
    required String playerId,
    required String playerName,
    required String answer,
  }) async {
    final docRef = _firestore
        .collection(FirebaseCollections.gameSessions)
        .doc(sessionId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final session = GameSession.fromFirestore(doc);
    final rounds = List<Map<String, dynamic>>.from(session.rounds);

    // Add this player's answer for the current round
    rounds.add({
      'playerId': playerId,
      'playerName': playerName,
      'question': session.currentQuestion,
      'answer': answer,
      'round': session.currentRound,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Check if both players have answered this round
    final answersThisRound = rounds.where((r) => r['round'] == session.currentRound).length;

    if (answersThisRound >= 2) {
      // Both answered — advance to next round
      if (session.currentRound >= session.totalRounds) {
        // Game complete
        await docRef.update({
          'rounds': rounds,
          'status': 'completed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Next round with new question
        final usedQuestions = rounds.map((r) => r['question'] as String).toList();
        final nextQuestion = getRandomQuestion(session.gameType, usedQuestions: usedQuestions);

        await docRef.update({
          'rounds': rounds,
          'currentRound': session.currentRound + 1,
          'currentQuestion': nextQuestion,
          'currentTurn': session.player1Id, // Player 1 always goes first each round
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      // Pass turn to the other player
      final otherPlayer = session.getOtherPlayerId(playerId);
      await docRef.update({
        'rounds': rounds,
        'currentTurn': otherPlayer,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Stream a game session for real-time updates
  static Stream<GameSession?> streamGameSession(String sessionId) {
    return _firestore
        .collection(FirebaseCollections.gameSessions)
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? GameSession.fromFirestore(doc) : null);
  }

  /// Get active game sessions for a user
  static Stream<List<GameSession>> streamActiveGames(String userId) {
    return _firestore
        .collection(FirebaseCollections.gameSessions)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => GameSession.fromFirestore(doc))
            .where((s) => s.player1Id == userId || s.player2Id == userId)
            .toList());
  }

  /// Get the human-readable label for a game type
  static String _gameTypeLabel(String gameType) {
    switch (gameType) {
      case 'would_you_rather':
        return 'Would You Rather';
      case 'truth_or_dare':
        return 'Truth or Dare';
      case 'this_or_that':
        return 'This or That';
      case '20_questions':
        return '20 Questions';
      default:
        return 'a game';
    }
  }

  /// Public version
  static String gameTypeLabel(String gameType) => _gameTypeLabel(gameType);
}
