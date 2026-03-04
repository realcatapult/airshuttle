import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'airshuttle_store.dart';
import 'models.dart';

enum PublicSitePage { home, features, rankings, teams, account }

void _showSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(description),
            ],
          ),
        ),
      ),
    );
  }
}

class _AirshuttleHomeTitle extends StatelessWidget {
  const _AirshuttleHomeTitle();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () =>
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_tennis,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Airshuttle'),
        ],
      ),
    );
  }
}

class AirShuttleApp extends StatefulWidget {
  const AirShuttleApp({super.key});

  @override
  State<AirShuttleApp> createState() => _AirShuttleAppState();
}

class _AirShuttleAppState extends State<AirShuttleApp> {
  late final AirShuttleStore _store;

  @override
  void initState() {
    super.initState();
    _store = AirShuttleStore();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Airshuttle',
          themeMode: _store.themeMode,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF1565C0),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF3F6FB),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF1565C0),
            useMaterial3: true,
            brightness: Brightness.dark,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          onGenerateRoute: (settings) {
            final uri = Uri.parse(settings.name ?? '/');

            if (uri.pathSegments.length == 2 &&
                uri.pathSegments.first == 'player') {
              final playerId = Uri.decodeComponent(uri.pathSegments[1]);
              final player = _store.playerById(playerId);

              if (player != null) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) =>
                      PlayerProfileDetailPage(store: _store, player: player),
                );
              }

              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => PlayerNotFoundPage(
                  store: _store,
                  missingPlayerId: playerId,
                ),
              );
            }

            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => _store.isAuthenticated
                  ? DashboardScreen(store: _store)
                  : AuthScreen(store: _store),
            );
          },
        );
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.store});

  final AirShuttleStore store;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginEmailController = TextEditingController(
    text: 'noor@airshuttle.app',
  );
  final _loginPasswordController = TextEditingController(text: 'pass123');

  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerSchoolController = TextEditingController();
  final _registerAvatarImageController = TextEditingController();
  final _newTeamNameController = TextEditingController();
  final _newTeamSchoolController = TextEditingController();
  final _newTeamCityController = TextEditingController();

  UserRole _registerRole = UserRole.player;
  bool _useExistingTeam = true;
  String? _existingTeamId;
  String _selectedEmoji = AirShuttleStore.avatarEmojis.first;
  int _selectedColor = AirShuttleStore.avatarPaletteValues.first;
  PublicSitePage _selectedPublicPage = PublicSitePage.home;

  @override
  void initState() {
    super.initState();
    if (widget.store.teams.isNotEmpty) {
      _existingTeamId = widget.store.teams.first.id;
      _registerSchoolController.text = widget.store.teams.first.school;
    }
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerSchoolController.dispose();
    _registerAvatarImageController.dispose();
    _newTeamNameController.dispose();
    _newTeamSchoolController.dispose();
    _newTeamCityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 960;

    return Scaffold(
      appBar: AppBar(
        title: const _AirshuttleHomeTitle(),
        actions: isWide
            ? [
                _siteNavButton('Home', PublicSitePage.home),
                _siteNavButton('Features', PublicSitePage.features),
                _siteNavButton('Rankings', PublicSitePage.rankings),
                _siteNavButton('Teams', PublicSitePage.teams),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _setPublicPage(PublicSitePage.account),
                  child: const Text('Sign In'),
                ),
                const SizedBox(width: 12),
              ]
            : [
                IconButton(
                  tooltip: 'Open account',
                  onPressed: () => _setPublicPage(PublicSitePage.account),
                  icon: const Icon(Icons.login),
                ),
              ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    const ListTile(
                      title: Text(
                        'Airshuttle',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _siteDrawerTile('Home', PublicSitePage.home),
                    _siteDrawerTile('Features', PublicSitePage.features),
                    _siteDrawerTile('Rankings', PublicSitePage.rankings),
                    _siteDrawerTile('Teams', PublicSitePage.teams),
                    _siteDrawerTile('Sign In', PublicSitePage.account),
                  ],
                ),
              ),
            ),
      body: SafeArea(child: _buildPublicWebsiteBody(context)),
    );
  }

  Widget _buildPublicWebsiteBody(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final topPlayers = widget.store.players.take(5).toList();

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: switch (_selectedPublicPage) {
                    PublicSitePage.home => _buildPublicHomePage(context),
                    PublicSitePage.features => _buildPublicFeaturesPage(
                      context,
                    ),
                    PublicSitePage.rankings => _buildPublicRankingsPage(
                      context,
                    ),
                    PublicSitePage.teams => _buildPublicTeamsPage(context),
                    PublicSitePage.account => _buildPublicAccountPage(context),
                  },
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        Text('Players: ${widget.store.players.length}'),
                        Text('Teams: ${widget.store.teams.length}'),
                        Text('Matches: ${widget.store.matches.length}'),
                        if (topPlayers.isNotEmpty)
                          Text(
                            'Top Player: ${topPlayers.first.fullName} (${topPlayers.first.rating.toStringAsFixed(2)} AR)',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '© ${DateTime.now().year} Airshuttle • Built for badminton teams and athletes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (width < 960) const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPublicHomePage(BuildContext context) {
    return Column(
      key: const ValueKey(PublicSitePage.home),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Wrap(
              runSpacing: 18,
              spacing: 24,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The badminton ranking platform for schools and teams',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Airshuttle gives you dynamic player rankings, verified match uploads, and shareable athlete profiles inspired by modern competitive sports platforms.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton(
                            onPressed: () =>
                                _setPublicPage(PublicSitePage.account),
                            child: const Text('Get Started'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                _setPublicPage(PublicSitePage.features),
                            child: const Text('Explore Features'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard('Rankings', 'Global, school, and team ladders'),
            _statCard('Profiles', 'Player records and match history'),
            _statCard('Match Uploads', 'Coach/player submissions with review'),
          ],
        ),
      ],
    );
  }

  Widget _buildPublicFeaturesPage(BuildContext context) {
    return Column(
      key: const ValueKey(PublicSitePage.features),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Features', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _FeatureCard(
              title: 'Dynamic AirRating',
              description:
                  'Performance updates after approved singles and doubles results.',
            ),
            _FeatureCard(
              title: 'School + Team Rosters',
              description:
                  'Athletes register with teams and appear in public rosters.',
            ),
            _FeatureCard(
              title: 'Match Verification',
              description:
                  'Uploads can be reviewed by admins before impacting rankings.',
            ),
            _FeatureCard(
              title: 'Player Discovery',
              description:
                  'Search players and inspect records, reliability, and recent results.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPublicRankingsPage(BuildContext context) {
    final players = widget.store.players.take(20).toList();
    return Column(
      key: const ValueKey(PublicSitePage.rankings),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Public Leaderboard',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        if (players.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No rankings available yet.'),
            ),
          )
        else
          ...players.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final team = widget.store.teamById(player.teamId);
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(player.fullName),
                subtitle: Text('${team?.name ?? 'No team'} • ${player.school}'),
                trailing: Text('${player.rating.toStringAsFixed(2)} AR'),
                onTap: () => _openPlayerProfile(context, widget.store, player),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPublicTeamsPage(BuildContext context) {
    final teams = widget.store.teams;

    return Column(
      key: const ValueKey(PublicSitePage.teams),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Teams', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        ...teams.map((team) {
          final roster = widget.store.rosterForTeam(team.id);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${team.school} • ${team.city}'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: roster
                        .map(
                          (player) => ActionChip(
                            label: Text(player.fullName),
                            onPressed: () => _openPlayerProfile(
                              context,
                              widget.store,
                              player,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPublicAccountPage(BuildContext context) {
    return Column(
      key: const ValueKey(PublicSitePage.account),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Demo login: noor@airshuttle.app / pass123 (player) • admin@airshuttle.app / admin123 (admin)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 680,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Login'),
                        Tab(text: 'Register'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildLoginTab(context),
                          _buildRegisterTab(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _siteNavButton(String label, PublicSitePage page) {
    final isSelected = _selectedPublicPage == page;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: () {
          _setPublicPage(page);
        },
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _siteDrawerTile(String label, PublicSitePage page) {
    return ListTile(
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        _setPublicPage(page);
      },
    );
  }

  Widget _statCard(String title, String subtitle) {
    return SizedBox(
      width: 320,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(BuildContext context) {
    return ListView(
      children: [
        TextField(
          controller: _loginEmailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            final error = widget.store.login(
              email: _loginEmailController.text,
              password: _loginPasswordController.text,
            );
            if (error != null) {
              _showSnackBar(context, error);
              return;
            }
            _showSnackBar(context, 'Welcome back to Airshuttle.');
          },
          icon: const Icon(Icons.login),
          label: const Text('Sign In'),
        ),
      ],
    );
  }

  Widget _buildRegisterTab(BuildContext context) {
    final teams = widget.store.teams;

    return ListView(
      children: [
        TextField(
          controller: _registerNameController,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerEmailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<UserRole>(
          initialValue: _registerRole,
          items: UserRole.values
              .map(
                (role) =>
                    DropdownMenuItem(value: role, child: Text(role.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _registerRole = value;
            });
          },
          decoration: const InputDecoration(labelText: 'Role'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerSchoolController,
          decoration: const InputDecoration(labelText: 'School'),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _useExistingTeam,
          title: const Text('Join existing team'),
          onChanged: (value) {
            setState(() {
              _useExistingTeam = value;
            });
          },
        ),
        if (_useExistingTeam) ...[
          DropdownButtonFormField<String>(
            initialValue: _existingTeamId,
            items: teams
                .map(
                  (team) => DropdownMenuItem(
                    value: team.id,
                    child: Text('${team.name} • ${team.school}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _existingTeamId = value;
              });
              final selectedTeam = teams.where((team) => team.id == value);
              if (selectedTeam.isNotEmpty) {
                _registerSchoolController.text = selectedTeam.first.school;
              }
            },
            decoration: const InputDecoration(labelText: 'Team'),
          ),
        ] else ...[
          TextField(
            controller: _newTeamNameController,
            decoration: const InputDecoration(labelText: 'New team name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newTeamSchoolController,
            decoration: const InputDecoration(labelText: 'Team school'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newTeamCityController,
            decoration: const InputDecoration(labelText: 'Team city'),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Profile picture customization',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(_selectedColor),
              child: Text(_selectedEmoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _registerAvatarImageController,
                decoration: const InputDecoration(
                  labelText: 'Optional profile image URL',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedEmoji,
          items: AirShuttleStore.avatarEmojis
              .map(
                (emoji) => DropdownMenuItem(value: emoji, child: Text(emoji)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _selectedEmoji = value;
            });
          },
          decoration: const InputDecoration(labelText: 'Avatar icon'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _selectedColor,
          items: AirShuttleStore.avatarPaletteValues
              .map(
                (colorValue) => DropdownMenuItem(
                  value: colorValue,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(colorValue),
                      ),
                      const SizedBox(width: 8),
                      Text('#${colorValue.toRadixString(16).toUpperCase()}'),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _selectedColor = value;
            });
          },
          decoration: const InputDecoration(labelText: 'Avatar color'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            final error = widget.store.register(
              fullName: _registerNameController.text,
              email: _registerEmailController.text,
              password: _registerPasswordController.text,
              role: _registerRole,
              school: _registerSchoolController.text,
              existingTeamId: _useExistingTeam ? _existingTeamId : null,
              newTeamName: _useExistingTeam
                  ? null
                  : _newTeamNameController.text,
              newTeamSchool: _useExistingTeam
                  ? null
                  : _newTeamSchoolController.text,
              newTeamCity: _useExistingTeam
                  ? null
                  : _newTeamCityController.text,
              avatarEmoji: _selectedEmoji,
              avatarColorValue: _selectedColor,
              avatarImageUrl: _registerAvatarImageController.text,
            );
            if (error != null) {
              _showSnackBar(context, error);
              return;
            }
            _showSnackBar(context, 'Account created and signed in.');
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Create Account'),
        ),
      ],
    );
  }

  void _setPublicPage(PublicSitePage page) {
    setState(() {
      _selectedPublicPage = page;
    });
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.store});

  final AirShuttleStore store;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktopLayout = width >= 1024;

    final user = widget.store.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final navItems = <_NavPage>[
      _NavPage(
        label: 'Rankings',
        icon: Icons.leaderboard,
        child: RankingsPage(store: widget.store),
      ),
      _NavPage(
        label: 'Matches',
        icon: Icons.upload_file,
        child: MatchHubPage(store: widget.store),
      ),
      _NavPage(
        label: 'Teams',
        icon: Icons.groups,
        child: TeamsPage(store: widget.store),
      ),
      _NavPage(
        label: 'Discover',
        icon: Icons.search,
        child: DiscoverPage(store: widget.store),
      ),
      _NavPage(
        label: 'Profile',
        icon: Icons.person,
        child: ProfilePage(store: widget.store),
      ),
      _NavPage(
        label: 'Settings',
        icon: Icons.settings,
        child: SettingsPage(store: widget.store),
      ),
      if (user.isAdmin)
        _NavPage(
          label: 'Admin',
          icon: Icons.admin_panel_settings,
          child: AdminPage(store: widget.store),
        ),
    ];

    final safeIndex = _selectedIndex.clamp(0, navItems.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: const _AirshuttleHomeTitle(),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Rank #${widget.store.rankOfPlayer(user.id)} • ${user.rating.toStringAsFixed(2)} AR',
              ),
            ),
          ),
        ],
      ),
      body: isDesktopLayout
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: safeIndex,
                  onDestinationSelected: _setSelectedIndex,
                  labelType: NavigationRailLabelType.all,
                  destinations: navItems
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: navItems[safeIndex].child),
              ],
            )
          : navItems[safeIndex].child,
      bottomNavigationBar: isDesktopLayout
          ? null
          : NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: _setSelectedIndex,
              destinations: navItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  void _setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _NavPage {
  _NavPage({required this.label, required this.icon, required this.child});

  final String label;
  final IconData icon;
  final Widget child;
}

enum RankingScope { global, school, team }

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key, required this.store});

  final AirShuttleStore store;

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  RankingScope _scope = RankingScope.global;
  String? _compareAId;
  String? _compareBId;

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.store.currentUser;
    final allPlayers = widget.store.players;

    final scopedPlayers = switch (_scope) {
      RankingScope.global => widget.store.rankedPlayers(),
      RankingScope.school => widget.store.rankedPlayers(
        school: currentUser?.school,
      ),
      RankingScope.team => widget.store.rankedPlayers(
        teamId: currentUser?.teamId,
      ),
    };

    _ensureComparePlayers(allPlayers);

    final compareA = _compareAId == null
        ? null
        : widget.store.playerById(_compareAId!);
    final compareB = _compareBId == null
        ? null
        : widget.store.playerById(_compareBId!);
    final compareProb = (compareA != null && compareB != null)
        ? widget.store.winProbability(compareA.id, compareB.id)
        : 0.5;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ranking Scope',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RankingScope>(
                  initialValue: _scope,
                  items: const [
                    DropdownMenuItem(
                      value: RankingScope.global,
                      child: Text('Global'),
                    ),
                    DropdownMenuItem(
                      value: RankingScope.school,
                      child: Text('My School'),
                    ),
                    DropdownMenuItem(
                      value: RankingScope.team,
                      child: Text('My Team'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _scope = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Head-to-Head Forecast',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _compareAId,
                  items: allPlayers
                      .map(
                        (player) => DropdownMenuItem(
                          value: player.id,
                          child: Text(player.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _compareAId = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Player A'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _compareBId,
                  items: allPlayers
                      .map(
                        (player) => DropdownMenuItem(
                          value: player.id,
                          child: Text(player.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _compareBId = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Player B'),
                ),
                const SizedBox(height: 12),
                if (compareA != null && compareB != null)
                  Text(
                    '${compareA.fullName}: ${(compareProb * 100).toStringAsFixed(1)}% win chance • ${compareB.fullName}: ${((1 - compareProb) * 100).toStringAsFixed(1)}%',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Leaderboard', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (scopedPlayers.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No players found for this scope.'),
            ),
          )
        else
          ...scopedPlayers.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final team = widget.store.teamById(player.teamId);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.shade100,
                  child: Text('${index + 1}'),
                ),
                title: Text(player.fullName),
                subtitle: Text(
                  '${team?.name ?? 'No team'} • ${player.school} • ${player.wins}-${player.losses}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${player.rating.toStringAsFixed(2)} AR'),
                    Text('${player.reliability}% reliability'),
                  ],
                ),
                onTap: () => _openPlayerProfile(context, widget.store, player),
              ),
            );
          }),
      ],
    );
  }

  void _ensureComparePlayers(List<PlayerProfile> players) {
    if (players.isEmpty) {
      _compareAId = null;
      _compareBId = null;
      return;
    }

    _compareAId ??= players.first.id;
    _compareBId ??= players.length > 1 ? players[1].id : players.first.id;

    final playerIds = players.map((player) => player.id).toSet();
    if (!playerIds.contains(_compareAId)) {
      _compareAId = players.first.id;
    }
    if (!playerIds.contains(_compareBId)) {
      _compareBId = players.length > 1 ? players[1].id : players.first.id;
    }
  }
}

class MatchHubPage extends StatefulWidget {
  const MatchHubPage({super.key, required this.store});

  final AirShuttleStore store;

  @override
  State<MatchHubPage> createState() => _MatchHubPageState();
}

class _MatchHubPageState extends State<MatchHubPage> {
  MatchFormat _format = MatchFormat.singles;
  String? _sideA1;
  String? _sideA2;
  String? _sideB1;
  String? _sideB2;
  DateTime _playedAt = DateTime.now();

  final _eventController = TextEditingController();
  final _set1AController = TextEditingController();
  final _set1BController = TextEditingController();
  final _set2AController = TextEditingController();
  final _set2BController = TextEditingController();
  final _set3AController = TextEditingController();
  final _set3BController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final players = widget.store.players;
    if (players.isNotEmpty) {
      _sideA1 = players.first.id;
      _sideB1 = players.length > 1 ? players[1].id : players.first.id;
      _sideA2 = players.length > 2 ? players[2].id : players.first.id;
      _sideB2 = players.length > 3 ? players[3].id : players.first.id;
    }
  }

  @override
  void dispose() {
    _eventController.dispose();
    _set1AController.dispose();
    _set1BController.dispose();
    _set2AController.dispose();
    _set2BController.dispose();
    _set3AController.dispose();
    _set3BController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.store.players;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Match',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MatchFormat>(
                  initialValue: _format,
                  items: MatchFormat.values
                      .map(
                        (format) => DropdownMenuItem(
                          value: format,
                          child: Text(format.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _format = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Match format'),
                ),
                const SizedBox(height: 12),
                _playerDropdown(
                  label: 'Side A - Player 1',
                  value: _sideA1,
                  players: players,
                  onChanged: (value) => setState(() => _sideA1 = value),
                ),
                const SizedBox(height: 8),
                if (_format == MatchFormat.doubles) ...[
                  _playerDropdown(
                    label: 'Side A - Player 2',
                    value: _sideA2,
                    players: players,
                    onChanged: (value) => setState(() => _sideA2 = value),
                  ),
                  const SizedBox(height: 8),
                ],
                _playerDropdown(
                  label: 'Side B - Player 1',
                  value: _sideB1,
                  players: players,
                  onChanged: (value) => setState(() => _sideB1 = value),
                ),
                const SizedBox(height: 8),
                if (_format == MatchFormat.doubles) ...[
                  _playerDropdown(
                    label: 'Side B - Player 2',
                    value: _sideB2,
                    players: players,
                    onChanged: (value) => setState(() => _sideB2 = value),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _eventController,
                  decoration: const InputDecoration(
                    labelText: 'Event / tournament name',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Select match date'),
                    ),
                    Text('Selected: ${_formatDate(_playedAt)}'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Set scores',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _setRow('Set 1', _set1AController, _set1BController),
                const SizedBox(height: 8),
                _setRow('Set 2', _set2AController, _set2BController),
                const SizedBox(height: 8),
                _setRow('Set 3 (optional)', _set3AController, _set3BController),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload Result'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Recent Match Uploads',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...widget.store.matches
            .take(20)
            .map((match) => MatchTile(store: widget.store, match: match)),
      ],
    );
  }

  Widget _playerDropdown({
    required String label,
    required String? value,
    required List<PlayerProfile> players,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: players
          .map(
            (player) => DropdownMenuItem(
              value: player.id,
              child: Text(player.fullName),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _setRow(
    String label,
    TextEditingController sideAController,
    TextEditingController sideBController,
  ) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: TextField(
            controller: sideAController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Side A'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: sideBController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Side B'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _playedAt,
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _playedAt = selected;
    });
  }

  void _submit() {
    final sideAIds = <String>[];
    final sideBIds = <String>[];

    if (_sideA1 == null || _sideB1 == null) {
      _showSnackBar(
        context,
        'Please choose at least one player for each side.',
      );
      return;
    }

    sideAIds.add(_sideA1!);
    sideBIds.add(_sideB1!);

    if (_format == MatchFormat.doubles) {
      if (_sideA2 == null || _sideB2 == null) {
        _showSnackBar(
          context,
          'Please choose doubles partners for both sides.',
        );
        return;
      }
      sideAIds.add(_sideA2!);
      sideBIds.add(_sideB2!);
    }

    final parsedSets = <MatchSet>[];

    final requiredSet1 = _parseSet(
      _set1AController.text,
      _set1BController.text,
    );
    final requiredSet2 = _parseSet(
      _set2AController.text,
      _set2BController.text,
    );
    if (requiredSet1 == null || requiredSet2 == null) {
      _showSnackBar(
        context,
        'Set 1 and Set 2 scores are required and must be numbers.',
      );
      return;
    }
    parsedSets.add(requiredSet1);
    parsedSets.add(requiredSet2);

    final hasAnyThirdScore =
        _set3AController.text.trim().isNotEmpty ||
        _set3BController.text.trim().isNotEmpty;
    if (hasAnyThirdScore) {
      final thirdSet = _parseSet(_set3AController.text, _set3BController.text);
      if (thirdSet == null) {
        _showSnackBar(
          context,
          'Set 3 score is incomplete. Provide both values or leave blank.',
        );
        return;
      }
      parsedSets.add(thirdSet);
    }

    final error = widget.store.uploadMatch(
      format: _format,
      sideAPlayerIds: sideAIds,
      sideBPlayerIds: sideBIds,
      sets: parsedSets,
      playedAt: _playedAt,
      eventName: _eventController.text,
    );

    if (error != null) {
      _showSnackBar(context, error);
      return;
    }

    _showSnackBar(context, 'Match uploaded successfully.');
    _eventController.clear();
    _set1AController.clear();
    _set1BController.clear();
    _set2AController.clear();
    _set2BController.clear();
    _set3AController.clear();
    _set3BController.clear();
    setState(() {
      _playedAt = DateTime.now();
    });
  }

  MatchSet? _parseSet(String sideA, String sideB) {
    final a = int.tryParse(sideA.trim());
    final b = int.tryParse(sideB.trim());
    if (a == null || b == null) {
      return null;
    }
    return MatchSet(sideA: a, sideB: b);
  }
}

class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key, required this.store});

  final AirShuttleStore store;

  @override
  Widget build(BuildContext context) {
    final teams = store.teams;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        final roster = store.rosterForTeam(team.id);
        final averageRating = store.teamAverageRating(team.id);
        final approvedMatches = store
            .matchesForTeam(team.id)
            .where((match) => match.status == MatchStatus.approved)
            .length;

        return Card(
          child: ExpansionTile(
            title: Text(team.name),
            subtitle: Text('${team.school} • ${team.city}'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Row(
                children: [
                  Expanded(child: Text('Roster: ${roster.length} players')),
                  Expanded(
                    child: Text('Avg AR: ${averageRating.toStringAsFixed(2)}'),
                  ),
                  Expanded(child: Text('Matches: $approvedMatches')),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: roster
                    .map(
                      (player) => ActionChip(
                        label: Text(
                          '${player.fullName} • ${player.rating.toStringAsFixed(2)}',
                        ),
                        onPressed: () =>
                            _openPlayerProfile(context, store, player),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key, required this.store});

  final AirShuttleStore store;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim().toLowerCase();

    final filtered = widget.store.players.where((player) {
      if (query.isEmpty) {
        return true;
      }
      final teamName = widget.store.teamById(player.teamId)?.name ?? '';
      return player.fullName.toLowerCase().contains(query) ||
          player.school.toLowerCase().contains(query) ||
          teamName.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _queryController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Search players, schools, teams',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final player = filtered[index];
              final team = widget.store.teamById(player.teamId);
              return Card(
                child: ListTile(
                  leading: PlayerAvatar(player: player),
                  title: Text(player.fullName),
                  subtitle: Text(
                    '${team?.name ?? 'No team'} • ${player.school}',
                  ),
                  trailing: Text('${player.rating.toStringAsFixed(2)} AR'),
                  onTap: () =>
                      _openPlayerProfile(context, widget.store, player),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PlayerProfileDetailPage extends StatelessWidget {
  const PlayerProfileDetailPage({
    super.key,
    required this.store,
    required this.player,
  });

  final AirShuttleStore store;
  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    final team = store.teamById(player.teamId);
    final approvedMatches = store.matchesForPlayer(
      player.id,
      includePending: false,
    );
    final summary = _buildFormatSummary(player.id, approvedMatches);
    final yearlyPerformance = _buildYearlyPerformance(
      player.id,
      approvedMatches,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const _AirshuttleHomeTitle(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/'),
            child: Text(store.isAuthenticated ? 'Dashboard' : 'Home'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PlayerBanner(player: player),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PlayerAvatar(player: player, radius: 34),
                  Text(
                    player.fullName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      Text('Rank #${store.rankOfPlayer(player.id)}'),
                      Text('${player.rating.toStringAsFixed(2)} AR'),
                      Text(
                        '${player.wins}-${player.losses} (${(player.winRate * 100).toStringAsFixed(1)}% overall)',
                      ),
                      Text('${player.reliability}% reliability'),
                      Text(team?.name ?? 'No team'),
                      Text(player.school),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specialization',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.specializationLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _SpecializationGraph(summary: summary),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Singles: ${summary.singlesWins}-${summary.singlesLosses} (${(summary.singlesWinRate * 100).toStringAsFixed(1)}%)',
                      ),
                      Text(
                        'Doubles: ${summary.doublesWins}-${summary.doublesLosses} (${(summary.doublesWinRate * 100).toStringAsFixed(1)}%)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Specialization is based on approved match win percentages and match volume.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progression',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Yearly improvement based on match outcomes. Hover points for annual breakdown.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  _ProgressionGraph(yearlyPerformance: yearlyPerformance),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Past Matches',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (approvedMatches.isEmpty)
                    const Text('No approved matches yet.')
                  else
                    ...approvedMatches.map(
                      (match) => MatchTile(store: store, match: match),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.store});

  final AirShuttleStore store;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  String? _activeUserId;
  String _avatarEmoji = AirShuttleStore.avatarEmojis.first;
  int _avatarColor = AirShuttleStore.avatarPaletteValues.first;

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.store.currentUser;
    if (user == null) {
      return const Center(child: Text('Not signed in.'));
    }

    _syncFromUser(user);
    final team = widget.store.teamById(user.teamId);
    final matchHistory = widget.store.matchesForPlayer(user.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                PlayerBanner(player: user, height: 110),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Color(_avatarColor),
                      backgroundImage: _avatarUrlController.text.trim().isEmpty
                          ? null
                          : NetworkImage(_avatarUrlController.text.trim()),
                      child: _avatarUrlController.text.trim().isNotEmpty
                          ? null
                          : Text(
                              _avatarEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rank #${widget.store.rankOfPlayer(user.id)}'),
                          Text('${user.rating.toStringAsFixed(2)} AR'),
                          Text('${user.wins}-${user.losses} record'),
                          Text('${user.reliability}% reliability'),
                          Text(team?.name ?? 'No team'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _schoolController,
                  decoration: const InputDecoration(labelText: 'School'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _avatarUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Profile image URL (optional)',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _avatarEmoji,
                  items: AirShuttleStore.avatarEmojis
                      .map(
                        (emoji) =>
                            DropdownMenuItem(value: emoji, child: Text(emoji)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _avatarEmoji = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Avatar icon'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: _avatarColor,
                  items: AirShuttleStore.avatarPaletteValues
                      .map(
                        (color) => DropdownMenuItem(
                          value: color,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: Color(color),
                              ),
                              const SizedBox(width: 8),
                              Text('#${color.toRadixString(16).toUpperCase()}'),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _avatarColor = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Avatar color'),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    widget.store.updateCurrentProfile(
                      fullName: _nameController.text,
                      school: _schoolController.text,
                      avatarEmoji: _avatarEmoji,
                      avatarColorValue: _avatarColor,
                      avatarImageUrl: _avatarUrlController.text,
                      bannerImageUrl: user.bannerImageUrl,
                    );
                    _showSnackBar(context, 'Profile updated.');
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Previous Matches',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (matchHistory.isEmpty)
                  const Text('No match history available yet.')
                else
                  ...matchHistory.map(
                    (match) => MatchTile(store: widget.store, match: match),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _syncFromUser(PlayerProfile user) {
    if (_activeUserId == user.id) {
      return;
    }
    _activeUserId = user.id;
    _nameController.text = user.fullName;
    _schoolController.text = user.school;
    _avatarUrlController.text = user.avatarImageUrl;
    _avatarEmoji = user.avatarEmoji;
    _avatarColor = user.avatarColorValue;
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});

  final AirShuttleStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _avatarUrlController = TextEditingController();
  final _bannerUrlController = TextEditingController();

  String? _activeUserId;
  ThemeMode _selectedThemeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.store.themeMode;
  }

  @override
  void dispose() {
    _avatarUrlController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.store.currentUser;
    if (user == null) {
      return const Center(child: Text('Not signed in.'));
    }

    _syncFromUser(user);

    final avatarUrl = _avatarUrlController.text.trim();
    final bannerUrl = _bannerUrlController.text.trim();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Change your photo, banner, theme, or sign out.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Picture',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(user.avatarColorValue),
                  backgroundImage: avatarUrl.isEmpty
                      ? null
                      : NetworkImage(avatarUrl),
                  child: avatarUrl.isNotEmpty
                      ? null
                      : Text(
                          user.avatarEmoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _avatarUrlController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Profile image URL (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Profile Banner',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      image: bannerUrl.isEmpty
                          ? null
                          : DecorationImage(
                              image: NetworkImage(bannerUrl),
                              fit: BoxFit.cover,
                            ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: bannerUrl.isEmpty
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bannerUrlController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Banner image URL (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                DropdownButtonFormField<ThemeMode>(
                  initialValue: _selectedThemeMode,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light mode'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark mode'),
                    ),
                  ],
                  onChanged: (mode) {
                    if (mode == null) {
                      return;
                    }
                    setState(() {
                      _selectedThemeMode = mode;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Theme mode'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () {
                widget.store.updateCurrentProfile(
                  fullName: user.fullName,
                  school: user.school,
                  avatarEmoji: user.avatarEmoji,
                  avatarColorValue: user.avatarColorValue,
                  avatarImageUrl: _avatarUrlController.text,
                  bannerImageUrl: _bannerUrlController.text,
                );
                widget.store.setThemeMode(_selectedThemeMode);
                _showSnackBar(context, 'Settings saved.');
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
            ),
            OutlinedButton.icon(
              onPressed: widget.store.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ],
    );
  }

  void _syncFromUser(PlayerProfile user) {
    if (_activeUserId == user.id) {
      return;
    }
    _activeUserId = user.id;
    _avatarUrlController.text = user.avatarImageUrl;
    _bannerUrlController.text = user.bannerImageUrl;
    _selectedThemeMode = widget.store.themeMode;
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.store});

  final AirShuttleStore store;

  @override
  Widget build(BuildContext context) {
    final currentUser = store.currentUser;
    if (currentUser == null || !currentUser.isAdmin) {
      return const Center(child: Text('Admin access required.'));
    }

    final pendingMatches = store.matches
        .where((match) => match.status == MatchStatus.pending)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Review Queue',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${pendingMatches.length} pending uploads'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (pendingMatches.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No pending uploads right now.'),
            ),
          )
        else
          ...pendingMatches.map(
            (match) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MatchTile(store: store, match: match),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            final error = store.reviewPendingMatch(
                              matchId: match.id,
                              newStatus: MatchStatus.approved,
                              reviewNote: 'Approved by admin panel.',
                            );
                            final message =
                                error ?? 'Match approved and ratings updated.';
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            final error = store.reviewPendingMatch(
                              matchId: match.id,
                              newStatus: MatchStatus.rejected,
                              reviewNote: 'Rejected by admin panel.',
                            );
                            final message = error ?? 'Match rejected.';
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MatchTile extends StatelessWidget {
  const MatchTile({super.key, required this.store, required this.match});

  final AirShuttleStore store;
  final MatchEntry match;

  @override
  Widget build(BuildContext context) {
    final sideAName = match.sideAPlayerIds
        .map(store.playerDisplayName)
        .join(' & ');
    final sideBName = match.sideBPlayerIds
        .map(store.playerDisplayName)
        .join(' & ');
    final winner = match.sideAWon ? sideAName : sideBName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${match.format.label} • ${_formatDate(match.playedAt)}'),
                Chip(
                  label: Text(match.status.label),
                  backgroundColor: match.status.color.withValues(alpha: 0.12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildMatchup(context),
            Text('Score: ${match.scoreline}'),
            Text('Winner: $winner'),
            Text(
              'Event: ${match.eventName.isEmpty ? 'Unlisted event' : match.eventName}',
            ),
            if (match.reviewNote.isNotEmpty) Text('Note: ${match.reviewNote}'),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchup(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Players:'),
        ..._linkedSide(context, match.sideAPlayerIds),
        const Text('vs'),
        ..._linkedSide(context, match.sideBPlayerIds),
      ],
    );
  }

  List<Widget> _linkedSide(BuildContext context, List<String> playerIds) {
    final widgets = <Widget>[];

    for (var i = 0; i < playerIds.length; i++) {
      final player = store.playerById(playerIds[i]);
      if (player == null) {
        widgets.add(const Text('Unknown'));
      } else {
        widgets.add(
          InkWell(
            onTap: () => _openPlayerProfile(context, store, player),
            child: Text(
              player.fullName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );
      }

      if (i < playerIds.length - 1) {
        widgets.add(const Text('&'));
      }
    }

    return widgets;
  }
}

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.player, this.radius = 20});

  final PlayerProfile player;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = player.avatarImageUrl.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: Color(player.avatarColorValue),
      backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
      child: imageUrl.isNotEmpty
          ? null
          : Text(player.avatarEmoji, style: TextStyle(fontSize: radius * 0.65)),
    );
  }
}

class PlayerBanner extends StatelessWidget {
  const PlayerBanner({super.key, required this.player, this.height = 128});

  final PlayerProfile player;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bannerImageUrl = player.bannerImageUrl.trim();
    final hasImage = bannerImageUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Color(player.avatarColorValue).withAlpha(42),
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(bannerImageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(12),
        child: Text(
          player.fullName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: hasImage
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class PlayerNotFoundPage extends StatelessWidget {
  const PlayerNotFoundPage({
    super.key,
    required this.store,
    required this.missingPlayerId,
  });

  final AirShuttleStore store;
  final String missingPlayerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const _AirshuttleHomeTitle(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/'),
            child: Text(store.isAuthenticated ? 'Dashboard' : 'Home'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Player profile not found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text('No profile exists for id: $missingPlayerId'),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed('/'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _openPlayerProfile(
  BuildContext context,
  AirShuttleStore store,
  PlayerProfile player,
) {
  if (store.playerById(player.id) == null) {
    return;
  }

  Navigator.of(context).pushNamed('/player/${Uri.encodeComponent(player.id)}');
}

class _FormatSummary {
  const _FormatSummary({
    required this.singlesWins,
    required this.singlesTotal,
    required this.doublesWins,
    required this.doublesTotal,
  });

  final int singlesWins;
  final int singlesTotal;
  final int doublesWins;
  final int doublesTotal;

  int get singlesLosses => singlesTotal - singlesWins;
  int get doublesLosses => doublesTotal - doublesWins;

  double get singlesWinRate =>
      singlesTotal == 0 ? 0 : singlesWins / singlesTotal;
  double get doublesWinRate =>
      doublesTotal == 0 ? 0 : doublesWins / doublesTotal;

  String get specializationLabel {
    if (singlesTotal == 0 && doublesTotal == 0) {
      return 'Developing • Need more match data';
    }
    if (singlesTotal == 0) {
      return 'Doubles Specialist';
    }
    if (doublesTotal == 0) {
      return 'Singles Specialist';
    }

    final difference = (singlesWinRate - doublesWinRate).abs();
    if (difference <= 0.06) {
      return 'Balanced • Strong in both singles and doubles';
    }

    return singlesWinRate > doublesWinRate
        ? 'Singles Specialist'
        : 'Doubles Specialist';
  }
}

class _SpecializationGraph extends StatelessWidget {
  const _SpecializationGraph({required this.summary});

  final _FormatSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final singlesStrength = _strength(
      summary.singlesWinRate,
      summary.singlesTotal,
    );
    final doublesStrength = _strength(
      summary.doublesWinRate,
      summary.doublesTotal,
    );

    return Wrap(
      spacing: 20,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: CustomPaint(
            painter: _SpecializationGraphPainter(
              singlesStrength: singlesStrength,
              doublesStrength: doublesStrength,
              singlesColor: colorScheme.primary,
              doublesColor: colorScheme.tertiary,
              trackColor: colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  summary.specializationLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legend(
                context,
                color: colorScheme.primary,
                title: 'Singles Skill Ring',
                subtitle:
                    '${summary.singlesTotal} matches • ${(summary.singlesWinRate * 100).toStringAsFixed(1)}% win',
              ),
              const SizedBox(height: 10),
              _legend(
                context,
                color: colorScheme.tertiary,
                title: 'Doubles Skill Ring',
                subtitle:
                    '${summary.doublesTotal} matches • ${(summary.doublesWinRate * 100).toStringAsFixed(1)}% win',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(
    BuildContext context, {
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }

  double _strength(double winRate, int totalMatches) {
    if (totalMatches == 0) {
      return 0;
    }

    final volumeWeight = (math.log(totalMatches + 1) / math.log(20))
        .clamp(0.35, 1.0)
        .toDouble();
    return (winRate * volumeWeight).clamp(0, 1).toDouble();
  }
}

class _SpecializationGraphPainter extends CustomPainter {
  const _SpecializationGraphPainter({
    required this.singlesStrength,
    required this.doublesStrength,
    required this.singlesColor,
    required this.doublesColor,
    required this.trackColor,
  });

  final double singlesStrength;
  final double doublesStrength;
  final Color singlesColor;
  final Color doublesColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 12;
    final innerRadius = outerRadius - 34;
    const start = -math.pi / 2;

    final outerTrack = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final innerTrack = Paint()
      ..color = trackColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final singlesPaint = Paint()
      ..color = singlesColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final doublesPaint = Paint()
      ..color = doublesColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      start,
      2 * math.pi,
      false,
      outerTrack,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      start,
      2 * math.pi,
      false,
      innerTrack,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      start,
      2 * math.pi * singlesStrength,
      false,
      singlesPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      start,
      2 * math.pi * doublesStrength,
      false,
      doublesPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpecializationGraphPainter oldDelegate) {
    return singlesStrength != oldDelegate.singlesStrength ||
        doublesStrength != oldDelegate.doublesStrength ||
        singlesColor != oldDelegate.singlesColor ||
        doublesColor != oldDelegate.doublesColor ||
        trackColor != oldDelegate.trackColor;
  }
}

class _YearlyPerformance {
  const _YearlyPerformance({
    required this.year,
    required this.singlesWins,
    required this.singlesLosses,
    required this.doublesWins,
    required this.doublesLosses,
    required this.improvementScore,
  });

  final int year;
  final int singlesWins;
  final int singlesLosses;
  final int doublesWins;
  final int doublesLosses;
  final double improvementScore;

  int get totalWins => singlesWins + doublesWins;
  int get totalLosses => singlesLosses + doublesLosses;
  int get totalMatches => totalWins + totalLosses;

  double get winRate => totalMatches == 0 ? 0 : totalWins / totalMatches;

  String get hoverLabel {
    return '$year\n'
        'Improvement: ${improvementScore.toStringAsFixed(1)}\n'
        'Win rate: ${(winRate * 100).toStringAsFixed(1)}%\n'
        'Singles: $singlesWins-$singlesLosses\n'
        'Doubles: $doublesWins-$doublesLosses';
  }
}

class _YearlyAccumulator {
  int singlesWins = 0;
  int singlesLosses = 0;
  int doublesWins = 0;
  int doublesLosses = 0;

  int get totalWins => singlesWins + doublesWins;
  int get totalLosses => singlesLosses + doublesLosses;
  int get totalMatches => totalWins + totalLosses;
  double get winRate => totalMatches == 0 ? 0 : totalWins / totalMatches;
}

List<_YearlyPerformance> _buildYearlyPerformance(
  String playerId,
  List<MatchEntry> matches,
) {
  final byYear = <int, _YearlyAccumulator>{};

  for (final match in matches) {
    final year = match.playedAt.year;
    final won = _didPlayerWinMatch(match, playerId);
    final bucket = byYear.putIfAbsent(year, _YearlyAccumulator.new);

    if (match.format == MatchFormat.singles) {
      if (won) {
        bucket.singlesWins += 1;
      } else {
        bucket.singlesLosses += 1;
      }
    } else {
      if (won) {
        bucket.doublesWins += 1;
      } else {
        bucket.doublesLosses += 1;
      }
    }
  }

  final years = byYear.keys.toList()..sort();
  if (years.isEmpty) {
    return const [];
  }

  final baselineWinRate = byYear[years.first]!.winRate;
  return years
      .map((year) {
        final bucket = byYear[year]!;
        return _YearlyPerformance(
          year: year,
          singlesWins: bucket.singlesWins,
          singlesLosses: bucket.singlesLosses,
          doublesWins: bucket.doublesWins,
          doublesLosses: bucket.doublesLosses,
          improvementScore: (bucket.winRate - baselineWinRate) * 100,
        );
      })
      .toList(growable: false);
}

class _ProgressionGraph extends StatelessWidget {
  const _ProgressionGraph({required this.yearlyPerformance});

  final List<_YearlyPerformance> yearlyPerformance;

  @override
  Widget build(BuildContext context) {
    if (yearlyPerformance.isEmpty) {
      return const Text('No yearly match data available yet.');
    }

    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 720.0;
        const height = 300.0;
        final layout = _buildProgressionLayout(
          yearlyPerformance,
          math.max(width, 360),
          height,
        );

        return SizedBox(
          width: layout.width,
          height: layout.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(layout.width, layout.height),
                painter: _ProgressionGraphPainter(
                  layout: layout,
                  lineColor: colorScheme.primary,
                  fillColor: colorScheme.primary.withValues(alpha: 0.14),
                  gridColor: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  zeroColor: colorScheme.secondary.withValues(alpha: 0.6),
                ),
              ),
              Positioned(
                left: 0,
                top: layout.plotTop + 8,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Improvement',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: layout.plotTop - 8,
                child: Text(
                  layout.maxValue.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Positioned(
                left: 10,
                top: layout.plotBottom - 8,
                child: Text(
                  layout.minValue.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              for (final point in layout.points)
                Positioned(
                  left: point.x - 10,
                  top: point.y - 10,
                  child: Tooltip(
                    message: point.performance.hoverLabel,
                    waitDuration: const Duration(milliseconds: 180),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              for (final point in layout.points)
                Positioned(
                  left: point.x - 24,
                  top: layout.plotBottom + 8,
                  child: SizedBox(
                    width: 48,
                    child: Text(
                      '${point.performance.year}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _YearGraphPoint {
  const _YearGraphPoint({
    required this.performance,
    required this.x,
    required this.y,
  });

  final _YearlyPerformance performance;
  final double x;
  final double y;
}

class _ProgressionLayout {
  const _ProgressionLayout({
    required this.width,
    required this.height,
    required this.plotLeft,
    required this.plotTop,
    required this.plotRight,
    required this.plotBottom,
    required this.minValue,
    required this.maxValue,
    required this.points,
  });

  final double width;
  final double height;
  final double plotLeft;
  final double plotTop;
  final double plotRight;
  final double plotBottom;
  final double minValue;
  final double maxValue;
  final List<_YearGraphPoint> points;
}

_ProgressionLayout _buildProgressionLayout(
  List<_YearlyPerformance> yearlyPerformance,
  double width,
  double height,
) {
  const plotLeft = 66.0;
  const plotRightPad = 20.0;
  const plotTop = 20.0;
  const plotBottomPad = 46.0;

  final rawMin = yearlyPerformance
      .map((entry) => entry.improvementScore)
      .reduce(math.min);
  final rawMax = yearlyPerformance
      .map((entry) => entry.improvementScore)
      .reduce(math.max);

  var minValue = rawMin;
  var maxValue = rawMax;
  if ((maxValue - minValue).abs() < 1.0) {
    minValue -= 5;
    maxValue += 5;
  }

  final plotRight = width - plotRightPad;
  final plotBottom = height - plotBottomPad;
  final plotWidth = math.max(1.0, plotRight - plotLeft);
  final plotHeight = math.max(1.0, plotBottom - plotTop);

  final points = <_YearGraphPoint>[];
  for (var i = 0; i < yearlyPerformance.length; i++) {
    final performance = yearlyPerformance[i];
    final t = yearlyPerformance.length == 1
        ? 0.5
        : i / (yearlyPerformance.length - 1);
    final x = plotLeft + (plotWidth * t);
    final y =
        plotTop +
        ((maxValue - performance.improvementScore) / (maxValue - minValue)) *
            plotHeight;

    points.add(_YearGraphPoint(performance: performance, x: x, y: y));
  }

  return _ProgressionLayout(
    width: width,
    height: height,
    plotLeft: plotLeft,
    plotTop: plotTop,
    plotRight: plotRight,
    plotBottom: plotBottom,
    minValue: minValue,
    maxValue: maxValue,
    points: points,
  );
}

class _ProgressionGraphPainter extends CustomPainter {
  const _ProgressionGraphPainter({
    required this.layout,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.zeroColor,
  });

  final _ProgressionLayout layout;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color zeroColor;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(layout.plotLeft, layout.plotTop),
      Offset(layout.plotLeft, layout.plotBottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(layout.plotLeft, layout.plotBottom),
      Offset(layout.plotRight, layout.plotBottom),
      axisPaint,
    );

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 1; i <= 4; i++) {
      final y = layout.plotTop + ((layout.plotBottom - layout.plotTop) * i / 4);
      canvas.drawLine(
        Offset(layout.plotLeft, y),
        Offset(layout.plotRight, y),
        gridPaint,
      );
    }

    if (layout.minValue < 0 && layout.maxValue > 0) {
      final zeroY =
          layout.plotTop +
          (layout.maxValue / (layout.maxValue - layout.minValue)) *
              (layout.plotBottom - layout.plotTop);
      final zeroPaint = Paint()
        ..color = zeroColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      canvas.drawLine(
        Offset(layout.plotLeft, zeroY),
        Offset(layout.plotRight, zeroY),
        zeroPaint,
      );
    }

    if (layout.points.isEmpty) {
      return;
    }

    final path = Path()..moveTo(layout.points.first.x, layout.points.first.y);
    for (var i = 1; i < layout.points.length; i++) {
      path.lineTo(layout.points[i].x, layout.points[i].y);
    }

    if (layout.points.length > 1) {
      final areaPath = Path.from(path)
        ..lineTo(layout.points.last.x, layout.plotBottom)
        ..lineTo(layout.points.first.x, layout.plotBottom)
        ..close();
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressionGraphPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.zeroColor != zeroColor;
  }
}

_FormatSummary _buildFormatSummary(String playerId, List<MatchEntry> matches) {
  var singlesWins = 0;
  var singlesTotal = 0;
  var doublesWins = 0;
  var doublesTotal = 0;

  for (final match in matches) {
    final playerWon = _didPlayerWinMatch(match, playerId);

    if (match.format == MatchFormat.singles) {
      singlesTotal += 1;
      if (playerWon) {
        singlesWins += 1;
      }
    } else {
      doublesTotal += 1;
      if (playerWon) {
        doublesWins += 1;
      }
    }
  }

  return _FormatSummary(
    singlesWins: singlesWins,
    singlesTotal: singlesTotal,
    doublesWins: doublesWins,
    doublesTotal: doublesTotal,
  );
}

bool _didPlayerWinMatch(MatchEntry match, String playerId) {
  final onSideA = match.sideAPlayerIds.contains(playerId);
  final onSideB = match.sideBPlayerIds.contains(playerId);
  if (!onSideA && !onSideB) {
    return false;
  }
  return onSideA ? match.sideAWon : !match.sideAWon;
}

String _formatDate(DateTime value) {
  final date = value.toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
