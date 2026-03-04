import 'package:flutter/material.dart';

enum UserRole { player, coach, admin }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.player:
        return 'Player';
      case UserRole.coach:
        return 'Coach';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

enum MatchStatus { pending, approved, rejected }

extension MatchStatusLabel on MatchStatus {
  String get label {
    switch (this) {
      case MatchStatus.pending:
        return 'Pending';
      case MatchStatus.approved:
        return 'Approved';
      case MatchStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case MatchStatus.pending:
        return Colors.orange;
      case MatchStatus.approved:
        return Colors.green;
      case MatchStatus.rejected:
        return Colors.red;
    }
  }
}

enum MatchFormat { singles, doubles }

extension MatchFormatLabel on MatchFormat {
  String get label {
    switch (this) {
      case MatchFormat.singles:
        return 'Singles';
      case MatchFormat.doubles:
        return 'Doubles';
    }
  }
}

class Team {
  Team({
    required this.id,
    required this.name,
    required this.school,
    required this.city,
    required this.createdAt,
  });

  final String id;
  String name;
  String school;
  String city;
  final DateTime createdAt;
}

class PlayerProfile {
  PlayerProfile({
    required this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.school,
    required this.teamId,
    required this.role,
    required this.avatarEmoji,
    required this.avatarColorValue,
    required this.avatarImageUrl,
    required this.bannerImageUrl,
    required this.rating,
    required this.reliability,
    required this.wins,
    required this.losses,
    required this.createdAt,
  });

  final String id;
  final String email;
  String password;
  String fullName;
  String school;
  String teamId;
  UserRole role;
  String avatarEmoji;
  int avatarColorValue;
  String avatarImageUrl;
  String bannerImageUrl;
  double rating;
  int reliability;
  int wins;
  int losses;
  final DateTime createdAt;

  bool get isAdmin => role == UserRole.admin;
  int get totalMatches => wins + losses;
  double get winRate => totalMatches == 0 ? 0 : wins / totalMatches;
}

class MatchSet {
  MatchSet({required this.sideA, required this.sideB});

  final int sideA;
  final int sideB;

  bool get sideAWon => sideA > sideB;
}

class MatchEntry {
  MatchEntry({
    required this.id,
    required this.format,
    required this.sideAPlayerIds,
    required this.sideBPlayerIds,
    required this.sets,
    required this.eventName,
    required this.playedAt,
    required this.uploadedByUserId,
    required this.uploadedAt,
    required this.status,
    required this.reviewNote,
  });

  final String id;
  MatchFormat format;
  List<String> sideAPlayerIds;
  List<String> sideBPlayerIds;
  List<MatchSet> sets;
  String eventName;
  DateTime playedAt;
  String uploadedByUserId;
  DateTime uploadedAt;
  MatchStatus status;
  String reviewNote;

  int get sideASetsWon => sets.where((set) => set.sideAWon).length;
  int get sideBSetsWon => sets.length - sideASetsWon;
  bool get sideAWon => sideASetsWon > sideBSetsWon;

  String get scoreline {
    return sets.map((set) => '${set.sideA}-${set.sideB}').join(', ');
  }
}
