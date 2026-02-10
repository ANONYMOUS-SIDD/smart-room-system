import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/loader_controller.dart';
import '../../controllers/show_password_controller.dart';
import '../../../services/auth_service.dart';
import '../../services/toast_service.dart';
import '../../themes/colors.dart';
import '../auth/utils/auth_utils.dart';
import '../auth/utils/validators.dart';
import '../auth/widgets/auth_buttons.dart';
import '../auth/widgets/auth_header.dart';
import '../auth/widgets/input_container.dart';
import '../auth/widgets/input_fields.dart';
import '../main/main_screen.dart';
import 'signup_screen.dart';

/// LOGIN SCREEN FOR EXISTING USER AUTHENTICATION WITH EMAIL AND PASSWORD
class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final AuthService authService = Get.find<AuthService>();
  final LoaderController loaderController = Get.find<LoaderController>();
  final ShowPasswordController showPasswordController = Get.find<ShowPasswordController>();
  final AuthController authController = Get.find<AuthController>();
  final ToastService toastService = Get.find<ToastService>();

  LoginScreen({Key? key}) : super(key: key);

  /// EXECUTE USER LOGIN PROCESS WITH FORM VALIDATION AND AUTHENTICATION
  Future<void> _handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    loaderController.startLoading();
    final user = await authService.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
    loaderController.stopLoading();

    if (user != null) {
      authController.initializeUserSession();
      toastService.showSuccessMessage("Login Successful!");
      Get.offAll(() => MainScreen());
    }
  }

  /// INITIATE PASSWORD RESET PROCESS WITH EMAIL VALIDATION
  Future<void> _handleForgotPassword() async {
    if (emailController.text.isEmpty) {
      toastService.showErrorMessage("Enter Email To Reset Password");
      return;
    }

    final emailError = AuthValidators.validateEmail(emailController.text.trim());
    if (emailError != null) {
      toastService.showErrorMessage("Enter Valid Email To Reset Password");
      return;
    }

    loaderController.startLoading();
    final success = await authService.sendPasswordResetEmail(emailController.text.trim());
    loaderController.stopLoading();

    if (success) {
      toastService.showSuccessMessage("Forgot Password Email Sent");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = AuthUtils.getResponsiveHeight(context, 1.0);
    final double screenWidth = AuthUtils.getResponsiveWidth(context, 1.0);
    final double bottomInset = AuthUtils.getBottomInset(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: false,
      body: Form(
        key: formKey,
        child: Stack(
          children: [
            ...AuthUtils.buildBackgroundGradients(context),
            Column(
              children: [
                AuthHeader(
                  height: screenHeight * 0.38,
                  animationPath: 'assets/images/lock_animation.json',
                  backgroundImagePath: 'assets/images/auth_background.jpg',
                ),
                Expanded(
                  child: _buildFormSection(context, screenHeight, screenWidth, bottomInset),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// CONSTRUCT FORM SECTION WITH ROUNDED CONTAINER AND CONTENT LAYOUT
  Widget _buildFormSection(BuildContext context, double height, double width, double bottomInset) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -35),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  width * 0.04,
                  height * 0.02,
                  width * 0.04,
                  bottomInset,
                ),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    _buildTitle(),
                    _buildInputFields(),
                    _buildForgotPassword(),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// BUILD SCREEN TITLE WITH GRADIENT TEXT STYLING
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          "Welcome Back",
          style: GoogleFonts.quicksand(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: AppColors.textGradient,
              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// BUILD FORM INPUT FIELDS CONTAINER WITH EMAIL AND PASSWORD FIELDS
  Widget _buildInputFields() {
    return InputContainer(
      children: [
        CustomInputField(
          controller: emailController,
          icon: Icons.email_rounded,
          iconColor: AppColors.emailIconColor,
          hintText: "Email Address",
          validator: AuthValidators.validateEmail,
          keyboardType: TextInputType.emailAddress,
        ),
        const InputDivider(),
        CustomInputField(
          controller: passwordController,
          icon: Icons.lock_rounded,
          iconColor: AppColors.passwordIconColor,
          hintText: "Password",
          validator: AuthValidators.validatePassword,
          isPassword: true,
        ),
      ],
    );
  }

  /// BUILD FORGOT PASSWORD TEXT LINK WITH TAP GESTURE SUPPORT
  Widget _buildForgotPassword() {
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(top: 16, right: 4),
      child: GestureDetector(
        onTap: _handleForgotPassword,
        child: Text(
          "Forgot Password?",
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  /// BUILD ACTION BUTTONS SECTION FOR LOGIN AND NAVIGATION OPTIONS
  Widget _buildActionButtons() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Obx(
              () => PrimaryAuthButton(
            text: "Login To Your Account",
            icon: Icons.login_rounded,
            onPressed: _handleLogin,
            isLoading: loaderController.isLoading.value,
          ),
        ),
        const SizedBox(height: 20),
        const OrDivider(),
        const SizedBox(height: 20),
        SecondaryAuthButton(
          text: "Create New Account",
          icon: Icons.person_add_rounded,
          onPressed: () => Get.off(() => SignUpScreen()),
        ),
      ],
    );
  }
}