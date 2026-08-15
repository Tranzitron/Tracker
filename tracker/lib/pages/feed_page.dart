import 'package:flutter/material.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/home_page.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/pages/analytics/progression_page.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/custom/custom_route.dart';
import 'package:tracker/pages/history/session_detail_page.dart';
import 'package:tracker/pages/settings/weight_format.dart';
import 'package:tracker/pages/settings_page.dart';

/// Personal activity feed built from completed workout sessions.
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  Stream<List<WorkoutSession>>? _stream;
  Map<int, String> _gymNames = const {};
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      final repo = RepositoryScope.maybeOf(context);
      _stream = repo?.sessions.watchAll();
      _loadGyms();
    }
  }

  Future<void> _loadGyms() async {
    final gyms =
        await RepositoryScope.maybeOf(context)?.gyms.getAll() ?? const [];
    if (!mounted) return;
    setState(() => _gymNames = {for (final gym in gyms) gym.id: gym.name});
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(
          context,
          title: 'Feed',
          actionButton: (
            title: 'Settings',
            onPressed: () => pushTo(context, const SettingsPage()),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Recent activity',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                _buildActivity(),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.show_chart_sharp),
                    title: const Text('Progression'),
                    subtitle: const Text(
                        'Strength and volume trends across all exercises'),
                    trailing: const Icon(Icons.chevron_right_sharp),
                    onTap: () => pushTo(context, const ProgressionPage()),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () =>
                      HomePageSingleton().changeTab(TabName.currentWorkout),
                  child: const Text('Go to Current Workout'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivity() {
    final stream = _stream;
    if (stream == null) return const _FeedEmpty();
    return StreamBuilder<List<WorkoutSession>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _FeedMessage(
            icon: Icons.error_outline,
            message: 'Could not load recent activity.',
            action: TextButton(
                onPressed: () => setState(() {}), child: const Text('Retry')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final sessions = [...snapshot.data ?? const <WorkoutSession>[]]..sort(
            (a, b) =>
                (b.endTime ?? b.startTime).compareTo(a.endTime ?? a.startTime));
        if (sessions.isEmpty) return const _FeedEmpty();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final session in sessions.take(5))
              _ActivityCard(
                session: session,
                gymName:
                    session.gymId == null ? null : _gymNames[session.gymId],
              ),
          ],
        );
      },
    );
  }
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.fitness_center, size: 40),
              SizedBox(height: 8),
              Text('No workouts logged yet.'),
              SizedBox(height: 4),
              Text('Complete a workout to see activity here.'),
            ],
          ),
        ),
      );
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
              if (action != null) action!,
            ],
          ),
        ),
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.session, this.gymName});

  final WorkoutSession session;
  final String? gymName;

  @override
  Widget build(BuildContext context) {
    final working = session.sets.where((set) => !set.isWarmup);
    final volume =
        working.fold<double>(0, (sum, set) => sum + set.weight * set.reps);
    final duration = session.endTime == null
        ? Duration.zero
        : session.endTime!.difference(session.startTime);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(session.title),
        subtitle: Text(
          '${_date(session.startTime)}${gymName == null ? '' : ' · $gymName'}\n'
          '${session.sets.length} sets · ${_duration(duration)} · ${formatWeight(context, volume)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_sharp),
        onTap: () => pushTo(
          context,
          SessionDetailPage(session: session, gymName: gymName),
        ),
      ),
    );
  }

  String _date(DateTime value) {
    final date = value.toLocal();
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  String _duration(Duration value) => value.inHours > 0
      ? '${value.inHours}h ${value.inMinutes % 60}m'
      : '${value.inMinutes}m';

  String _pad(int value) => value.toString().padLeft(2, '0');
}
