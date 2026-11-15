import { Loan } from '../models/Loan.js';
import { adminSetStatus } from '../services/loan.service.js';

/** GET /admin/loans — latest applications with applicant details. */
export async function listLoans(_req, res) {
  const loans = await Loan.find().sort({ createdAt: -1 }).limit(100).populate('user', 'phone firstName lastName creditScore');
  res.json({
    loans: loans.map((loan) => ({
      ...loan.toPublicJSON(),
      applicant: loan.user
        ? {
            id: loan.user.id,
            phone: loan.user.phone,
            name: [loan.user.firstName, loan.user.lastName].filter(Boolean).join(' ') || null,
            creditScore: loan.user.creditScore,
          }
        : null,
    })),
  });
}

/** PATCH /admin/loans/:id/status — manual approve / reject / disburse. */
export async function setStatus(req, res) {
  const { status, note } = req.valid.body;
  const loan = await adminSetStatus(req.valid.params.id, status, note);
  res.json({ loan: loan.toPublicJSON() });
}
