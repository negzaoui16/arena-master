/// Backend Specialty enum (must match API)
enum Specialty {
  FRONTEND,
  BACKEND,
  FULLSTACK,
  MOBILE,
  DATA,
  BI,
  CYBERSECURITY,
  DESIGN,
  DEVOPS;

  static Specialty? fromString(String? value) {
    if (value == null) return null;
    final upper = value.toUpperCase();
    for (final e in Specialty.values) {
      if (e.name == upper) return e;
    }
    return null;
  }

  String get displayName {
    switch (this) {
      case Specialty.FRONTEND:
        return 'Frontend';
      case Specialty.BACKEND:
        return 'Backend';
      case Specialty.FULLSTACK:
        return 'Fullstack';
      case Specialty.MOBILE:
        return 'Mobile';
      case Specialty.DATA:
        return 'Data';
      case Specialty.BI:
        return 'BI';
      case Specialty.CYBERSECURITY:
        return 'Cybersecurity';
      case Specialty.DESIGN:
        return 'Design';
      case Specialty.DEVOPS:
        return 'DevOps';
    }
  }
}

/// Competition (hackathon) from API
class Competition {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String? specialty;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double rewardPool;
  final int? maxParticipants;
  final bool isActive;
  final CompetitionCreator? creator;
  final int participantsCount;
  final bool antiCheatEnabled;
  final double? antiCheatThreshold;

  Competition({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    this.specialty,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.rewardPool = 0,
    this.maxParticipants,
    this.isActive = true,
    this.creator,
    this.participantsCount = 0,
    this.antiCheatEnabled = false,
    this.antiCheatThreshold,
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    final startRaw = json['startDate'];
    final endRaw = json['endDate'];
    return Competition(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: (json['difficulty'] as String?) ?? 'MEDIUM',
      specialty: json['specialty'] as String?,
      startDate: startRaw != null ? DateTime.parse(startRaw.toString()) : DateTime.now(),
      endDate: endRaw != null ? DateTime.parse(endRaw.toString()) : DateTime.now(),
      status: (json['status'] as String?) ?? 'SCHEDULED',
      rewardPool: (json['rewardPool'] as num?)?.toDouble() ?? 0,
      maxParticipants: json['maxParticipants'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      creator: json['creator'] != null
          ? CompetitionCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      participantsCount: (json['_count'] as Map<String, dynamic>?)?['participants'] as int? ?? 0,
      antiCheatEnabled: json['antiCheatEnabled'] as bool? ?? false,
      antiCheatThreshold: (json['antiCheatThreshold'] as num?)?.toDouble(),
    );
  }

  String get difficultyDisplay {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return 'Easy';
      case 'HARD':
        return 'Hard';
      default:
        return 'Medium';
    }
  }

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'OPEN_FOR_ENTRY':
        return 'Open for entry';
      case 'SUBMISSION_CLOSED':
        return 'Submission closed';
      default:
        return status.replaceAll('_', ' ').toLowerCase();
    }
  }

  bool get canJoin => status.toUpperCase() == 'OPEN_FOR_ENTRY' || status.toUpperCase() == 'RUNNING';
}

class CompetitionCreator {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;

  CompetitionCreator({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
  });

  factory CompetitionCreator.fromJson(Map<String, dynamic> json) {
    return CompetitionCreator(
      id: json['id'] as String,
      firstName: (json['firstName'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      email: json['email'] as String?,
    );
  }
}

class CompetitionsResponse {
  final List<Competition> data;
  final PaginationInfo pagination;

  CompetitionsResponse({required this.data, required this.pagination});

  factory CompetitionsResponse.fromJson(Map<String, dynamic> json) {
    return CompetitionsResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => Competition.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      hasNext: json['hasNext'] as bool,
      hasPrev: json['hasPrev'] as bool,
    );
  }
}
