enum MaritalStatus { single, married, divorced, widowed }

class Applicant {
  final String id;
  final String name;
  final int age;
  final String location;
  final String businessGoal;
  final double fundingGoal;
  final double currentFunding;
  final String? photo;
  final String? fingerprintPhoto;
  final bool isVerified;
  final bool isApproved;
  final DateTime createdAt;

  // Additional fields required by logic
  final MaritalStatus maritalStatus;
  final int familyMembers;
  final String division;
  final String district;
  final String upazilla;
  final String thana;
  final String currentOccupation;

  Applicant({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.businessGoal,
    required this.fundingGoal,
    this.currentFunding = 0.0,
    this.photo,
    this.fingerprintPhoto,
    this.isVerified = false,
    this.isApproved = false,
    DateTime? createdAt,
    this.maritalStatus = MaritalStatus.single,
    this.familyMembers = 0,
    this.division = '',
    this.district = '',
    this.upazilla = '',
    this.thana = '',
    this.currentOccupation = '',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      // 'id': id,
      'name': name,
      'age': age,
      'location': location,
      'business_goal': businessGoal,
      'funding_goal': fundingGoal,
      'current_funding': currentFunding,
      'photo': photo,
      'fingerprint_photo': fingerprintPhoto,
      'status': isApproved ? 'APPROVED' : (isVerified ? 'PENDING' : 'PENDING'),

      'marital_status': maritalStatus.name,
      'family_members': familyMembers,
      'division': division,
      'district': district,
      'upazilla': upazilla,
      'thana': thana,
      'current_occupation': currentOccupation,
      // created_at is strictly read-only for now in map usually
    };
  }

  factory Applicant.fromMap(Map<String, dynamic> map) {
    return Applicant(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      location: map['location'] ?? '',
      businessGoal: map['business_goal'] ?? '',
      fundingGoal: (map['funding_goal'] ?? 0).toDouble(),
      currentFunding: (map['current_funding'] ?? 0).toDouble(),
      photo: map['photo'],
      fingerprintPhoto: map['fingerprint_photo'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      isVerified: map['status'] != 'PENDING',
      isApproved: map['status'] == 'APPROVED',

      maritalStatus: MaritalStatus.values.firstWhere(
        (e) => e.name == map['marital_status'],
        orElse: () => MaritalStatus.single,
      ),
      familyMembers: map['family_members'] ?? 0,
      division: map['division'] ?? '',
      district: map['district'] ?? '',
      upazilla: map['upazilla'] ?? '',
      thana: map['thana'] ?? '',
      currentOccupation: map['current_occupation'] ?? '',
    );
  }

  double get fundingProgress =>
      fundingGoal > 0 ? (currentFunding / fundingGoal) * 100 : 0;

  // Convenience getters for UI compatibility
  String? get photoUrl => photo;
  String get category => businessGoal;
  double get fullFundingNeeded => fundingGoal;

  String get maritalStatusString {
    switch (maritalStatus) {
      case MaritalStatus.single:
        return 'Single';
      case MaritalStatus.married:
        return 'Married';
      case MaritalStatus.divorced:
        return 'Divorced';
      case MaritalStatus.widowed:
        return 'Widowed';
    }
  }
}
