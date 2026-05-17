const express = require('express');
const jwt = require('jsonwebtoken');
const db = require('../db');

const router = express.Router();

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

const expertKey = () => String(process.env.AMA_EXPERT_KEY || '').trim();
const adminKey = () => String(process.env.AMA_ADMIN_KEY || process.env.AMA_EXPERT_KEY || '').trim();

const requireExpertKey = (req, res, next) => {
    const expected = expertKey();
    const provided = String(req.header('x-ama-expert-key') || '').trim();
    if (!expected || provided !== expected) {
        return res.status(403).json({ msg: 'Expert key required (x-ama-expert-key)' });
    }
    next();
};

const requireAdminKey = (req, res, next) => {
    const expected = adminKey();
    const provided = String(req.header('x-ama-admin-key') || req.header('x-ama-expert-key') || '').trim();
    if (!expected || provided !== expected) {
        return res.status(403).json({ msg: 'Admin key required (x-ama-admin-key)' });
    }
    next();
};

function expertJson(doc) {
    if (!doc) return null;
    const o = typeof doc.toObject === 'function' ? doc.toObject({ virtuals: true }) : { ...doc };
    return {
        id: String(o.id || o._id),
        slug: o.slug,
        name: o.name,
        title: o.title || '',
        bio: o.bio || '',
        credentials: o.credentials || '',
        avatarUrl: o.avatarUrl || '',
        active: o.active !== false,
    };
}

function sessionJson(doc) {
    if (!doc) return null;
    const o = typeof doc.toObject === 'function' ? doc.toObject({ virtuals: true }) : { ...doc };
    return {
        id: String(o.id || o._id),
        expertSlug: o.expertSlug,
        title: o.title,
        description: o.description || '',
        topics: Array.isArray(o.topics) ? o.topics : [],
        status: o.status || 'scheduled',
        startsAt: o.startsAt,
        endsAt: o.endsAt || null,
        questionCount: o.questionCount ?? 0,
        answeredCount: o.answeredCount ?? 0,
        createdAt: o.createdAt,
        updatedAt: o.updatedAt,
    };
}

function questionJson(doc) {
    if (!doc) return null;
    const o = typeof doc.toObject === 'function' ? doc.toObject({ virtuals: true }) : { ...doc };
    return {
        id: String(o.id || o._id),
        sessionId: String(o.sessionId),
        userId: String(o.userId),
        authorName: o.authorName || 'Glow member',
        body: o.body,
        status: o.status || 'pending',
        answer: o.answer || '',
        answeredBySlug: o.answeredBySlug || '',
        answeredAt: o.answeredAt || null,
        upvoteCount: o.upvoteCount ?? 0,
        createdAt: o.createdAt,
        updatedAt: o.updatedAt,
    };
}

// GET /api/ama/experts
router.get('/experts', async (req, res) => {
    try {
        const rows = await db.findAmaExperts();
        res.json(rows.map(expertJson));
    } catch (err) {
        console.error('[ama] experts:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// GET /api/ama/experts/:slug
router.get('/experts/:slug', async (req, res) => {
    try {
        const expert = await db.findAmaExpertBySlug(req.params.slug);
        if (!expert) return res.status(404).json({ msg: 'Expert not found' });
        res.json(expertJson(expert));
    } catch (err) {
        console.error('[ama] expert:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// GET /api/ama/sessions?status=live
router.get('/sessions', async (req, res) => {
    try {
        const status = req.query?.status ? String(req.query.status).trim() : null;
        const expertSlug = req.query?.expert ? String(req.query.expert).trim() : null;
        const rows = await db.findAmaSessions({ status, expertSlug });
        res.json(rows.map(sessionJson));
    } catch (err) {
        console.error('[ama] sessions:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// GET /api/ama/sessions/:id
router.get('/sessions/:id', async (req, res) => {
    try {
        const session = await db.findAmaSessionById(req.params.id);
        if (!session) return res.status(404).json({ msg: 'Session not found' });
        const expert = await db.findAmaExpertBySlug(session.expertSlug);
        res.json({
            session: sessionJson(session),
            expert: expert ? expertJson(expert) : null,
        });
    } catch (err) {
        console.error('[ama] session:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// POST /api/ama/sessions — admin/expert tooling
router.post('/sessions', requireAdminKey, async (req, res) => {
    try {
        const expertSlug = String(req.body?.expertSlug ?? '').trim();
        const title = String(req.body?.title ?? '').trim();
        const description = String(req.body?.description ?? '').trim();
        const status = String(req.body?.status ?? 'scheduled').trim();
        const startsAt = req.body?.startsAt ? new Date(req.body.startsAt) : new Date();
        const endsAt = req.body?.endsAt ? new Date(req.body.endsAt) : null;
        const topics = Array.isArray(req.body?.topics)
            ? req.body.topics.map((t) => String(t).trim()).filter(Boolean)
            : [];

        if (!expertSlug || !title) {
            return res.status(400).json({ msg: 'expertSlug and title are required' });
        }
        const expert = await db.findAmaExpertBySlug(expertSlug);
        if (!expert) return res.status(400).json({ msg: 'Unknown expert slug' });

        const session = await db.saveAmaSession({
            expertSlug,
            title,
            description,
            topics,
            status: ['scheduled', 'live', 'ended'].includes(status) ? status : 'scheduled',
            startsAt,
            endsAt,
        });
        res.status(201).json(sessionJson(session));
    } catch (err) {
        console.error('[ama] create session:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// PATCH /api/ama/sessions/:id — set live / ended
router.patch('/sessions/:id', requireExpertKey, async (req, res) => {
    try {
        const session = await db.findAmaSessionById(req.params.id);
        if (!session) return res.status(404).json({ msg: 'Session not found' });
        const patch = {};
        if (req.body?.status && ['scheduled', 'live', 'ended'].includes(req.body.status)) {
            patch.status = req.body.status;
        }
        if (req.body?.endsAt) patch.endsAt = new Date(req.body.endsAt);
        const updated = await db.updateAmaSession(req.params.id, patch);
        res.json(sessionJson(updated));
    } catch (err) {
        console.error('[ama] patch session:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// GET /api/ama/sessions/:id/questions
router.get('/sessions/:id/questions', async (req, res) => {
    try {
        const session = await db.findAmaSessionById(req.params.id);
        if (!session) return res.status(404).json({ msg: 'Session not found' });
        const sort = String(req.query?.sort || 'top') === 'recent' ? 'recent' : 'top';
        const rows = await db.findAmaQuestions(req.params.id, { sort });
        res.json(rows.map(questionJson));
    } catch (err) {
        console.error('[ama] questions:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// POST /api/ama/sessions/:id/questions
router.post('/sessions/:id/questions', auth, async (req, res) => {
    try {
        const session = await db.findAmaSessionById(req.params.id);
        if (!session) return res.status(404).json({ msg: 'Session not found' });
        if (session.status === 'ended') {
            return res.status(400).json({ msg: 'This AMA has ended — questions are closed.' });
        }
        const bodyText = String(req.body?.body ?? '').trim();
        if (!bodyText || bodyText.length < 8) {
            return res.status(400).json({ msg: 'Question must be at least 8 characters.' });
        }
        if (bodyText.length > 1200) {
            return res.status(400).json({ msg: 'Question is too long (max 1200 characters).' });
        }

        const user = await db.findUserById(req.user.id);
        const anonymous = req.body?.anonymous === true || req.body?.anonymous === 'true';
        const authorName = anonymous ? 'Anonymous' : (user?.name || 'Glow member');

        const question = await db.saveAmaQuestion({
            sessionId: req.params.id,
            userId: req.user.id,
            authorName,
            body: bodyText,
        });
        res.status(201).json(questionJson(question));
    } catch (err) {
        console.error('[ama] ask:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// POST /api/ama/questions/:id/upvote
router.post('/questions/:id/upvote', auth, async (req, res) => {
    try {
        const updated = await db.upvoteAmaQuestion(req.params.id, req.user.id);
        if (!updated) return res.status(404).json({ msg: 'Question not found' });
        res.json(questionJson(updated));
    } catch (err) {
        console.error('[ama] upvote:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// POST /api/ama/questions/:id/answer — expert only
router.post('/questions/:id/answer', requireExpertKey, async (req, res) => {
    try {
        const answer = String(req.body?.answer ?? '').trim();
        const expertSlug = String(req.body?.expertSlug ?? '').trim();
        if (!answer || answer.length < 4) {
            return res.status(400).json({ msg: 'Answer must be at least 4 characters.' });
        }
        if (answer.length > 4000) {
            return res.status(400).json({ msg: 'Answer is too long (max 4000 characters).' });
        }

        const question = await db.findAmaQuestionById(req.params.id);
        if (!question) return res.status(404).json({ msg: 'Question not found' });

        const session = await db.findAmaSessionById(question.sessionId);
        if (!session) return res.status(404).json({ msg: 'Session not found' });

        const slug = expertSlug || session.expertSlug;
        const updated = await db.answerAmaQuestion(req.params.id, {
            answer,
            answeredBySlug: slug,
        });
        res.json(questionJson(updated));
    } catch (err) {
        console.error('[ama] answer:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
