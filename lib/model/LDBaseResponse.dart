class LDBaseResponse {
  int? rideRequestId;
  int? riderequest_in_driver_id;
  List<dynamic>? nearby_driver_ids;
  bool? status;
  String? message;

  LDBaseResponse({this.status, this.message,this.rideRequestId, this.riderequest_in_driver_id, this.nearby_driver_ids});

  LDBaseResponse.fromJson(Map<String, dynamic> json) {
    rideRequestId = json['riderequest_id'];
    riderequest_in_driver_id = json['riderequest_in_driver_id'];
    nearby_driver_ids = json['nearby_driver_ids'];
    status = json['status'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['order_id'] = this.rideRequestId;
    data['riderequest_in_driver_id'] = this.riderequest_in_driver_id;
    data['nearby_driver_ids'] = this.nearby_driver_ids;
    data['status'] = this.status;
    data['message'] = this.message;
    return data;
  }
}
