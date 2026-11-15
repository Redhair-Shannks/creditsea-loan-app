import { Router } from 'express';
import mongoose from 'mongoose';
import adminRoutes from './admin.routes.js';
import authRoutes from './auth.routes.js';
import loanRoutes from './loan.routes.js';
import userRoutes from './user.routes.js';

const router = Router();

router.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    uptimeSec: Math.round(process.uptime()),
  });
});

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/loans', loanRoutes);
router.use('/admin', adminRoutes);

export default router;
