/// AUTHENTICATION FORM VALIDATION UTILITY CLASS FOR INPUT FIELD VALIDATION
class AuthValidators {

  /// VALIDATE FULL NAME INPUT FOR PROPER FORMAT AND LENGTH
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return "Please Enter Your Full Name";
    }
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
      return "Name Should Contain Only Letters And Spaces";
    }
    if (value.length < 2) {
      return "Name Must Be At Least 2 Characters";
    }
    return null;
  }

  /// VALIDATE NEPALI PHONE NUMBER FOR CORRECT FORMAT AND STARTING DIGITS
  static String? validateNepaliPhone(String? value) {
    if (value == null || value.isEmpty) {
      return "Please Enter Your Phone Number";
    }

    // REMOVE ANY SPACES OR SPECIAL CHARACTERS FOR VALIDATION
    final cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanedValue.length != 10) {
      return "Phone Number Must Be Exactly 10 Digits";
    }

    if (!cleanedValue.startsWith('97') && !cleanedValue.startsWith('98')) {
      return "Phone Number Must Start With 97 Or 98";
    }

    return null;
  }

  /// VALIDATE EMAIL ADDRESS FOR STANDARD EMAIL FORMAT COMPLIANCE
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please Enter Your Email Address";
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return "Please Enter A Valid Email Address";
    }
    return null;
  }

  /// VALIDATE PASSWORD FOR MINIMUM SECURITY REQUIREMENTS AND COMPLEXITY
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please Enter A Password";
    }
    if (value.length < 8) {
      return "Password Must Be At Least 8 Characters";
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]+$').hasMatch(value)) {
      return "Password Must Contain Both Letters And Numbers";
    }
    return null;
  }

  /// VALIDATE CONFIRMATION PASSWORD MATCHES ORIGINAL PASSWORD INPUT
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return "Please Confirm Your Password";
    }
    if (value != originalPassword) {
      return "Passwords Do Not Match";
    }
    return null;
  }
}