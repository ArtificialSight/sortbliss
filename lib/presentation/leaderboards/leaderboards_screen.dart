import 'package:flutter/material.dart';
import 'package:sortbliss/core/services/leaderboard_service.dart';

/// Global leaderboards screen with competitive rankings
class LeaderboardsScreen extends StatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  State<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends State<LeaderboardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<LeaderboardType, List<LeaderboardEntry>> _cachedLeaderboards = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: LeaderboardService.leaderboardTypes.length,
      vsync: this,
    );

    _tabController.addListener(_onTabChanged);

    _loadLeaderboard(LeaderboardType.allTime);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final type = LeaderboardService.leaderboardTypes[_tabController.index];
      _loadLeaderboard(type);
    }
  }

  Future<void> _loadLeaderboard(LeaderboardType type) async {
    if (_cachedLeaderboards.containsKey(type)) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await LeaderboardService.instance.initialize();
      final entries = await LeaderboardService.instance.getLeaderboard(type);

      setState(() {
        _cachedLeaderboards[type] = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Leaderboards'),
        backgroundColor: const Color(0xFF0F172A),
        bottom: TabBar(
          controller: _tabController,
          tabs: LeaderboardService.leaderboardTypes.map((type) {
            return Tab(text: type.displayName);
          }).toList(),
          indicatorColor: Colors.amber,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: LeaderboardService.leaderboardTypes.map((type) {
          return _buildLeaderboardTab(type);
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderboardTab(LeaderboardType type) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
        ),
      );
    }

    final entries = _cachedLeaderboards[type] ?? [];

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.leaderboard,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              'No rankings yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _cachedLeaderboards.remove(type);
        await _loadLeaderboard(type);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(type);
          }

          final entry = entries[index - 1];
          return _buildLeaderboardEntry(entry);
        },
      ),
    );
  }

  Widget _buildHeader(LeaderboardType type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.blue.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            type.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<int?>(
            future: LeaderboardService.instance.getUserRank(type),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox();
              }

              final rank = snapshot.data!;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Your Rank: #$rank',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? Colors.amber.withOpacity(0.2)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: entry.isCurrentUser
            ? Border.all(color: Colors.amber, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 50,
            child: Text(
              entry.rankDisplay,
              style: TextStyle(
                color: entry.rank <= 3 ? entry.rankColor : Colors.white,
                fontSize: entry.rank <= 3 ? 28 : 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 12),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.playerName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: entry.isCurrentUser
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ${entry.level} • ${entry.stars} ⭐',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'points',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
