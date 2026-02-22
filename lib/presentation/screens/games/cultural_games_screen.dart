import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Cultural Exchange Games Screen
/// Users explore world cultures through interactive games — a key differentiator
class CulturalGamesScreen extends ConsumerStatefulWidget {
  const CulturalGamesScreen({super.key});

  @override
  ConsumerState<CulturalGamesScreen> createState() =>
      _CulturalGamesScreenState();
}

class _CulturalGamesScreenState extends ConsumerState<CulturalGamesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _random = Random();

  // Current game state
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedAnswer;
  String _selectedRegion = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // CULTURAL TRIVIA DATA
  // ──────────────────────────────────────────────

  static const List<Map<String, dynamic>> _triviaQuestions = [
    {
      'question': 'In Japan, what does it mean when you slurp your noodles loudly?',
      'options': ['It\'s rude', 'You enjoy the food', 'You want more', 'You\'re in a hurry'],
      'correct': 1,
      'explanation': 'In Japan, slurping noodles is a sign of enjoyment and appreciation for the food!',
      'region': 'Asia',
    },
    {
      'question': 'What is "Hygge" (hoo-gah) in Danish culture?',
      'options': ['A type of bread', 'A cozy feeling of contentment', 'A winter dance', 'A greeting'],
      'correct': 1,
      'explanation': 'Hygge is the Danish concept of cozy contentment — enjoying life\'s simple pleasures.',
      'region': 'Europe',
    },
    {
      'question': 'In India, what does touching someone\'s feet signify?',
      'options': ['Disrespect', 'A greeting', 'Deep respect for elders', 'A dance move'],
      'correct': 2,
      'explanation': 'Touching feet (Pranaam) in India is a sign of deep respect, usually towards elders.',
      'region': 'Asia',
    },
    {
      'question': 'What is the Ethiopian concept of "Gursha"?',
      'options': ['A holiday', 'Feeding someone by hand as a sign of love', 'A type of coffee', 'A song'],
      'correct': 1,
      'explanation': 'Gursha is the Ethiopian tradition of hand-feeding someone to show love and friendship.',
      'region': 'Africa',
    },
    {
      'question': 'In Brazil, what is a "Cafuné"?',
      'options': ['A dance move', 'Running fingers through someone\'s hair', 'A coffee ritual', 'A beach sport'],
      'correct': 1,
      'explanation': 'Cafuné is the tender act of running your fingers through someone\'s hair — uniquely Brazilian.',
      'region': 'Americas',
    },
    {
      'question': 'What does "Ubuntu" mean in Southern African philosophy?',
      'options': ['A computer system', '"I am because we are"', 'A greeting', 'A type of music'],
      'correct': 1,
      'explanation': 'Ubuntu means "I am because we are" — emphasizing our shared humanity and interconnection.',
      'region': 'Africa',
    },
    {
      'question': 'In Turkey, what happens when someone spills coffee on you?',
      'options': ['They owe you a new shirt', 'It means 40 years of friendship', 'Nothing special', 'Bad luck'],
      'correct': 1,
      'explanation': 'Turkish proverb: "A cup of coffee commits one to forty years of friendship."',
      'region': 'Middle East',
    },
    {
      'question': 'What is "Wabi-Sabi" in Japanese aesthetics?',
      'options': ['Perfection in art', 'Beauty in imperfection', 'A type of pottery', 'A tea ceremony'],
      'correct': 1,
      'explanation': 'Wabi-Sabi is finding beauty in imperfection — embracing the natural cycle of growth and decay.',
      'region': 'Asia',
    },
    {
      'question': 'In Argentina, what is a typical greeting between friends?',
      'options': ['Handshake', 'A kiss on the cheek', 'A bow', 'A wave'],
      'correct': 1,
      'explanation': 'In Argentina, friends greet each other with a kiss on the cheek, regardless of gender.',
      'region': 'Americas',
    },
    {
      'question': 'What is "Fika" in Swedish culture?',
      'options': ['A winter sport', 'A coffee break with pastries', 'A folk dance', 'A holiday'],
      'correct': 1,
      'explanation': 'Fika is the Swedish ritual of taking a coffee break with pastries — it\'s about slowing down and connecting.',
      'region': 'Europe',
    },
    {
      'question': 'In South Korea, who pours drinks at a dinner table?',
      'options': ['Everyone pours their own', 'The youngest person', 'You pour for others, never yourself', 'The host only'],
      'correct': 2,
      'explanation': 'In Korean culture, you always pour drinks for others — never for yourself. It shows respect.',
      'region': 'Asia',
    },
    {
      'question': 'What is "Saudade" in Portuguese culture?',
      'options': ['A celebration', 'A deep longing for something absent', 'A type of music', 'A dessert'],
      'correct': 1,
      'explanation': 'Saudade is a deep emotional state of longing for something or someone absent — considered untranslatable.',
      'region': 'Europe',
    },
    {
      'question': 'In Maori culture, what is the "Hongi"?',
      'options': ['A war dance', 'Pressing noses together in greeting', 'A type of food', 'A ceremonial gift'],
      'correct': 1,
      'explanation': 'The Hongi is the traditional Maori greeting where noses and foreheads are pressed together, sharing the breath of life.',
      'region': 'Oceania',
    },
    {
      'question': 'What does "Ikigai" represent in Japanese philosophy?',
      'options': ['Material wealth', 'Your reason for being', 'Physical fitness', 'Social status'],
      'correct': 1,
      'explanation': 'Ikigai means "a reason for being" — the intersection of what you love, what you\'re good at, and what the world needs.',
      'region': 'Asia',
    },
    {
      'question': 'In Mexico, what is the significance of "Día de los Muertos"?',
      'options': ['A horror festival', 'Celebrating and remembering deceased loved ones', 'A harvest festival', 'A political holiday'],
      'correct': 1,
      'explanation': 'Día de los Muertos is a joyful celebration honoring deceased loved ones, believing their spirits return for a visit.',
      'region': 'Americas',
    },
  ];

  // ──────────────────────────────────────────────
  // GUESS THE CUSTOM DATA
  // ──────────────────────────────────────────────

  static const List<Map<String, String>> _customs = [
    {
      'emoji': '🇯🇵',
      'custom': 'Taking off shoes before entering a home',
      'country': 'Japan',
      'explanation': 'Removing shoes keeps the home clean and is a sign of respect in Japanese culture.',
    },
    {
      'emoji': '🇮🇳',
      'custom': 'Eating with your right hand only',
      'country': 'India',
      'explanation': 'The left hand is considered unclean in many South Asian cultures, so food is eaten with the right.',
    },
    {
      'emoji': '🇬🇧',
      'custom': 'Queuing patiently in a straight line',
      'country': 'United Kingdom',
      'explanation': 'The British are famous for their love of orderly queues — cutting in line is a serious social faux pas!',
    },
    {
      'emoji': '🇹🇭',
      'custom': 'Never touching someone\'s head',
      'country': 'Thailand',
      'explanation': 'The head is considered the most sacred part of the body in Thai culture.',
    },
    {
      'emoji': '🇫🇷',
      'custom': 'Greeting with kisses on each cheek',
      'country': 'France',
      'explanation': 'La bise is the standard French greeting — the number of kisses varies by region!',
    },
    {
      'emoji': '🇰🇷',
      'custom': 'Using both hands when giving or receiving something',
      'country': 'South Korea',
      'explanation': 'Using both hands shows respect and politeness, especially with elders.',
    },
    {
      'emoji': '🇧🇷',
      'custom': 'Arriving 15-30 minutes late to social events',
      'country': 'Brazil',
      'explanation': 'In Brazil, arriving exactly on time to a party might mean you arrive before the host is ready!',
    },
    {
      'emoji': '🇪🇬',
      'custom': 'Never refusing a cup of tea offered by a host',
      'country': 'Egypt',
      'explanation': 'Tea is a symbol of hospitality in Egypt — refusing it can be seen as rejecting the host\'s kindness.',
    },
  ];

  // ──────────────────────────────────────────────
  // LOVE LANGUAGE CULTURES DATA
  // ──────────────────────────────────────────────

  static const List<Map<String, String>> _loveTraditions = [
    {
      'title': 'Love Locks — Paris, France',
      'description': 'Couples attach padlocks to bridges and throw away the key as a symbol of eternal love.',
      'emoji': '🔒',
    },
    {
      'title': 'Spoon Carving — Wales',
      'description': 'A man carves an intricate wooden spoon to give to the woman he loves. The more detailed, the deeper the love.',
      'emoji': '🥄',
    },
    {
      'title': 'Mangalsutra — India',
      'description': 'A sacred necklace tied by the groom around the bride\'s neck during the wedding, symbolizing a lifelong bond.',
      'emoji': '📿',
    },
    {
      'title': 'Handfasting — Celtic/Irish',
      'description': 'An ancient wedding ritual where the couple\'s hands are tied together with ribbon, giving us the phrase "tying the knot."',
      'emoji': '🪢',
    },
    {
      'title': 'Tanabata — Japan',
      'description': 'On July 7th, lovers write wishes on paper strips and hang them on bamboo branches, celebrating star-crossed lovers Orihime and Hikoboshi.',
      'emoji': '🎋',
    },
    {
      'title': 'Jumping the Broom — African-American',
      'description': 'A wedding tradition where couples jump over a broom together, symbolizing sweeping away the past and starting fresh.',
      'emoji': '🧹',
    },
    {
      'title': 'Claddagh Ring — Ireland',
      'description': 'A ring with two hands holding a heart topped by a crown. How you wear it signals if you\'re single, dating, or married.',
      'emoji': '💍',
    },
    {
      'title': 'Red Thread of Fate — Chinese/Japanese',
      'description': 'An invisible red thread connects two people who are destined to be together — it may stretch or tangle, but never break.',
      'emoji': '🧵',
    },
  ];

  List<Map<String, dynamic>> get _filteredQuestions {
    if (_selectedRegion == 'All') return _triviaQuestions;
    return _triviaQuestions
        .where((q) => q['region'] == _selectedRegion)
        .toList();
  }

  void _answerQuestion(int index) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedAnswer = index;
      if (index == _filteredQuestions[_currentQuestionIndex]['correct']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _filteredQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answered = false;
        _selectedAnswer = null;
      });
    } else {
      _showResultsDialog();
    }
  }

  void _resetTriviaQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _answered = false;
      _selectedAnswer = null;
    });
  }

  void _showResultsDialog() {
    final total = _filteredQuestions.length;
    final pct = (_score / total * 100).round();
    String message;
    IconData icon;
    Color iconColor;
    if (pct >= 80) {
      message = 'Cultural Ambassador! You really know the world.';
      icon = Icons.public;
      iconColor = const Color(0xFF00B894);
    } else if (pct >= 50) {
      message = 'Great effort! Keep exploring world cultures.';
      icon = Icons.school;
      iconColor = AppColors.cupidPink;
    } else {
      message = 'There\'s so much to discover! Play again?';
      icon = Icons.emoji_nature;
      iconColor = const Color(0xFF6C5CE7);
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 56),
              const SizedBox(height: 16),
              Text(
                '$_score / $total',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepPlum,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.deepPlum.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetTriviaQuiz();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.cupidPink),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Play Again',
                        style: TextStyle(color: AppColors.cupidPink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cupidPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Done',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────

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
          'Cultural Exchange',
          style: TextStyle(
            color: AppColors.deepPlum,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cupidPink,
          labelColor: AppColors.cupidPink,
          unselectedLabelColor: AppColors.deepPlum.withOpacity(0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Trivia'),
            Tab(text: 'Customs'),
            Tab(text: 'Love Traditions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTriviaTab(),
          _buildCustomsTab(),
          _buildLoveTraditionsTab(),
        ],
      ),
    );
  }

  // ── TAB 1: Cultural Trivia ──

  Widget _buildTriviaTab() {
    final questions = _filteredQuestions;
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.public,
              color: AppColors.cupidPink,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text('No questions for this region yet!',
                style: TextStyle(fontSize: 16, color: AppColors.deepPlum)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _selectedRegion = 'All'),
              child: const Text('Show all regions'),
            ),
          ],
        ),
      );
    }

    final q = questions[_currentQuestionIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Region filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Asia', 'Europe', 'Africa', 'Americas', 'Middle East', 'Oceania']
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(r),
                          selected: _selectedRegion == r,
                          selectedColor: AppColors.cupidPink,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: _selectedRegion == r
                                ? AppColors.cupidPink
                                : AppColors.deepPlum.withOpacity(0.2),
                          ),
                          labelStyle: TextStyle(
                            color: _selectedRegion == r
                                ? Colors.white
                                : AppColors.deepPlum,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedRegion = r;
                              _resetTriviaQuiz();
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Progress
          Row(
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.deepPlum.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cupidPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score: $_score',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.cupidPink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / questions.length,
            backgroundColor: AppColors.warmBlush,
            valueColor: const AlwaysStoppedAnimation(AppColors.cupidPink),
          ),
          const SizedBox(height: 24),

          // Question Card
          Container(
            width: double.infinity,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cupidPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    q['region'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cupidPink,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  q['question'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPlum,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Options
          ...List.generate((q['options'] as List).length, (i) {
            final isCorrect = i == q['correct'];
            final isSelected = _selectedAnswer == i;
            Color bg = Colors.white;
            Color border = AppColors.warmBlush;
            if (_answered) {
              if (isCorrect) {
                bg = Colors.green.withOpacity(0.1);
                border = Colors.green;
              } else if (isSelected) {
                bg = Colors.red.withOpacity(0.1);
                border = Colors.red;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _answerQuestion(i),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border, width: _answered && (isCorrect || isSelected) ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _answered && isCorrect
                              ? Colors.green
                              : _answered && isSelected
                                  ? Colors.red
                                  : AppColors.warmBlush,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: _answered && isCorrect
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : _answered && isSelected
                                  ? const Icon(Icons.close, color: Colors.white, size: 16)
                                  : Text(
                                      String.fromCharCode(65 + i),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepPlum,
                                        fontSize: 13,
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          (q['options'] as List)[i] as String,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.deepPlum,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Explanation + Next
          if (_answered) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cupidPink.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q['explanation'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.deepPlum.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cupidPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _currentQuestionIndex < _filteredQuestions.length - 1
                      ? 'Next Question'
                      : 'See Results',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── TAB 2: Guess the Custom ──

  Widget _buildCustomsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _customs.length,
      itemBuilder: (context, index) {
        return _CustomCard(custom: _customs[index]);
      },
    );
  }

  // ── TAB 3: Love Traditions ──

  Widget _buildLoveTraditionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _loveTraditions.length,
      itemBuilder: (context, index) {
        final item = _loveTraditions[index];
        return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['emoji']!, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['description']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.deepPlum.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Flip-card widget for Guess the Custom game
class _CustomCard extends StatefulWidget {
  final Map<String, String> custom;
  const _CustomCard({required this.custom});

  @override
  State<_CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<_CustomCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.custom;
    return GestureDetector(
      onTap: () => setState(() => _revealed = !_revealed),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _revealed ? AppColors.cupidPink.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _revealed ? AppColors.cupidPink : AppColors.warmBlush,
            width: _revealed ? 2 : 1,
          ),
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
                Text(c['emoji']!, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _revealed ? c['country']! : 'Tap to reveal country',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _revealed
                          ? AppColors.cupidPink
                          : AppColors.deepPlum.withOpacity(0.5),
                    ),
                  ),
                ),
                Icon(
                  _revealed ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.deepPlum.withOpacity(0.3),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              c['custom']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.deepPlum,
                height: 1.3,
              ),
            ),
            if (_revealed) ...[
              const SizedBox(height: 10),
              Text(
                c['explanation']!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.deepPlum.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
