import 'package:get/get.dart';

class ShowPasswordController extends GetxController {
  var isPasswordVisible = true.obs;
  var isConfirmPasswordVisible = true.obs;

  // Toggles Visibility Of Main Password Field
  void togglePasswordVisibility() => isPasswordVisible.value = !isPasswordVisible.value;

  // Toggles Visibility Of Confirm Password Field
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
}