import '../main.dart';

List<String> getCancelReasonList() {
  List<String> list = [];
  list.add(language.driverGoingWrongDirection);
  list.add(language.pickUpTimeTakingTooLong);
  list.add(language.driverAskedMeToCancel);
  list.add(language.safetyConcerns);
  list.add(language.driverNotShown);
  list.add(language.noNeedRide);
  list.add(language.infoNotMatch);
  list.add(language.needToEditRide);
  list.add(language.others);
  return list;
}
