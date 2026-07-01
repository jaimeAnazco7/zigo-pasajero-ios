class FRideBookingModel {
  int? riderId;
  int? driverID;
  int? rideId;
  String? status;
  String? paymentType;
  int? onStreamApiCall;
  int? onRiderStreamApiCall;
  int? tips;
  String? paymentStatus;
  List<int>? driver_ids;
  List<dynamic>? nearby_driver_ids; // <--- AÑADIDO

  FRideBookingModel({
    this.riderId,
    this.driverID,
    this.rideId,
    this.paymentStatus,
    this.status,
    this.paymentType,
    this.tips,
    this.onStreamApiCall = 0,
    this.onRiderStreamApiCall = 0,
    this.driver_ids,
    this.nearby_driver_ids,
  });

  FRideBookingModel.fromJson(Map<String, dynamic> json) {
    riderId = int.tryParse(json["rider_id"].toString());
    driverID = int.tryParse(json["driver_id"].toString());
    rideId = int.tryParse(json["ride_id"].toString());
    paymentStatus = json['payment_status'];
    status = json["status"];
    tips = int.tryParse(json["tips"].toString()) ?? null;
    paymentType = json["payment_type"];
    onStreamApiCall = json["on_stream_api_call"];
    onRiderStreamApiCall = json["on_rider_stream_api_call"];
    if (json['driver_ids'] != null) {
      driver_ids = List<int>.from(json['driver_ids']);
    }
    nearby_driver_ids = json['nearby_driver_ids'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["rider_id"] = this.riderId;
    data["ride_id"] = this.rideId;
    data["driver_id"] = this.driverID;
    data['payment_status'] = this.paymentStatus;
    data["status"] = this.status;
    data["tips"] = this.tips;
    data["payment_type"] = this.paymentType;
    data["on_stream_api_call"] = this.onStreamApiCall;
    data["on_rider_stream_api_call"] = this.onRiderStreamApiCall;
    if (this.driver_ids != null) {
      data["driver_ids"] = this.driver_ids;
    }
    if (this.nearby_driver_ids != null) {
      data["nearby_driver_ids"] = this.nearby_driver_ids;
    }
    return data;
  }
}
