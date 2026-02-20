import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// AI-powered cultural conversation starters
/// Shows contextual icebreakers the user can tap to send in chat
class ConversationStartersSheet extends StatefulWidget {
  /// Callback when user selects a starter to send
  final void Function(String message) onSend;
  final String? otherUserName;
  final String? otherUserLocation;
  final List<String>? otherUserInterests;

  const ConversationStartersSheet({
    super.key,
    required this.onSend,
    this.otherUserName,
    this.otherUserLocation,
    this.otherUserInterests,
  });

  @override
  State<ConversationStartersSheet> createState() =>
      _ConversationStartersSheetState();
}

class _ConversationStartersSheetState extends State<ConversationStartersSheet> {
  final _random = Random();
  String _selectedCategory = 'Cultural';
  late List<String> _currentStarters;

  // ──────────────────────────────────────────────
  // STARTER CATEGORIES
  // ──────────────────────────────────────────────

  static const Map<String, List<String>> _startersByCategory = {
    'Cultural': [
      "What's a tradition from your culture that you absolutely love? I'd really like to learn about it!",
      "If you could take me to your favorite place in your hometown, where would we go first?",
      "What's a dish from your culture that everyone should try at least once?",
      "Is there a festival or celebration from your background that you look forward to every year?",
      "What's something about your culture that surprises people when you tell them?",
      "If we traveled to each other's hometowns, what's the first thing you'd want to show me?",
      "What's the most beautiful word or phrase in your native language? I'd love to learn it!",
      "Do you have a family recipe that's been passed down through generations?",
      "What music or artists do people in your culture grow up listening to?",
      "What's a cultural norm from your background that you think the rest of the world should adopt?",
    ],
    'Deep': [
      "What's something you're passionate about that most people don't expect?",
      "If you could live in any era, when would you choose and why?",
      "What's the best piece of advice you've ever received?",
      "What does your ideal weekend look like?",
      "If you could master any skill overnight, what would it be?",
      "What's the most spontaneous thing you've ever done?",
      "What small thing always makes your day better?",
      "What's on your bucket list that you haven't done yet?",
      "What's a belief you held strongly but changed your mind about?",
      "If you wrote a book about your life, what would the title be?",
    ],
    'Fun': [
      "If you had to eat one cuisine for the rest of your life, what would it be?",
      "What's your go-to karaoke song? (No judgment, I promise!)",
      "If you could have dinner with anyone in history, who would it be?",
      "What's the worst movie you secretly love?",
      "Would you rather travel back in time or into the future?",
      "If you were a character in a TV show, which show would it be?",
      "What's the most useless talent you have?",
      "If you could live in any fictional world, where would you go?",
      "What's the most random fact you know?",
      "Pineapple on pizza — yes or no? This is a make-or-break question!",
    ],
    'Travel': [
      "What's the most beautiful place you've ever visited?",
      "If money and time were no object, where would your dream trip be?",
      "Do you prefer mountains or beaches? (Choose wisely!)",
      "What's the most interesting food you've tried while traveling?",
      "Have you ever experienced culture shock? What happened?",
      "What's one country you'd love to visit but haven't yet?",
      "Do you prefer planned itineraries or spontaneous adventures?",
      "What's the best souvenir you've ever brought home?",
      "Have you ever learned a phrase in another language while traveling?",
      "If you could teleport anywhere right now, where would you go?",
    ],
  };

  @override
  void initState() {
    super.initState();
    _refreshStarters();
  }

  void _refreshStarters() {
    final allStarters =
        _startersByCategory[_selectedCategory] ?? _startersByCategory['Cultural']!;
    final shuffled = List<String>.from(allStarters)..shuffle(_random);
    setState(() {
      _currentStarters = shuffled.take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cupidPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: AppColors.cupidPink, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conversation Starters',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepPlum,
                        ),
                      ),
                      Text(
                        'Tap a message to send it',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.cupidPink),
                  tooltip: 'Shuffle',
                  onPressed: _refreshStarters,
                ),
              ],
            ),
          ),

          // Category chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _startersByCategory.keys.map((cat) {
                final isSelected = _selectedCategory == cat;
                final icon = _categoryIcon(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(icon,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.deepPlum),
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.cupidPink,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.cupidPink
                          : AppColors.deepPlum.withOpacity(0.2),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.deepPlum,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                      _refreshStarters();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Starters list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _currentStarters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final starter = _currentStarters[index];
                return GestureDetector(
                  onTap: () {
                    widget.onSend(starter);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.softIvory,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.warmBlush),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            starter,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.deepPlum,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.cupidPink.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: AppColors.cupidPink,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Cultural':
        return Icons.public;
      case 'Deep':
        return Icons.psychology;
      case 'Fun':
        return Icons.emoji_emotions;
      case 'Travel':
        return Icons.flight;
      default:
        return Icons.chat;
    }
  }
}

/// Convenience function to show the sheet from anywhere
void showConversationStarters(
  BuildContext context, {
  required void Function(String message) onSend,
  String? otherUserName,
  String? otherUserLocation,
  List<String>? otherUserInterests,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.65,
    ),
    builder: (_) => ConversationStartersSheet(
      onSend: onSend,
      otherUserName: otherUserName,
      otherUserLocation: otherUserLocation,
      otherUserInterests: otherUserInterests,
    ),
  );
}
