import 'package:get/get.dart';

import '../modules/auth/create_password/create_password_binding.dart';
import '../modules/auth/create_password/create_password_view.dart';
import '../modules/auth/otp/otp_binding.dart';
import '../modules/auth/otp/otp_view.dart';
import '../modules/auth/sign_in/sign_in_binding.dart';
import '../modules/auth/sign_in/sign_in_view.dart';
import '../modules/auth/welcome/welcome_binding.dart';
import '../modules/auth/welcome/welcome_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/loan_calculator/loan_calculator_binding.dart';
import '../modules/loan_calculator/loan_calculator_view.dart';
import '../modules/loan_offer/loan_offer_binding.dart';
import '../modules/loan_offer/loan_offer_view.dart';
import '../modules/loan_status/loan_status_binding.dart';
import '../modules/loan_status/loan_status_view.dart';
import '../modules/onboarding/email_verification/email_verification_view.dart';
import '../modules/onboarding/employment_details/employment_details_view.dart';
import '../modules/onboarding/onboarding_bindings.dart';
import '../modules/onboarding/pan_verification/pan_verification_view.dart';
import '../modules/onboarding/personal_details/personal_details_view.dart';
import '../modules/profile/profile_binding.dart';
import '../modules/profile/profile_view.dart';
import '../modules/repayment/repayment_binding.dart';
import '../modules/repayment/repayment_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import 'app_routes.dart';
import 'auth_guard.dart';

/// Route table: every screen with its binding (dependency injection) and guards.
abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = [
    GetPage(name: Routes.splash, page: () => const SplashView(), binding: SplashBinding()),

    // Auth
    GetPage(name: Routes.welcome, page: () => const WelcomeView(), binding: WelcomeBinding()),
    GetPage(name: Routes.otp, page: () => const OtpView(), binding: OtpBinding()),
    GetPage(name: Routes.signIn, page: () => const SignInView(), binding: SignInBinding()),
    _protected(Routes.createPassword, () => const CreatePasswordView(), CreatePasswordBinding()),

    // Onboarding
    _protected(Routes.personalDetails, () => const PersonalDetailsView(), PersonalDetailsBinding()),
    _protected(Routes.emailVerification, () => const EmailVerificationView(), EmailVerificationBinding()),
    _protected(Routes.panVerification, () => const PanVerificationView(), PanVerificationBinding()),
    _protected(Routes.employmentDetails, () => const EmploymentDetailsView(), EmploymentDetailsBinding()),

    // Loans
    _protected(Routes.home, () => const HomeView(), HomeBinding()),
    _protected(Routes.loanCalculator, () => const LoanCalculatorView(), LoanCalculatorBinding()),
    _protected(Routes.loanOffer, () => const LoanOfferView(), LoanOfferBinding()),
    _protected(Routes.loanStatus, () => const LoanStatusView(), LoanStatusBinding()),
    _protected(Routes.repayment, () => const RepaymentView(), RepaymentBinding()),
    _protected(Routes.profile, () => const ProfileView(), ProfileBinding()),
  ];

  /// A page that requires a signed-in user.
  static GetPage<dynamic> _protected(String name, GetPageBuilder page, Bindings binding) =>
      GetPage(name: name, page: page, binding: binding, middlewares: [AuthGuard()]);
}
