const express = require('express');
const router = express.Router();
const auth = require('../lib/auth');
const DirectMessage = require('../models/DirectMessage');
const Friendship = require('../models/Friendship');

// Get message history with a specific friend
router.get('/:friendId', auth, async (req, res) => {
  try {
    const { friendId } = req.params;
    
    // Optional: verify friendship
    const friendship = await Friendship.findOne({
      $or: [
        { requester: req.user.id, recipient: friendId, status: 'accepted' },
        { requester: friendId, recipient: req.user.id, status: 'accepted' },
      ],
    });
    
    if (!friendship) {
      return res.status(403).json({ error: 'You are not friends with this user' });
    }

    const messages = await DirectMessage.find({
      $or: [
        { sender: req.user.id, recipient: friendId },
        { sender: friendId, recipient: req.user.id },
      ],
    }).sort({ createdAt: 1 }).limit(100);

    // Mark as read
    await DirectMessage.updateMany(
      { sender: friendId, recipient: req.user.id, read: false },
      { $set: { read: true } }
    );

    res.json({ messages });
  } catch (err) {
    console.error('[messages/history] Error:', err);
    res.status(500).json({ error: 'Could not fetch messages' });
  }
});

module.exports = router;
