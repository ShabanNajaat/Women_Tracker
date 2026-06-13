const express = require('express');
const router = express.Router();
const auth = require('../lib/auth');
const Notification = require('../models/Notification');

// GET /api/notifications — fetch user notifications
router.get('/', auth, async (req, res) => {
    try {
        const notifications = await Notification.find({ recipient: req.user.id })
            .populate('sender', 'username')
            .sort({ createdAt: -1 })
            .limit(50)
            .lean();
        const unreadCount = await Notification.countDocuments({ recipient: req.user.id, read: false });
        res.json({ notifications, unreadCount });
    } catch (err) {
        res.status(500).json({ error: 'Could not fetch notifications' });
    }
});

// POST /api/notifications/read — mark all as read
router.post('/read', auth, async (req, res) => {
    try {
        await Notification.updateMany({ recipient: req.user.id, read: false }, { $set: { read: true } });
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Could not mark as read' });
    }
});

// GET /api/notifications/unread-count
router.get('/unread-count', auth, async (req, res) => {
    try {
        const count = await Notification.countDocuments({ recipient: req.user.id, read: false });
        res.json({ count });
    } catch (err) {
        res.status(500).json({ error: 'Could not get count' });
    }
});

module.exports = router;
