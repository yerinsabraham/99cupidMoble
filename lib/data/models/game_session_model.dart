import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a real-time multiplayer game session between two users
class GameSession {
  final String? id;
  final String gameType; // 'would_you_rather', 'truth_or_dare', 'this_or_that', '20_questions'
  final String player1Id;
  final String player2Id;
  final String player1Name;
  final String player2Name;
  final String? player1Photo;
  final String? player2Photo;
  final String status; // 'pending', 'active', 'completed'
  final String currentTurn; // player1Id or player2Id
  final String currentQuestion;
  final List<Map<String, dynamic>> rounds; // [{playerId, answer, question, timestamp}]
  final int currentRound;
  final int totalRounds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? chatId; // reference to the chat between the two users

  GameSession({
    this.id,
    required this.gameType,
    required this.player1Id,
    required this.player2Id,
    required this.player1Name,
    required this.player2Name,
    this.player1Photo,
    this.player2Photo,
    this.status = 'pending',
    required this.currentTurn,
    required this.currentQuestion,
    this.rounds = const [],
    this.currentRound = 1,
    this.totalRounds = 5,
    DateTime? createdAt,
    this.updatedAt,
    this.chatId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory GameSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameSession(
      id: doc.id,
      gameType: data['gameType'] ?? '',
      player1Id: data['player1Id'] ?? '',
      player2Id: data['player2Id'] ?? '',
      player1Name: data['player1Name'] ?? 'Player 1',
      player2Name: data['player2Name'] ?? 'Player 2',
      player1Photo: data['player1Photo'],
      player2Photo: data['player2Photo'],
      status: data['status'] ?? 'pending',
      currentTurn: data['currentTurn'] ?? '',
      currentQuestion: data['currentQuestion'] ?? '',
      rounds: List<Map<String, dynamic>>.from(
        (data['rounds'] ?? []).map((r) => Map<String, dynamic>.from(r)),
      ),
      currentRound: data['currentRound'] ?? 1,
      totalRounds: data['totalRounds'] ?? 5,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      chatId: data['chatId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gameType': gameType,
      'player1Id': player1Id,
      'player2Id': player2Id,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'player1Photo': player1Photo,
      'player2Photo': player2Photo,
      'status': status,
      'currentTurn': currentTurn,
      'currentQuestion': currentQuestion,
      'rounds': rounds,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'chatId': chatId,
    };
  }

  String getOtherPlayerId(String currentUserId) {
    return currentUserId == player1Id ? player2Id : player1Id;
  }

  String getOtherPlayerName(String currentUserId) {
    return currentUserId == player1Id ? player2Name : player1Name;
  }

  String? getOtherPlayerPhoto(String currentUserId) {
    return currentUserId == player1Id ? player2Photo : player1Photo;
  }

  bool isMyTurn(String currentUserId) {
    return currentTurn == currentUserId;
  }
}
