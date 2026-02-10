import 'package:get/get.dart';

class LoaderController extends GetxController {
  var isLoading = false.obs;

  // Changes Loading Indicator State To True
  void startLoading() => isLoading.value = true;

  // Changes Loading Indicator State To False
  void stopLoading() => isLoading.value = false;

  // Toggles Between Loading And Not Loading States
  void toggleLoading() => isLoading.value = !isLoading.value;
}