const express = require('express');
const auth = require('../lib/auth');
const User = require('../models/User');
const Friendship = require('../models/Friendship');
const router = express.Router();

// Search users by username
router.get('/search', auth, async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) return res.json([]);
    const users = await User.find({
      username: { $regex: q, $options: 'i' },
      _id: { $ne: req.user.id }
    }).select('username').limit(10);
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get suggested friends (users not yet friends with the current user)
router.get('/suggested', auth, async (req, res) => {
  try {
    const friendships = await Friendship.find({
      $or: [{ requester: req.user.id }, { recipient: req.user.id }]
    });

    const friendIds = friendships.map(f => 
      f.requester.toString() === req.user.id ? f.recipient.toString() : f.requester.toString()
    );
    friendIds.push(req.user.id);

    const suggested = await User.find({
      _id: { $nin: friendIds },
      username: { $exists: true, $ne: null }
    }).select('username').limit(10);

    res.json(suggested);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all friends and pending requests
router.get('/', auth, async (req, res) => {
  try {
    const friendships = await Friendship.find({
      $or: [{ requester: req.user.id }, { recipient: req.user.id }]
    }).populate('requester recipient', 'username');

    const pendingIncoming = [];
    const pendingOutgoing = [];
    const friends = [];

    friendships.forEach(f => {
      const isRequester = f.requester._id.toString() === req.user.id;
      const otherUser = isRequester ? f.recipient : f.requester;

      if (f.status === 'accepted') {
        friends.push({ id: otherUser._id, username: otherUser.username });
      } else if (f.status === 'pending') {
        if (isRequester) pendingOutgoing.push({ id: otherUser._id, username: otherUser.username });
        else pendingIncoming.push({ id: otherUser._id, username: otherUser.username, requestId: f._id });
      }
    });

    res.json({ friends, pendingIncoming, pendingOutgoing });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Send friend request
router.post('/request', auth, async (req, res) => {
  try {
    const { targetUserId } = req.body;
    if (targetUserId === req.user.id) return res.status(400).json({ error: 'Cannot add yourself' });

    const existing = await Friendship.findOne({
      $or: [
        { requester: req.user.id, recipient: targetUserId },
        { requester: targetUserId, recipient: req.user.id }
      ]
    });

    if (existing) return res.status(400).json({ error: 'Friendship already exists or pending' });

    const friendship = new Friendship({
      requester: req.user.id,
      recipient: targetUserId
    });
    await friendship.save();

    res.json({ message: 'Friend request sent' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Respond to friend request
router.post('/respond', auth, async (req, res) => {
  try {
    const { requestId, action } = req.body; // action = 'accept' or 'reject'
    const friendship = await Friendship.findOne({ _id: requestId, recipient: req.user.id, status: 'pending' });
    
    if (!friendship) return res.status(404).json({ error: 'Request not found' });

    if (action === 'accept') {
      friendship.status = 'accepted';
      await friendship.save();
    } else {
      await Friendship.deleteOne({ _id: requestId });
    }

    res.json({ message: `Request ${action}ed` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get friend's shared data (streaks, etc.)
router.get('/shared/:id', auth, async (req, res) => {
  try {
    const friendId = req.params.id;
    // Verify they are actually friends
    const friendship = await Friendship.findOne({
      $or: [
        { requester: req.user.id, recipient: friendId, status: 'accepted' },
        { requester: friendId, recipient: req.user.id, status: 'accepted' }
      ]
    });

    if (!friendship) return res.status(403).json({ error: 'Not friends' });

    const friend = await User.findById(friendId).select('username glowPoints dailyStreak longestStreak profile');
    if (!friend) return res.status(404).json({ error: 'Friend not found' });

    res.json(friend);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
