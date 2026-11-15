import { Router } from 'express';
import { apply, completeStep, getConfig, getOne, list, quote, repay } from '../controllers/loan.controller.js';
import { requireAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import {
  ekycSchema,
  enachSchema,
  esignSchema,
  loanApplySchema,
  loanQuoteSchema,
  objectIdParam,
  repaymentSchema,
} from '../validators/schemas.js';

const router = Router();
const loanId = validate(objectIdParam, 'params');

router.get('/config', getConfig); // public: the calculator can render before sign-in

router.use(requireAuth);
router.get('/', list);
router.post('/', validate(loanApplySchema), apply);
router.post('/quote', validate(loanQuoteSchema), quote);
router.get('/:id', loanId, getOne);
router.post('/:id/ekyc', loanId, validate(ekycSchema), completeStep('ekyc'));
router.post('/:id/enach', loanId, validate(enachSchema), completeStep('enach'));
router.post('/:id/esign', loanId, validate(esignSchema), completeStep('esign'));
router.post('/:id/repayments', loanId, validate(repaymentSchema), repay);

export default router;
