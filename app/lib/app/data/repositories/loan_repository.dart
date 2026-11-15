import '../models/json.dart';
import '../models/loan.dart';
import '../models/loan_config.dart';
import '../models/loan_quote.dart';
import '../models/user.dart';
import '../providers/api_client.dart';

/// Result of a repayment: the updated loan and the user's new credit score.
typedef RepaymentResult = ({Loan loan, AppUser user});

/// Loan endpoints (`/loans/*`).
class LoanRepository {
  LoanRepository(this._api);

  final ApiClient _api;

  Loan _loan(Json json) => Loan.fromJson(asJson(json['loan']));

  Future<LoanConfig> config() async => LoanConfig.fromJson(await _api.getJson('/loans/config'));

  Future<LoanAssessment> quote({required int principal, required int tenureDays}) async {
    final json = await _api.postJson('/loans/quote', {'principal': principal, 'tenureDays': tenureDays});
    return LoanAssessment.fromJson(asJson(json['assessment']));
  }

  Future<Loan> apply({required int principal, required int tenureDays, required String purpose}) async =>
      _loan(await _api.postJson('/loans', {'principal': principal, 'tenureDays': tenureDays, 'purpose': purpose}));

  Future<List<Loan>> list() async {
    final json = await _api.getJson('/loans');
    return asJsonList(json['loans']).map(Loan.fromJson).toList();
  }

  Future<Loan> get(String id) async => _loan(await _api.getJson('/loans/$id'));

  Future<Loan> completeEkyc(String id, String aadhaarNumber) async =>
      _loan(await _api.postJson('/loans/$id/ekyc', {'aadhaarNumber': aadhaarNumber, 'consent': true}));

  Future<Loan> completeEnach(String id, {required String accountNumber, required String ifsc}) async =>
      _loan(await _api.postJson('/loans/$id/enach', {'accountNumber': accountNumber, 'ifsc': ifsc}));

  Future<Loan> completeEsign(String id) async => _loan(await _api.postJson('/loans/$id/esign', {'agreed': true}));

  Future<RepaymentResult> repay(String id, {required int amount, required String upiId}) async {
    final json = await _api.postJson('/loans/$id/repayments', {'amount': amount, 'method': 'UPI', 'upiId': upiId});
    return (loan: _loan(json), user: AppUser.fromJson(asJson(json['user'])));
  }
}
