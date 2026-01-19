import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/match_model.dart';
import '../../../core/constants/firebase_collections.dart';
import '../../widgets/common/loading_indicator.dart';

/// MatchesScreen - Displays mutual matches
/// Ported from web app MatchesPageV2.jsx
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<MatchModel> _matches = [];
  bool _isLoading = true;
  bool _useMockData = true;

  // Mock matches data
  final List<Map<String, dynamic>> _mockMatches = [
    {
      'id': 'match_1',
      'name': 'Jenny',
      'photo': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      'age': 26,
      'bio': 'Love hiking and coffee',
      'distance': '2 miles away',
      'matchedAt': DateTime.now().subtract(const Duration(hours: 2)),
      'isNew': true,
    },
    {
      'id': 'match_2',
      'name': 'Lily',
      'photo': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
      'age': 24,
      'bio': 'Yoga enthusiast & traveler',
      'distance': '5 miles away',
      'matchedAt': DateTime.now().subtract(const Duration(hours: 12)),
      'isNew': true,
    },
    {
      'id': 'match_3',
      'name': 'Caroline',
      'photo': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      'age': 28,
      'bio': 'Foodie & photographer',
      'distance': '3 miles away',
      'matchedAt': DateTime.now().subtract(const Duration(days: 1)),
      'isNew': false,
    },
    {
      'id': 'match_4',
      'name': 'Jennifer',
      'photo': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      'age': 25,
      'bio': 'Artist & music lover',
      'distance': '7 miles away',
      'matchedAt': DateTime.now().subtract(const Duration(days: 2)),
      'isNew': false,
    },
    {
      'id': 'match_5',
      'name': 'Marry Jane',
      'photo': 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400',
      'age': 27,
      'bio': 'Dog mom & runner',
      'distance': '4 miles away',
      'matchedAt': DateTime.now().subtract(const Duration(days: 3)),
      'isNew': false,
    },
    {
      'id': 'match_6',
      'name': 'Emma',
      'photo': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
      'age': 23,
      'bio': 'Beach lover & dancer',
      'distance': '6 miles away',
      'matchedAt': DateTime.now().subtract(const Duration(days: 4)),
      'isNew': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMockDataSetting();
  }

  Future<void> _loadMockDataSetting() async {
    try {
      final doc = await _firestore
          .collection('appSettings')
          .doc('development')
          .get();

      if (doc.exists && doc.data() != null) {
        final useMock = doc.data()!['useMockMessages'] as bool? ?? true;
        if (mounted) {
          setState(() => _useMockData = useMock);
        }
      }
    } catch (e) {
      debugPrint('Using default mock data setting due to: $e');
      if (mounted) {
        setState(() => _useMockData = true);
      }
    }
    
    if (_useMockData) {
      setState(() => _isLoading = false);
    } else {
      _loadMatches();
    }
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final matchesSnapshot = await _firestore
          .collection(FirebaseCollections.matches)
          .get();

      final matches = matchesSnapshot.docs
          .map((doc) => MatchModel.fromFirestore(doc))
          .where((match) =>
              match.user1Id == currentUser.uid ||
              match.user2Id == currentUser.uid)
          .toList();

      // Sort by most recent
      matches.sort((a, b) => b.matchedAt.compareTo(a.matchedAt));

      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading matches: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    final hasMatches = _useMockData ? _mockMatches.isNotEmpty : _matches.isNotEmpty;
    final matchCount = _useMockData ? _mockMatches.length : _matches.length;

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cupidPink.withOpacity(0.1),
                    AppColors.softIvory,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B9D), AppColors.cupidPink],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cupidPink.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Matches',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepPlum,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '$matchCount ${matchCount == 1 ? 'mutual connection' : 'mutual connections'}',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasMatches) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warmBlush,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cupidPink.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            size: 20,
                            color: AppColors.cupidPink,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tap on a match to start chatting!',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.deepPlum,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Matches Grid
            Expanded(
              child: !hasMatches
                  ? _buildEmptyState()
                  : _useMockData
                      ? _buildMockMatchesGrid()
                      : _buildRealMatchesGrid(),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.warmBlush,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cupidPink.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_border,
              size: 64,
              color: AppColors.cupidPink,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No matches yet',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.deepPlum,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'When someone likes you back,\nthey\'ll appear here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), AppColors.cupidPink],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cupidPink.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Start Swiping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockMatchesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _mockMatches.length,
      itemBuilder: (context, index) {
        final match = _mockMatches[index];
        return _buildMatchCard(
          name: match['name'] as String,
          photo: match['photo'] as String,
          age: match['age'] as int,
          bio: match['bio'] as String,
          distance: match['distance'] as String,
          isNew: match['isNew'] as bool,
          onTap: () => context.push('/chat/mock_${match['id']}'),
        );
      },
    );
  }

  Widget _buildRealMatchesGrid() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        final otherUserName = match.getOtherUserName(currentUserId);
        final otherUserPhoto = match.getOtherUserPhoto(currentUserId);
        final isNew = DateTime.now().difference(match.matchedAt).inHours < 24;

        return _buildMatchCard(
          name: otherUserName,
          photo: otherUserPhoto,
          age: null,
          bio: '',
          distance: '',
          isNew: isNew,
          onTap: () {
            if (match.chatId != null) {
              context.push('/chat/${match.chatId}');
            }
          },
        );
      },
    );
  }

  Widget _buildMatchCard({
    required String name,
    String? photo,
    int? age,
    String? bio,
    String? distance,
    required bool isNew,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.cupidPink.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              photo != null
                  ? Image.network(
                      photo,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[300]!, Colors.grey[200]!],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF6B9D), AppColors.cupidPink, AppColors.deepPlum],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // New badge
              if (isNew)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B9D), AppColors.cupidPink],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cupidPink.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

              // Content at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              age != null ? '$name, $age' : name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (distance != null && distance.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distance,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble,
                              size: 16,
                              color: AppColors.cupidPink,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Say Hi!',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepPlum,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
