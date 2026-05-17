const express = require('express');
const jwt = require('jsonwebtoken');
const db = require('../db');

const router = express.Router();

const PHASE_ROOMS = new Set(['menstrual', 'follicular', 'ovulatory', 'luteal']);

const auth = (req, res, next) => {
    const token = req.header('x-auth-token');
    if (!token) return res.status(401).json({ msg: 'No token, authorization denied' });
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded.user;
        next();
    } catch (err) {
        res.status(401).json({ msg: 'Token is not valid' });
    }
};

function postJson(doc) {
    if (!doc) return null;
    const o = typeof doc.toObject === 'function' ? doc.toObject({ virtuals: true }) : { ...doc };
    const id = o.id || o._id?.toString?.() || o._id;
    return {
        id: String(id),
        userId: String(o.userId),
        authorName: o.authorName || 'Glow member',
        title: o.title,
        body: o.body,
        phaseRoom: o.phaseRoom || null,
        commentCount: o.commentCount ?? 0,
        createdAt: o.createdAt,
        updatedAt: o.updatedAt,
    };
}

function commentJson(doc) {
    if (!doc) return null;
    const o = typeof doc.toObject === 'function' ? doc.toObject({ virtuals: true }) : { ...doc };
    const id = o.id || o._id?.toString?.() || o._id;
    return {
        id: String(id),
        postId: String(o.postId),
        userId: String(o.userId),
        authorName: o.authorName || 'Glow member',
        body: o.body,
        createdAt: o.createdAt,
        updatedAt: o.updatedAt,
    };
}

// GET /api/community/posts?phase=menstrual
router.get('/posts', auth, async (req, res) => {
    try {
        const phase = req.query?.phase ? String(req.query.phase).trim() : null;
        if (phase && !PHASE_ROOMS.has(phase)) {
            return res.status(400).json({ msg: 'Invalid phase room' });
        }
        const rows = await db.findCommunityPosts({ phaseRoom: phase || undefined });
        res.json(rows.map((r) => postJson(r)));
    } catch (err) {
        console.error('[community] list posts:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// POST /api/community/posts
router.post('/posts', auth, async (req, res) => {
    try {
        const title = String(req.body?.title ?? '').trim();
        const bodyText = String(req.body?.body ?? '').trim();
        if (!title || !bodyText) {
            return res.status(400).json({ msg: 'Title and body are required' });
        }
        const user = await db.findUserById(req.user.id);
        const authorName = user?.name || 'Glow member';
        let phaseRoom = req.body?.phaseRoom ? String(req.body.phaseRoom).trim() : null;
        if (phaseRoom && !PHASE_ROOMS.has(phaseRoom)) {
            return res.status(400).json({ msg: 'Invalid phase room' });
        }
        if (!phaseRoom) phaseRoom = null;
        const post = await db.saveCommunityPost({
            userId: req.user.id,
            authorName,
            title,
            body: bodyText,
            phaseRoom,
        });
        res.status(201).json(postJson(post));
    } catch (err) {
        console.error('[community] create post:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// GET /api/community/posts/:id
router.get('/posts/:id', auth, async (req, res) => {
    try {
        const post = await db.findCommunityPostById(req.params.id);
        if (!post) return res.status(404).json({ msg: 'Post not found' });
        res.json(postJson(post));
    } catch (err) {
        console.error('[community] get post:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// GET /api/community/posts/:id/comments
router.get('/posts/:id/comments', auth, async (req, res) => {
    try {
        const post = await db.findCommunityPostById(req.params.id);
        if (!post) return res.status(404).json({ msg: 'Post not found' });
        const rows = await db.findCommunityComments(req.params.id);
        res.json(rows.map((r) => commentJson(r)));
    } catch (err) {
        console.error('[community] list comments:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// POST /api/community/posts/:id/comments
router.post('/posts/:id/comments', auth, async (req, res) => {
    try {
        const post = await db.findCommunityPostById(req.params.id);
        if (!post) return res.status(404).json({ msg: 'Post not found' });
        const bodyText = String(req.body?.body ?? '').trim();
        if (!bodyText) {
            return res.status(400).json({ msg: 'Comment body is required' });
        }
        const user = await db.findUserById(req.user.id);
        const authorName = user?.name || 'Glow member';
        const comment = await db.saveCommunityComment({
            postId: req.params.id,
            userId: req.user.id,
            authorName,
            body: bodyText,
        });
        res.status(201).json(commentJson(comment));
    } catch (err) {
        console.error('[community] create comment:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
