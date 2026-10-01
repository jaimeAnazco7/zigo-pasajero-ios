import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi_booking/utils/Extensions/app_common.dart';

import '../model/FRideBookingModel.dart';
import '../utils/Constants.dart';
import 'BaseServices.dart';

class RideService extends BaseService {
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  late CollectionReference rideRef;

  RideService() {
    rideRef = fireStore.collection(RIDE_COLLECTION);
  }

  Future addRide(FRideBookingModel rideBookingModel, int? rideID) {
    return rideRef.doc("ride_$rideID").set(rideBookingModel.toJson());
  }

  /// Actualiza (o crea) el doc Firebase con driver_ids para que el conductor lo vea.
  /// Necesario en viajes programados: el hosting no escribe Firestore (sin gRPC).
  Future<void> syncDriverOffer({
    required int rideId,
    required int riderId,
    required int driverId,
    String status = NEW_RIDE_REQUESTED,
    String? paymentType,
  }) async {
    final data = <String, dynamic>{
      'ride_id': rideId,
      'rider_id': riderId,
      'status': status,
      'driver_ids': [driverId],
      'nearby_driver_ids': [driverId],
      'on_rider_stream_api_call': 1,
      'on_stream_api_call': 0,
      'payment_status': '',
      'payment_type': paymentType ?? '',
      'tips': 0,
    };
    await rideRef.doc('ride_$rideId').set(data, SetOptions(merge: true));
    log('Firebase syncDriverOffer ride_$rideId -> driver $driverId');
  }

  /// Crea el doc mínimo del viaje si aún no existe (reserva al activarse).
  Future<void> ensureRideDocument({
    required int rideId,
    required int riderId,
    int? driverId,
    String status = NEW_RIDE_REQUESTED,
    String? paymentType,
  }) async {
    final data = <String, dynamic>{
      'ride_id': rideId,
      'rider_id': riderId,
      'status': status,
      'on_rider_stream_api_call': 1,
      'on_stream_api_call': 0,
      'payment_status': '',
      'payment_type': paymentType ?? '',
      'tips': 0,
    };
    if (driverId != null && driverId > 0) {
      data['driver_ids'] = [driverId];
      data['nearby_driver_ids'] = [driverId];
    }
    await rideRef.doc('ride_$rideId').set(data, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> fetchRide({int? rideId}) {
    print("FEETHFDJHF::${rideId}");
    return rideRef.where('ride_id', isEqualTo: rideId).snapshots();
  }

  Future<QuerySnapshot<Object?>> checkIsRideExist({required int rideId}) async {
    print("checkIsRideExist::${rideId}");
    return await rideRef.where('ride_id', isEqualTo: rideId).get();
  }

  Future<List<FRideBookingModel>> fetchRideFuture({int? rideId}) {
    return rideRef.where('ride_id', isEqualTo: rideId).get().then((value) {
      return value.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> updateStatusOfRide({int? rideID, req}) {
    return rideRef.doc("ride_$rideID").update(req).then((value) {
      log(' status updated');
    }).catchError((e) {
      log('Error status update $e');
    });
  }
}
