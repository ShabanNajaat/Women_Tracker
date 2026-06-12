const express = require('express');
const router = express.Router();
const auth = require('../lib/auth');
const Story = require('../models/Story');
const Friendship = require('../models/Friendship');

// POST / — Create story
router.post('/', auth, async (req, res) => {
    try {
        const { imageData, caption } = req.body;
        if (!imageData) return res.status(400).json({ error: 'imageData is required' });

        const story = new Story({
            user: req.user.id,
            imageData,
            caption: caption || '',
            expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
        });
        await story.save();
        res.status(201).json(story);
    } catch (err) {
        res.status(500).json({ error: 'Could not create story' });
    }
});

// GET /feed — Get friends' stories from last 24h
router.get('/feed', auth, async (req, res) => {
    try {
        const userId = req.user.id;
        const friendships = await Friendship.find({
            $or: [{ requester: userId }, { recipient: userId }],
            status: 'accepted',
        });
        const friendIds = friendships.map(f =>
            f.requester.toString() === userId ? f.recipient : f.requester
        );
        friendIds.push(userId); // include own stories

        const stories = await Story.find({
            user: { $in: friendIds },
            expiresAt: { $gt: new Date() },
        })
            .sort({ createdAt: -1 })
            .populate('user', 'username photo')
            .lean();

        res.json(stories);
    } catch (err) {
        res.status(500).json({ error: 'Could not fetch stories' });
    }
});

// GET /mine — Get own stories
router.get('/mine', auth, async (req, res) => {
    try {
        const stories = await Story.find({ user: req.user.id })
            .sort({ createdAt: -1 })
            .lean();
        res.json(stories);
    } catch (err) {
        res.status(500).json({ error: 'Could not fetch stories' });
    }
});

// DELETE /:id — Delete own story
router.delete('/:id', auth, async (req, res) => {
    try {
        const story = await Story.findOneAndDelete({ _id: req.params.id, user: req.user.id });
        if (!story) return res.status(404).json({ error: 'Story not found' });
        res.json({ message: 'Story deleted' });
    } catch (err) {
        res.status(500).json({ error: 'Could not delete story' });
    }
});

// POST /:id/react — Add reaction
router.post('/:id/react', auth, async (req, res) => {
    try {
        const { emoji } = req.body;
        const story = await Story.findById(req.params.id);
        if (!story) return res.status(404).json({ error: 'Story not found' });

        story.reactions.push({
            user: req.user.id,
            emoji: emoji || '❤️',
        });
        await story.save();
        res.json({ message: 'Reaction added' });
    } catch (err) {
        res.status(500).json({ error: 'Could not add reaction' });
    }
});

// POST /:id/view — Mark story as viewed
router.post('/:id/view', auth, async (req, res) => {
    try {
        await Story.updateOne(
            { _id: req.params.id },
            { $addToSet: { viewedBy: req.user.id } }
        );
        res.json({ message: 'Story viewed' });
    } catch (err) {
        res.status(500).json({ error: 'Could not mark as viewed' });
    }
});

module.exports = router;
