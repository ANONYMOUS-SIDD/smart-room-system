import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/loader_controller.dart';
import '../../controllers/show_password_controller.dart';
import '../../../services/auth_service.dart';
import '../../themes/colors.dart';
import '../auth/utils/auth_utils.dart';
import '../auth/utils/validators.dart';
import '../auth/widgets/auth_buttons.dart';
import '../auth/widgets/auth_header.dart';
import '../auth/widgets/input_container.dart';
import '../auth/widgets/input_fields.dart';
import '../auth/widgets/phone_input_field.dart';
import 'login_screen.dart';

/// USER REGISTRATION SCREEN FOR CREATING NEW ACCOUNT WITH MULTI-FIELD FORM
class SignUpScreen extends StatelessWidget {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final AuthService authService = Get.find<AuthService>();
  final LoaderController loaderController = Get.find<LoaderController>();
  final ShowPasswordController showPasswordController = Get.find<ShowPasswordController>();
  final AuthController authController = Get.find<AuthController>();

  SignUpScreen({super.key});

  /// PROCESS USER REGISTRATION WITH FORM VALIDATION AND ACCOUNT CREATION
  Future<void> _handleSignUp() async {
    if (!formKey.currentState!.validate()) return;

    loaderController.startLoading();
    final user = await authService.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      fullName: fullNameController.text.trim(),
      phone: phoneController.text.trim(),
    );
    loaderController.stopLoading();

    if (user != null) {
      authController.initializeUserSession();
      Get.offAll(() => LoginScreen());
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
                  height: screenHeight * 0.28,
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

  /// CONSTRUCT FORM SECTION WITH ROUNDED CONTAINER AND SCROLLABLE CONTENT
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
          offset: const Offset(0, -20),
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
              margin: const EdgeInsets.only(top: 12),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  width * 0.04,
                  height * 0.007,
                  width * 0.04,
                  bottomInset,
                ),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    _buildTitle(),
                    _buildInputFields(),
                    _buildActionButtons(),
                    _buildPrivacyNotice(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// BUILD SCREEN TITLE WITH GRADIENT TEXT EFFECT
  Widget _buildTitle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Text(
        "Create Account",
        style: GoogleFonts.quicksand(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: AppColors.textGradient,
            ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
        ),
      ),
    );
  }

  /// BUILD ALL REGISTRATION INPUT FIELDS WITH VALIDATION
  Widget _buildInputFields() {
    return InputContainer(
      children: [
        CustomInputField(
          controller: fullNameController,
          icon: Icons.person_2_rounded,
          iconColor: AppColors.nameIconColor,
          hintText: "Full Name",
          validator: AuthValidators.validateFullName,
          keyboardType: TextInputType.name,
        ),
        const InputDivider(),
        PhoneInputField(
          controller: phoneController,
          hintText: "Phone Number",
          validator: AuthValidators.validateNepaliPhone,
        ),
        const InputDivider(),
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
        const InputDivider(),
        CustomInputField(
          controller: confirmPasswordController,
          icon: Icons.lock_rounded,
          iconColor: AppColors.confirmPasswordIconColor,
          hintText: "Confirm Password",
          validator: (value) => AuthValidators.validateConfirmPassword(value, passwordController.text),
          isPassword: true,
          isConfirmPassword: true,
        ),
      ],
    );
  }

  /// BUILD ACTION BUTTONS FOR REGISTRATION AND NAVIGATION
  Widget _buildActionButtons() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Obx(
              () => PrimaryAuthButton(
            text: "Create Your Account",
            icon: Icons.rocket_launch_rounded,
            onPressed: _handleSignUp,
            isLoading: loaderController.isLoading.value,
          ),
        ),
        const SizedBox(height: 15),
        const OrDivider(),
        const SizedBox(height: 15),
        SecondaryAuthButton(
          text: "Use Existing Account",
          icon: Icons.person,
          onPressed: () => Get.off(() => LoginScreen()),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  /// BUILD PRIVACY POLICY AND TERMS OF SERVICE NOTICE TEXT
  Widget _buildPrivacyNotice() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        "By Signing Up, You Agree To Our Terms & Privacy Policy",
        textAlign: TextAlign.center,
        style: GoogleFonts.quicksand(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}