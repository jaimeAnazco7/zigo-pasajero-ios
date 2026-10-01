class PassengerReferralStatsModel {
  bool? enabled;
  String? referralCode;
  String? shareLink;
  int? referralsNeeded;
  int? completedReferrals;
  int? pendingReferrals;
  int? progressInCycle;
  int? remainingForNextReward;
  num? welcomeBonusAmount;
  num? freeRideMaxDiscount;
  List<PassengerReferralItem>? referrals;
  List<PassengerReferralRewardItem>? rewards;

  PassengerReferralStatsModel({
    this.enabled,
    this.referralCode,
    this.shareLink,
    this.referralsNeeded,
    this.completedReferrals,
    this.pendingReferrals,
    this.progressInCycle,
    this.remainingForNextReward,
    this.welcomeBonusAmount,
    this.freeRideMaxDiscount,
    this.referrals,
    this.rewards,
  });

  factory PassengerReferralStatsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    return PassengerReferralStatsModel(
      enabled: data['enabled'] == true || data['enabled'] == 1,
      referralCode: data['referral_code']?.toString(),
      shareLink: data['share_link']?.toString(),
      referralsNeeded: int.tryParse('${data['referrals_needed'] ?? 3}'),
      completedReferrals: int.tryParse('${data['completed_referrals'] ?? 0}'),
      pendingReferrals: int.tryParse('${data['pending_referrals'] ?? 0}'),
      progressInCycle: int.tryParse('${data['progress_in_cycle'] ?? 0}'),
      remainingForNextReward: int.tryParse('${data['remaining_for_next_reward'] ?? 0}'),
      welcomeBonusAmount: num.tryParse('${data['welcome_bonus_amount'] ?? 5}'),
      freeRideMaxDiscount: num.tryParse('${data['free_ride_max_discount'] ?? 15}'),
      referrals: data['referrals'] != null
          ? (data['referrals'] as List).map((e) => PassengerReferralItem.fromJson(Map<String, dynamic>.from(e))).toList()
          : [],
      rewards: data['rewards'] != null
          ? (data['rewards'] as List).map((e) => PassengerReferralRewardItem.fromJson(Map<String, dynamic>.from(e))).toList()
          : [],
    );
  }
}

class PassengerReferralItem {
  int? id;
  String? name;
  String? status;
  String? registeredAt;
  String? firstTripAt;

  PassengerReferralItem({this.id, this.name, this.status, this.registeredAt, this.firstTripAt});

  factory PassengerReferralItem.fromJson(Map<String, dynamic> json) {
    return PassengerReferralItem(
      id: int.tryParse('${json['id'] ?? 0}'),
      name: json['name']?.toString(),
      status: json['status']?.toString(),
      registeredAt: json['registered_at']?.toString(),
      firstTripAt: json['first_trip_at']?.toString(),
    );
  }
}

class PassengerReferralRewardItem {
  int? id;
  String? rewardType;
  String? couponCode;
  String? status;
  int? milestone;
  String? createdAt;

  PassengerReferralRewardItem({this.id, this.rewardType, this.couponCode, this.status, this.milestone, this.createdAt});

  factory PassengerReferralRewardItem.fromJson(Map<String, dynamic> json) {
    return PassengerReferralRewardItem(
      id: int.tryParse('${json['id'] ?? 0}'),
      rewardType: json['reward_type']?.toString(),
      couponCode: json['coupon_code']?.toString(),
      status: json['status']?.toString(),
      milestone: int.tryParse('${json['milestone'] ?? 0}'),
      createdAt: json['created_at']?.toString(),
    );
  }
}
