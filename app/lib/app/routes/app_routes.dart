/// Named routes. Screens navigate with `Get.toNamed(Routes.x)`.
abstract final class Routes {
  static const splash = '/';

  // Auth (Figma: Create an account, OTP, Password, Sign in)
  static const welcome = '/welcome';
  static const otp = '/otp';
  static const createPassword = '/create-password';
  static const signIn = '/sign-in';

  // Onboarding (Figma: Details screens)
  static const personalDetails = '/onboarding/personal';
  static const emailVerification = '/onboarding/email';
  static const panVerification = '/onboarding/pan';
  static const employmentDetails = '/onboarding/employment';

  // Loans
  static const home = '/home';
  static const loanCalculator = '/loan/apply';
  static const loanOffer = '/loan/offer';
  static const loanStatus = '/loan/status';
  static const repayment = '/loan/repay';

  static const profile = '/profile';
}
