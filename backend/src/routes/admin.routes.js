import { Router } from 'express';
import { listLoans, setStatus } from '../controllers/admin.controller.js';
import { requireAdmin } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { adminStatusSchema, objectIdParam } from '../validators/schemas.js';

const router = Router();

router.use(requireAdmin);
router.get('/loans', listLoans);
router.patch('/loans/:id/status', validate(objectIdParam, 'params'), validate(adminStatusSchema), setStatus);

export default router;
