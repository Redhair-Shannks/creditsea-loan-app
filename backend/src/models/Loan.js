import mongoose from 'mongoose';

/**
 * Status flow (assignment): SUBMITTED -> UNDER_REVIEW -> APPROVED | REJECTED -> DISBURSED.
 * After approval the borrower completes E-KYC, E-NACH and E-Sign (from the Figma design),
 * then the money is disbursed. A fully repaid loan becomes CLOSED.
 */
export const LOAN_STATUSES = Object.freeze(['SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'DISBURSED', 'CLOSED']);
export const ACTIVE_LOAN_STATUSES = Object.freeze(['SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'DISBURSED']);
export const VERIFICATION_STEPS = Object.freeze(['EKYC', 'ENACH', 'ESIGN']);

const statusEventSchema = new mongoose.Schema(
  {
    status: { type: String, enum: LOAN_STATUSES, required: true },
    note: { type: String },
    at: { type: Date, required: true },
  },
  { _id: false },
);

const repaymentSchema = new mongoose.Schema({
  amount: { type: Number, required: true, min: 1 },
  method: { type: String, required: true },
  upiId: { type: String },
  reference: { type: String, required: true },
  paidAt: { type: Date, required: true },
});

const loanSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    applicationNo: { type: String, required: true, unique: true },
    purpose: { type: String, required: true },

    // Pricing is frozen at application time so later product changes don't affect it.
    principal: { type: Number, required: true },
    tenureDays: { type: Number, required: true },
    interestPerDayPct: { type: Number, required: true },
    processingFeePct: { type: Number, required: true },
    interest: { type: Number, required: true },
    processingFee: { type: Number, required: true },
    totalPayable: { type: Number, required: true },
    disbursalAmount: { type: Number, required: true },

    status: { type: String, enum: LOAN_STATUSES, default: 'SUBMITTED', index: true },
    statusUpdatedAt: { type: Date, default: Date.now },
    statusHistory: { type: [statusEventSchema], default: [] },

    decision: {
      reasons: { type: [String], default: undefined },
      bureauScore: { type: Number },
      decidedAt: { type: Date },
    },

    // Post-approval steps; we keep only masked identifiers.
    steps: {
      ekycAt: { type: Date },
      aadhaarMasked: { type: String },
      enachAt: { type: Date },
      bankAccountMasked: { type: String },
      ifsc: { type: String },
      esignAt: { type: Date },
    },

    disbursedAt: { type: Date },
    dueDate: { type: Date },
    amountPaid: { type: Number, default: 0 },
    repayments: { type: [repaymentSchema], default: [] },
    closedAt: { type: Date },
  },
  { timestamps: true, optimisticConcurrency: true },
);

loanSchema.virtual('outstanding').get(function outstanding() {
  return Math.max(0, this.totalPayable - this.amountPaid);
});

loanSchema.methods.toPublicJSON = function toPublicJSON() {
  const steps = this.steps ?? {};
  return {
    id: this.id,
    applicationNo: this.applicationNo,
    purpose: this.purpose,
    principal: this.principal,
    tenureDays: this.tenureDays,
    interestPerDayPct: this.interestPerDayPct,
    processingFeePct: this.processingFeePct,
    interest: this.interest,
    processingFee: this.processingFee,
    totalPayable: this.totalPayable,
    disbursalAmount: this.disbursalAmount,
    status: this.status,
    statusUpdatedAt: this.statusUpdatedAt,
    statusHistory: this.statusHistory.map(({ status, note, at }) => ({ status, note: note ?? null, at })),
    rejectionReasons: this.status === 'REJECTED' ? (this.decision?.reasons ?? []) : [],
    steps: {
      ekycAt: steps.ekycAt ?? null,
      aadhaarMasked: steps.aadhaarMasked ?? null,
      enachAt: steps.enachAt ?? null,
      bankAccountMasked: steps.bankAccountMasked ?? null,
      ifsc: steps.ifsc ?? null,
      esignAt: steps.esignAt ?? null,
    },
    disbursedAt: this.disbursedAt ?? null,
    dueDate: this.dueDate ?? null,
    amountPaid: this.amountPaid,
    outstanding: this.outstanding,
    repayments: this.repayments.map((r) => ({
      id: r.id,
      amount: r.amount,
      method: r.method,
      upiId: r.upiId ?? null,
      reference: r.reference,
      paidAt: r.paidAt,
    })),
    closedAt: this.closedAt ?? null,
    createdAt: this.createdAt,
  };
};

export const Loan = mongoose.model('Loan', loanSchema);
