import 'package:flutter/material.dart' show ChangeNotifier, ThemeMode;

import 'models.dart';
import 'ranking_engine.dart';

class AirShuttleStore extends ChangeNotifier {
  AirShuttleStore() {
    _seedData();
  }

  static const List<int> avatarPaletteValues = [
    0xFF1565C0,
    0xFF2E7D32,
    0xFF6A1B9A,
    0xFFEF6C00,
    0xFF37474F,
    0xFF00838F,
  ];

  static const List<String> avatarEmojis = ['🏸', '🔥', '⚡', '🎯', '🦅', '🌟'];

  final List<Team> _teams = [];
  final List<PlayerProfile> _players = [];
  final List<MatchEntry> _matches = [];

  String? _currentUserId;
  int _idCounter = 0;
  ThemeMode _themeMode = ThemeMode.light;

  List<Team> get teams => List.unmodifiable(_teams);

  List<PlayerProfile> get players {
    final sorted = List<PlayerProfile>.from(_players);
    sorted.sort((a, b) {
      final ratingComparison = b.rating.compareTo(a.rating);
      if (ratingComparison != 0) {
        return ratingComparison;
      }
      return b.reliability.compareTo(a.reliability);
    });
    return sorted;
  }

  List<MatchEntry> get matches {
    final sorted = List<MatchEntry>.from(_matches);
    sorted.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return sorted;
  }

  bool get isAuthenticated => _currentUserId != null;
  ThemeMode get themeMode => _themeMode;

  PlayerProfile? get currentUser {
    if (_currentUserId == null) {
      return null;
    }
    return playerById(_currentUserId!);
  }

  PlayerProfile? playerById(String id) {
    for (final player in _players) {
      if (player.id == id) {
        return player;
      }
    }
    return null;
  }

  Team? teamById(String id) {
    for (final team in _teams) {
      if (team.id == id) {
        return team;
      }
    }
    return null;
  }

  List<PlayerProfile> rankedPlayers({String? school, String? teamId}) {
    return players
        .where((player) {
          final bySchool = school == null || player.school == school;
          final byTeam = teamId == null || player.teamId == teamId;
          return bySchool && byTeam;
        })
        .toList(growable: false);
  }

  int rankOfPlayer(String playerId) {
    final ordered = players;
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].id == playerId) {
        return i + 1;
      }
    }
    return ordered.length;
  }

  String playerDisplayName(String playerId) {
    final player = playerById(playerId);
    if (player == null) {
      return 'Unknown';
    }
    return player.fullName;
  }

  List<PlayerProfile> rosterForTeam(String teamId) {
    final roster = _players.where((player) => player.teamId == teamId).toList();
    roster.sort((a, b) => b.rating.compareTo(a.rating));
    return roster;
  }

  List<MatchEntry> matchesForPlayer(
    String playerId, {
    bool includePending = true,
  }) {
    final filtered = _matches.where((match) {
      if (!includePending && match.status != MatchStatus.approved) {
        return false;
      }
      return match.sideAPlayerIds.contains(playerId) ||
          match.sideBPlayerIds.contains(playerId);
    }).toList();
    filtered.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return filtered;
  }

  List<MatchEntry> matchesForTeam(String teamId) {
    final teamPlayers = rosterForTeam(
      teamId,
    ).map((player) => player.id).toSet();
    final filtered = _matches.where((match) {
      final allPlayers = [...match.sideAPlayerIds, ...match.sideBPlayerIds];
      return allPlayers.any(teamPlayers.contains);
    }).toList();
    filtered.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return filtered;
  }

  double teamAverageRating(String teamId) {
    final roster = rosterForTeam(teamId);
    if (roster.isEmpty) {
      return 0;
    }
    final total = roster.fold<double>(
      0,
      (running, player) => running + player.rating,
    );
    return total / roster.length;
  }

  double playerStrengthIndex(PlayerProfile player) {
    final reliabilityFactor = player.reliability / 100;
    return player.rating * (0.6 + (0.4 * reliabilityFactor));
  }

  double winProbability(String playerAId, String playerBId) {
    final playerA = playerById(playerAId);
    final playerB = playerById(playerBId);
    if (playerA == null || playerB == null) {
      return 0.5;
    }
    return RankingEngine.expectedOutcome(playerA.rating, playerB.rating);
  }

  String? login({required String email, required String password}) {
    final normalizedEmail = email.trim().toLowerCase();

    PlayerProfile? matched;
    for (final player in _players) {
      if (player.email.toLowerCase() == normalizedEmail) {
        matched = player;
        break;
      }
    }

    if (matched == null || matched.password != password) {
      return 'Invalid email or password.';
    }

    _currentUserId = matched.id;
    notifyListeners();
    return null;
  }

  void logout() {
    _currentUserId = null;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
  }

  String? register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    required String school,
    String? existingTeamId,
    String? newTeamName,
    String? newTeamSchool,
    String? newTeamCity,
    required String avatarEmoji,
    required int avatarColorValue,
    String avatarImageUrl = '',
  }) {
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();
    final trimmedSchool = school.trim();

    if (trimmedName.isEmpty ||
        trimmedEmail.isEmpty ||
        trimmedPassword.isEmpty ||
        trimmedSchool.isEmpty) {
      return 'Please complete all required account fields.';
    }

    for (final player in _players) {
      if (player.email.toLowerCase() == trimmedEmail) {
        return 'An account with that email already exists.';
      }
    }

    var teamId = existingTeamId?.trim() ?? '';
    if (teamId.isEmpty) {
      final createdTeamName = (newTeamName ?? '').trim();
      final createdTeamSchool = (newTeamSchool ?? '').trim();
      final createdTeamCity = (newTeamCity ?? '').trim();

      if (createdTeamName.isEmpty ||
          createdTeamSchool.isEmpty ||
          createdTeamCity.isEmpty) {
        return 'To create a new team, fill in team name, school, and city.';
      }

      final newTeam = Team(
        id: _nextId('team'),
        name: createdTeamName,
        school: createdTeamSchool,
        city: createdTeamCity,
        createdAt: DateTime.now(),
      );
      _teams.add(newTeam);
      teamId = newTeam.id;
    }

    final account = PlayerProfile(
      id: _nextId('player'),
      email: trimmedEmail,
      password: trimmedPassword,
      fullName: trimmedName,
      school: trimmedSchool,
      teamId: teamId,
      role: role,
      avatarEmoji: avatarEmoji,
      avatarColorValue: avatarColorValue,
      avatarImageUrl: avatarImageUrl.trim(),
      bannerImageUrl: '',
      rating: 6.0,
      reliability: 35,
      wins: 0,
      losses: 0,
      createdAt: DateTime.now(),
    );

    _players.add(account);
    _currentUserId = account.id;
    notifyListeners();
    return null;
  }

  void updateCurrentProfile({
    required String fullName,
    required String school,
    required String avatarEmoji,
    required int avatarColorValue,
    required String avatarImageUrl,
    required String bannerImageUrl,
  }) {
    final user = currentUser;
    if (user == null) {
      return;
    }

    user.fullName = fullName.trim().isEmpty ? user.fullName : fullName.trim();
    user.school = school.trim().isEmpty ? user.school : school.trim();
    user.avatarEmoji = avatarEmoji;
    user.avatarColorValue = avatarColorValue;
    user.avatarImageUrl = avatarImageUrl.trim();
    user.bannerImageUrl = bannerImageUrl.trim();
    notifyListeners();
  }

  String? uploadMatch({
    required MatchFormat format,
    required List<String> sideAPlayerIds,
    required List<String> sideBPlayerIds,
    required List<MatchSet> sets,
    required DateTime playedAt,
    required String eventName,
  }) {
    final uploader = currentUser;
    if (uploader == null) {
      return 'Please log in to upload a match.';
    }

    final requiredPlayersPerSide = format == MatchFormat.singles ? 1 : 2;
    if (sideAPlayerIds.length != requiredPlayersPerSide ||
        sideBPlayerIds.length != requiredPlayersPerSide) {
      return 'Invalid participant count for ${format.label.toLowerCase()}.';
    }

    final allPlayers = [...sideAPlayerIds, ...sideBPlayerIds];
    final uniquePlayers = allPlayers.toSet();
    if (uniquePlayers.length != allPlayers.length) {
      return 'A player cannot appear on both sides of the same match.';
    }

    for (final playerId in allPlayers) {
      if (playerById(playerId) == null) {
        return 'One or more selected players no longer exist.';
      }
    }

    if (sets.length < 2 || sets.length > 3) {
      return 'Provide 2 or 3 sets for each match result.';
    }

    for (final set in sets) {
      if (set.sideA == set.sideB) {
        return 'Badminton sets cannot end in a tie.';
      }
    }

    final match = MatchEntry(
      id: _nextId('match'),
      format: format,
      sideAPlayerIds: sideAPlayerIds,
      sideBPlayerIds: sideBPlayerIds,
      sets: sets,
      eventName: eventName.trim(),
      playedAt: playedAt,
      uploadedByUserId: uploader.id,
      uploadedAt: DateTime.now(),
      status: uploader.isAdmin ? MatchStatus.approved : MatchStatus.pending,
      reviewNote: uploader.isAdmin ? 'Auto-approved upload by admin.' : '',
    );

    _matches.add(match);
    if (match.status == MatchStatus.approved) {
      _applyMatchToRatings(match);
    }
    notifyListeners();
    return null;
  }

  String? reviewPendingMatch({
    required String matchId,
    required MatchStatus newStatus,
    String reviewNote = '',
  }) {
    final reviewer = currentUser;
    if (reviewer == null || !reviewer.isAdmin) {
      return 'Only admins can review pending uploads.';
    }

    MatchEntry? match;
    for (final entry in _matches) {
      if (entry.id == matchId) {
        match = entry;
        break;
      }
    }

    if (match == null) {
      return 'Match not found.';
    }
    if (match.status != MatchStatus.pending) {
      return 'Only pending matches can be reviewed.';
    }
    if (newStatus == MatchStatus.pending) {
      return 'Review must be approved or rejected.';
    }

    match.status = newStatus;
    match.reviewNote = reviewNote.trim();

    if (newStatus == MatchStatus.approved) {
      _applyMatchToRatings(match);
    }

    notifyListeners();
    return null;
  }

  void _applyMatchToRatings(MatchEntry match) {
    final sideAPlayers = match.sideAPlayerIds
        .map(playerById)
        .whereType<PlayerProfile>()
        .toList();
    final sideBPlayers = match.sideBPlayerIds
        .map(playerById)
        .whereType<PlayerProfile>()
        .toList();

    if (sideAPlayers.isEmpty || sideBPlayers.isEmpty) {
      return;
    }

    final averageSideA =
        sideAPlayers.fold<double>(
          0,
          (running, player) => running + player.rating,
        ) /
        sideAPlayers.length;

    final averageSideB =
        sideBPlayers.fold<double>(
          0,
          (running, player) => running + player.rating,
        ) /
        sideBPlayers.length;

    final delta = RankingEngine.computeDelta(
      averageSideARating: averageSideA,
      averageSideBRating: averageSideB,
      sideAWon: match.sideAWon,
      sets: match.sets,
      format: match.format,
    );

    final sideAPerPlayer = delta.sideADelta / sideAPlayers.length;
    final sideBPerPlayer = delta.sideBDelta / sideBPlayers.length;

    for (final player in sideAPlayers) {
      player.rating = RankingEngine.clampRating(player.rating + sideAPerPlayer);
      if (match.sideAWon) {
        player.wins += 1;
      } else {
        player.losses += 1;
      }
      player.reliability = RankingEngine.reliabilityFromMatches(
        player.totalMatches,
      );
    }

    for (final player in sideBPlayers) {
      player.rating = RankingEngine.clampRating(player.rating + sideBPerPlayer);
      if (match.sideAWon) {
        player.losses += 1;
      } else {
        player.wins += 1;
      }
      player.reliability = RankingEngine.reliabilityFromMatches(
        player.totalMatches,
      );
    }
  }

  void _seedData() {
    final teamRavens = Team(
      id: 'team-ravens',
      name: 'Riverside Ravens',
      school: 'Riverside High',
      city: 'San Diego',
      createdAt: DateTime(2024, 8, 1),
    );
    final teamFalcons = Team(
      id: 'team-falcons',
      name: 'Eastview Falcons',
      school: 'Eastview Academy',
      city: 'Austin',
      createdAt: DateTime(2024, 8, 2),
    );
    final teamTitans = Team(
      id: 'team-titans',
      name: 'North City Titans',
      school: 'North City Prep',
      city: 'Seattle',
      createdAt: DateTime(2024, 8, 3),
    );

    _teams.addAll([teamRavens, teamFalcons, teamTitans]);

    _players.addAll([
      PlayerProfile(
        id: 'player-admin',
        email: 'admin@airshuttle.app',
        password: 'admin123',
        fullName: 'Alex Rivera',
        school: teamRavens.school,
        teamId: teamRavens.id,
        role: UserRole.admin,
        avatarEmoji: '🏸',
        avatarColorValue: avatarPaletteValues[0],
        avatarImageUrl: '',
        bannerImageUrl: 'https://picsum.photos/seed/alex-banner/1200/280',
        rating: 8.8,
        reliability: 96,
        wins: 74,
        losses: 22,
        createdAt: DateTime(2020, 9, 1),
      ),
      PlayerProfile(
        id: 'player-priya',
        email: 'priya@airshuttle.app',
        password: 'pass123',
        fullName: 'Priya Nair',
        school: teamRavens.school,
        teamId: teamRavens.id,
        role: UserRole.player,
        avatarEmoji: '⚡',
        avatarColorValue: avatarPaletteValues[2],
        avatarImageUrl: '',
        bannerImageUrl: 'https://picsum.photos/seed/priya-banner/1200/280',
        rating: 8.2,
        reliability: 90,
        wins: 52,
        losses: 21,
        createdAt: DateTime(2021, 2, 12),
      ),
      PlayerProfile(
        id: 'player-hannah',
        email: 'hannah@airshuttle.app',
        password: 'pass123',
        fullName: 'Hannah Kim',
        school: teamFalcons.school,
        teamId: teamFalcons.id,
        role: UserRole.player,
        avatarEmoji: '🌟',
        avatarColorValue: avatarPaletteValues[1],
        avatarImageUrl: '',
        bannerImageUrl: 'https://picsum.photos/seed/hannah-banner/1200/280',
        rating: 8.0,
        reliability: 89,
        wins: 49,
        losses: 23,
        createdAt: DateTime(2021, 5, 30),
      ),
      PlayerProfile(
        id: 'player-lucas',
        email: 'lucas@airshuttle.app',
        password: 'pass123',
        fullName: 'Lucas Meyer',
        school: teamFalcons.school,
        teamId: teamFalcons.id,
        role: UserRole.player,
        avatarEmoji: '🔥',
        avatarColorValue: avatarPaletteValues[3],
        avatarImageUrl: '',
        bannerImageUrl: 'https://picsum.photos/seed/lucas-banner/1200/280',
        rating: 7.8,
        reliability: 87,
        wins: 44,
        losses: 26,
        createdAt: DateTime(2021, 6, 22),
      ),
      PlayerProfile(
        id: 'player-noor',
        email: 'noor@airshuttle.app',
        password: 'pass123',
        fullName: 'Noor Patel',
        school: teamTitans.school,
        teamId: teamTitans.id,
        role: UserRole.player,
        avatarEmoji: '🎯',
        avatarColorValue: avatarPaletteValues[4],
        avatarImageUrl: '',
        bannerImageUrl: 'https://picsum.photos/seed/noor-banner/1200/280',
        rating: 8.4,
        reliability: 93,
        wins: 59,
        losses: 19,
        createdAt: DateTime(2020, 11, 9),
      ),
      PlayerProfile(
        id: 'player-diego',
        email: 'diego@airshuttle.app',
        password: 'pass123',
        fullName: 'Diego Santos',
        school: teamTitans.school,
        teamId: teamTitans.id,
        role: UserRole.player,
        avatarEmoji: '🦅',
        avatarColorValue: avatarPaletteValues[5],
        avatarImageUrl: '',
        bannerImageUrl: 'https://picsum.photos/seed/diego-banner/1200/280',
        rating: 7.9,
        reliability: 86,
        wins: 41,
        losses: 27,
        createdAt: DateTime(2021, 3, 10),
      ),
      PlayerProfile(
        id: 'player-olivia',
        email: 'olivia@airshuttle.app',
        password: 'pass123',
        fullName: 'Andre Wang ',
        school: teamRavens.school,
        teamId: teamRavens.id,
        role: UserRole.player,
        avatarEmoji: '🌟',
        avatarColorValue: avatarPaletteValues[0],
        avatarImageUrl: '',
        bannerImageUrl: 'https://picsum.photos/seed/olivia-banner/1200/280',
        rating: 9.0,
        reliability: 97,
        wins: 82,
        losses: 994,
        createdAt: DateTime(2020, 1, 15),
      ),
      PlayerProfile(
        id: 'player-malik',
        email: 'malik@airshuttle.app',
        password: 'pass123',
        fullName: 'Malik Thompson',
        school: teamFalcons.school,
        teamId: teamFalcons.id,
        role: UserRole.player,
        avatarEmoji: '⚡',
        avatarColorValue: avatarPaletteValues[1],
        avatarImageUrl: '',
        bannerImageUrl: 'https://picsum.photos/seed/malik-banner/1200/280',
        rating: 8.7,
        reliability: 95,
        wins: 76,
        losses: 29,
        createdAt: DateTime(2019, 10, 2),
      ),
      PlayerProfile(
        id: 'player-zoe',
        email: 'zoe@airshuttle.app',
        password: 'pass123',
        fullName: 'Zoe Chen',
        school: teamTitans.school,
        teamId: teamTitans.id,
        role: UserRole.player,
        avatarEmoji: '🔥',
        avatarColorValue: avatarPaletteValues[2],
        avatarImageUrl: '',
        bannerImageUrl: 'https://picsum.photos/seed/zoe-banner/1200/280',
        rating: 8.5,
        reliability: 94,
        wins: 68,
        losses: 24,
        createdAt: DateTime(2020, 4, 4),
      ),
      PlayerProfile(
        id: 'player-ryan',
        email: 'ryan@airshuttle.app',
        password: 'pass123',
        fullName: 'Ryan Cole',
        school: teamTitans.school,
        teamId: teamTitans.id,
        role: UserRole.player,
        avatarEmoji: '🎯',
        avatarColorValue: avatarPaletteValues[3],
        avatarImageUrl: '',
        bannerImageUrl: 'https://picsum.photos/seed/ryan-banner/1200/280',
        rating: 8.3,
        reliability: 92,
        wins: 63,
        losses: 25,
        createdAt: DateTime(2021, 1, 19),
      ),
    ]);

    _matches.addAll([
      MatchEntry(
        id: 'match-seed-1',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-olivia'],
        sideBPlayerIds: ['player-malik'],
        sets: [
          MatchSet(sideA: 21, sideB: 18),
          MatchSet(sideA: 17, sideB: 21),
          MatchSet(sideA: 21, sideB: 19),
        ],
        eventName: 'Spring Classic',
        playedAt: DateTime(2021, 3, 14),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2021, 3, 14, 19, 10),
        status: MatchStatus.approved,
        reviewNote: 'Verified by tournament desk.',
      ),
      MatchEntry(
        id: 'match-seed-2',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-noor'],
        sideBPlayerIds: ['player-priya'],
        sets: [MatchSet(sideA: 21, sideB: 16), MatchSet(sideA: 21, sideB: 18)],
        eventName: 'Metro Circuit Stop 2',
        playedAt: DateTime(2021, 5, 2),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2021, 5, 2, 20, 5),
        status: MatchStatus.approved,
        reviewNote: 'Verified by coach upload.',
      ),
      MatchEntry(
        id: 'match-seed-3',
        format: MatchFormat.doubles,
        sideAPlayerIds: ['player-olivia', 'player-priya'],
        sideBPlayerIds: ['player-zoe', 'player-ryan'],
        sets: [
          MatchSet(sideA: 21, sideB: 14),
          MatchSet(sideA: 19, sideB: 21),
          MatchSet(sideA: 21, sideB: 16),
        ],
        eventName: 'National Juniors Finals',
        playedAt: DateTime(2021, 10, 21),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2021, 10, 21, 21, 0),
        status: MatchStatus.approved,
        reviewNote: 'Official score sheet submitted.',
      ),
      MatchEntry(
        id: 'match-seed-4',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-zoe'],
        sideBPlayerIds: ['player-diego'],
        sets: [MatchSet(sideA: 21, sideB: 15), MatchSet(sideA: 21, sideB: 17)],
        eventName: 'Winter Masters',
        playedAt: DateTime(2022, 2, 11),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2022, 2, 11, 18, 40),
        status: MatchStatus.approved,
        reviewNote: 'Regional referee upload.',
      ),
      MatchEntry(
        id: 'match-seed-5',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-malik'],
        sideBPlayerIds: ['player-hannah'],
        sets: [
          MatchSet(sideA: 18, sideB: 21),
          MatchSet(sideA: 21, sideB: 13),
          MatchSet(sideA: 21, sideB: 16),
        ],
        eventName: 'Conference Challenge',
        playedAt: DateTime(2022, 4, 7),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2022, 4, 7, 19, 15),
        status: MatchStatus.approved,
        reviewNote: 'Confirmed by league office.',
      ),
      MatchEntry(
        id: 'match-seed-6',
        format: MatchFormat.doubles,
        sideAPlayerIds: ['player-noor', 'player-diego'],
        sideBPlayerIds: ['player-lucas', 'player-hannah'],
        sets: [MatchSet(sideA: 21, sideB: 19), MatchSet(sideA: 21, sideB: 15)],
        eventName: 'Summer Team Cup',
        playedAt: DateTime(2022, 8, 19),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2022, 8, 19, 20, 30),
        status: MatchStatus.approved,
        reviewNote: 'Verified by coach upload.',
      ),
      MatchEntry(
        id: 'match-seed-7',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-olivia'],
        sideBPlayerIds: ['player-noor'],
        sets: [
          MatchSet(sideA: 21, sideB: 17),
          MatchSet(sideA: 16, sideB: 21),
          MatchSet(sideA: 18, sideB: 21),
        ],
        eventName: 'City Grand Prix',
        playedAt: DateTime(2023, 1, 28),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2023, 1, 28, 17, 50),
        status: MatchStatus.approved,
        reviewNote: 'Official score sheet submitted.',
      ),
      MatchEntry(
        id: 'match-seed-8',
        format: MatchFormat.doubles,
        sideAPlayerIds: ['player-malik', 'player-lucas'],
        sideBPlayerIds: ['player-priya', 'player-ryan'],
        sets: [
          MatchSet(sideA: 21, sideB: 19),
          MatchSet(sideA: 18, sideB: 21),
          MatchSet(sideA: 21, sideB: 17),
        ],
        eventName: 'Spring Team Clash',
        playedAt: DateTime(2023, 3, 16),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2023, 3, 16, 20, 15),
        status: MatchStatus.approved,
        reviewNote: 'Verified by head umpire.',
      ),
      MatchEntry(
        id: 'match-seed-9',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-ryan'],
        sideBPlayerIds: ['player-hannah'],
        sets: [MatchSet(sideA: 22, sideB: 20), MatchSet(sideA: 21, sideB: 18)],
        eventName: 'Summer Ladder Finals',
        playedAt: DateTime(2023, 7, 9),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2023, 7, 9, 18, 5),
        status: MatchStatus.approved,
        reviewNote: 'Competition desk approved.',
      ),
      MatchEntry(
        id: 'match-seed-10',
        format: MatchFormat.doubles,
        sideAPlayerIds: ['player-zoe', 'player-noor'],
        sideBPlayerIds: ['player-olivia', 'player-priya'],
        sets: [
          MatchSet(sideA: 16, sideB: 21),
          MatchSet(sideA: 21, sideB: 17),
          MatchSet(sideA: 21, sideB: 19),
        ],
        eventName: 'Autumn Invitational',
        playedAt: DateTime(2023, 11, 4),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2023, 11, 4, 21, 20),
        status: MatchStatus.approved,
        reviewNote: 'Verified by tournament desk.',
      ),
      MatchEntry(
        id: 'match-seed-11',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-malik'],
        sideBPlayerIds: ['player-diego'],
        sets: [MatchSet(sideA: 21, sideB: 13), MatchSet(sideA: 21, sideB: 14)],
        eventName: 'Winter Open',
        playedAt: DateTime(2024, 2, 13),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2024, 2, 13, 19, 30),
        status: MatchStatus.approved,
        reviewNote: 'Official score sheet submitted.',
      ),
      MatchEntry(
        id: 'match-seed-12',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-olivia'],
        sideBPlayerIds: ['player-zoe'],
        sets: [
          MatchSet(sideA: 19, sideB: 21),
          MatchSet(sideA: 21, sideB: 17),
          MatchSet(sideA: 21, sideB: 15),
        ],
        eventName: 'Northwest Elite',
        playedAt: DateTime(2024, 5, 30),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2024, 5, 30, 20, 0),
        status: MatchStatus.approved,
        reviewNote: 'Verified by league office.',
      ),
      MatchEntry(
        id: 'match-seed-13',
        format: MatchFormat.doubles,
        sideAPlayerIds: ['player-noor', 'player-ryan'],
        sideBPlayerIds: ['player-malik', 'player-hannah'],
        sets: [
          MatchSet(sideA: 17, sideB: 21),
          MatchSet(sideA: 21, sideB: 19),
          MatchSet(sideA: 21, sideB: 18),
        ],
        eventName: 'Regional Team Clash',
        playedAt: DateTime(2024, 9, 14),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2024, 9, 14, 20, 25),
        status: MatchStatus.approved,
        reviewNote: 'Verified by coach upload.',
      ),
      MatchEntry(
        id: 'match-seed-14',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-priya'],
        sideBPlayerIds: ['player-lucas'],
        sets: [MatchSet(sideA: 21, sideB: 12), MatchSet(sideA: 21, sideB: 16)],
        eventName: 'Autumn Open',
        playedAt: DateTime(2024, 11, 8),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2024, 11, 8, 18, 35),
        status: MatchStatus.approved,
        reviewNote: 'Competition desk approved.',
      ),
      MatchEntry(
        id: 'match-seed-15',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-olivia'],
        sideBPlayerIds: ['player-noor'],
        sets: [
          MatchSet(sideA: 21, sideB: 18),
          MatchSet(sideA: 17, sideB: 21),
          MatchSet(sideA: 22, sideB: 20),
        ],
        eventName: 'Pro Series Finals',
        playedAt: DateTime(2025, 1, 26),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2025, 1, 26, 21, 5),
        status: MatchStatus.approved,
        reviewNote: 'Verified by tournament desk.',
      ),
      MatchEntry(
        id: 'match-seed-16',
        format: MatchFormat.doubles,
        sideAPlayerIds: ['player-zoe', 'player-ryan'],
        sideBPlayerIds: ['player-diego', 'player-lucas'],
        sets: [MatchSet(sideA: 21, sideB: 16), MatchSet(sideA: 21, sideB: 19)],
        eventName: 'Spring Invitational',
        playedAt: DateTime(2025, 3, 18),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2025, 3, 18, 19, 40),
        status: MatchStatus.approved,
        reviewNote: 'Official score sheet submitted.',
      ),
      MatchEntry(
        id: 'match-seed-17',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-hannah'],
        sideBPlayerIds: ['player-priya'],
        sets: [
          MatchSet(sideA: 16, sideB: 21),
          MatchSet(sideA: 21, sideB: 18),
          MatchSet(sideA: 21, sideB: 19),
        ],
        eventName: 'City Invitational',
        playedAt: DateTime(2025, 5, 22),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2025, 5, 22, 18, 55),
        status: MatchStatus.approved,
        reviewNote: 'Verified by league office.',
      ),
      MatchEntry(
        id: 'match-seed-18',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-malik'],
        sideBPlayerIds: ['player-zoe'],
        sets: [
          MatchSet(sideA: 21, sideB: 17),
          MatchSet(sideA: 19, sideB: 21),
          MatchSet(sideA: 21, sideB: 16),
        ],
        eventName: 'Summer Grand Prix',
        playedAt: DateTime(2025, 7, 5),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2025, 7, 5, 20, 45),
        status: MatchStatus.approved,
        reviewNote: 'Verified by head umpire.',
      ),
      MatchEntry(
        id: 'match-seed-19',
        format: MatchFormat.doubles,
        sideAPlayerIds: ['player-olivia', 'player-priya'],
        sideBPlayerIds: ['player-noor', 'player-ryan'],
        sets: [
          MatchSet(sideA: 18, sideB: 21),
          MatchSet(sideA: 21, sideB: 19),
          MatchSet(sideA: 17, sideB: 21),
        ],
        eventName: 'National Team Event',
        playedAt: DateTime(2025, 8, 30),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2025, 8, 30, 21, 5),
        status: MatchStatus.approved,
        reviewNote: 'Official score sheet submitted.',
      ),
      MatchEntry(
        id: 'match-seed-20',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-lucas'],
        sideBPlayerIds: ['player-diego'],
        sets: [
          MatchSet(sideA: 21, sideB: 19),
          MatchSet(sideA: 18, sideB: 21),
          MatchSet(sideA: 21, sideB: 19),
        ],
        eventName: 'Practice Ladder',
        playedAt: DateTime(2026, 1, 14),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2026, 1, 14, 18, 10),
        status: MatchStatus.approved,
        reviewNote: 'Internal ranked ladder match.',
      ),
      MatchEntry(
        id: 'match-seed-21',
        format: MatchFormat.doubles,
        sideAPlayerIds: ['player-noor', 'player-zoe'],
        sideBPlayerIds: ['player-malik', 'player-olivia'],
        sets: [
          MatchSet(sideA: 21, sideB: 23),
          MatchSet(sideA: 21, sideB: 18),
          MatchSet(sideA: 19, sideB: 21),
        ],
        eventName: 'Winter Team Showcase',
        playedAt: DateTime(2026, 2, 2),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2026, 2, 2, 20, 20),
        status: MatchStatus.approved,
        reviewNote: 'Verified by tournament desk.',
      ),
      MatchEntry(
        id: 'match-seed-22',
        format: MatchFormat.singles,
        sideAPlayerIds: ['player-priya'],
        sideBPlayerIds: ['player-ryan'],
        sets: [
          MatchSet(sideA: 21, sideB: 15),
          MatchSet(sideA: 19, sideB: 21),
          MatchSet(sideA: 18, sideB: 21),
        ],
        eventName: 'Open Trial Match',
        playedAt: DateTime(2026, 2, 20),
        uploadedByUserId: 'player-admin',
        uploadedAt: DateTime(2026, 2, 20, 19, 30),
        status: MatchStatus.pending,
        reviewNote: '',
      ),
    ]);

    for (final match in _matches) {
      if (match.status == MatchStatus.approved) {
        _applyMatchToRatings(match);
      }
    }
  }

  String _nextId(String prefix) {
    _idCounter += 1;
    return '$prefix-$_idCounter';
  }
}
