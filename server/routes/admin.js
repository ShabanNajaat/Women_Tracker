const express = require('express');
const auth = require('../lib/auth');
const User = require('../models/User');
const AppRating = require('../models/AppRating');
const router = express.Router();

// Allow users to submit an app rating
router.post('/rate', auth, async (req, res) => {
  try {
    const { stars, feedback } = req.body;
    if (!stars || stars < 1 || stars > 5) {
      return res.status(400).json({ error: 'Stars must be between 1 and 5' });
    }
    const rating = new AppRating({
      user: req.user.id,
      stars,
      feedback
    });
    await rating.save();
    res.json({ message: 'Rating submitted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin endpoint to view users and ratings
// Requires a hardcoded admin secret passed in headers for simplicity & security
router.get('/dashboard', async (req, res) => {
  try {
    const adminKey = req.headers['x-admin-key'];
    if (adminKey !== 'GlowAdmin2026!') {
      return res.status(401).json({ error: 'Unauthorized: Invalid Admin Key' });
    }

    const users = await User.find({}).select('username email createdAt');
    const ratings = await AppRating.find({}).populate('user', 'username').sort({ createdAt: -1 });

    res.json({
      totalUsers: users.length,
      users,
      ratings
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
