const express = require('express');
const router = express.Router();
const auth = require('../lib/auth');
const User = require('../models/User');
const Friendship = require('../models/Friendship');

// In-memory streak store (could be moved to MongoDB later)
// Structure: { recipientId: { senderId: { lastSent: Date, imageData: string, caption: string } } }
const streakInbox = {};

// Send a streak to a friend
router.post('/send', auth, async (req, res) => {
  try {
    const { friendId, imageData, caption } = req.body;
    if (!friendId) return res.status(400).json({ error: 'Friend ID required' });

    // Verify friendship
    const friendship = await Friendship.findOne({
      $or: [
        { requester: req.user.id, recipient: friendId, status: 'accepted' },
        { requester: friendId, recipient: req.user.id, status: 'accepted' },
      ],
    });
    if (!friendship) return res.status(400).json({ error: 'You are not friends with this user' });

    const sender = await User.findById(req.user.id).select('username');
    const senderName = (sender && sender.username) || 'Someone';

    // Store streak in recipient's inbox
    if (!streakInbox[friendId]) streakInbox[friendId] = {};
    streakInbox[friendId][req.user.id] = {
      senderId: req.user.id,
      senderName: senderName,
      imageData: imageData || null,
      caption: caption || '🔥 Streak!',
      sentAt: new Date().toISOString(),
    };

    // Create a direct message for the chat feed
    const DirectMessage = require('../models/DirectMessage');
    const msgText = imageData ? `📸 ${caption || 'Streak!'}` : `🔥 ${caption || 'Streak!'}`;
    await DirectMessage.create({
      sender: req.user.id,
      recipient: friendId,
      text: msgText
    });

    res.json({ message: 'Streak sent!' });
  } catch (err) {
    console.error('[streaks/send] Error:', err.message);
    res.status(500).json({ error: 'Could not send streak' });
  }
});

// Get my streak inbox (streaks sent to me)
router.get('/inbox', auth, (req, res) => {
  const myInbox = streakInbox[req.user.id] || {};
  const streaks = Object.values(myInbox).sort(
    (a, b) => new Date(b.sentAt) - new Date(a.sentAt)
  );
  res.json({ streaks });
});

// Clear a streak from inbox (after viewing)
router.delete('/inbox/:senderId', auth, (req, res) => {
  const myInbox = streakInbox[req.user.id];
  if (myInbox) {
    delete myInbox[req.params.senderId];
  }
  res.json({ message: 'Streak cleared' });
});

module.exports = router;
