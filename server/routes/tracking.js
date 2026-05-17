const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const db = require('../db');

function clampInt15(n) {
    const v = parseInt(n, 10);
    if (Number.isNaN(v)) return null;
    return Math.min(5, Math.max(1, v));
}

/** Normalize POST body so web (`mood` string), Flutter (`symptoms`/petals), and wellness scalars coexist. */
function normalizeLogPayload(userId, body) {
    const date =
        typeof body.date === 'string' && body.date.trim()
            ? body.date.trim()
            : new Date().toISOString().split('T')[0];

    let moods = Array.isArray(body.moods) ? [...body.moods] : [];
    const moodSingle =
        typeof body.mood === 'string' ? body.mood.trim() : '';
    if (moodSingle && moods.length === 0) moods = [moodSingle];

    const out = {
        userId,
        date,
        moods,
        symptoms: Array.isArray(body.symptoms) ? body.symptoms : [],
        notes: body.notes != null ? String(body.notes) : '',
    };

    if (body.cravingsNote !== undefined) {
        out.cravingsNote = String(body.cravingsNote ?? '').slice(0, 4000);
    }
    if (body.anxietyNote !== undefined) {
        out.anxietyNote = String(body.anxietyNote ?? '').slice(0, 4000);
    }

    if (body.energy != null && String(body.energy).trim() !== '') {
        out.energy = String(body.energy);
    }
    if (body.period !== undefined) {
        out.period = body.period === true || body.period === 'true';
    }
    if (body.flow != null && String(body.flow).trim() !== '') {
        out.flow = String(body.flow).trim();
    }

    ['energyLevel', 'stressLevel', 'sleepQuality'].forEach((k) => {
        if (body[k] === undefined || body[k] === null || body[k] === '') return;
        const c = clampInt15(body[k]);
        if (c != null) out[k] = c;
    });

    const vn = body.voiceNotePath ?? body.audioUrl;
    if (vn != null && vn !== '') {
        out.voiceNotePath = String(vn);
        out.audioUrl = String(vn);
    }

    return out;
}

// Middleware to verify JWT
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

// --- Period Day Routes (Granular Logging) ---

// @route   GET api/tracking/period-days
router.get('/period-days', auth, async (req, res) => {
    try {
        const days = await db.findPeriodDaysByUserId(req.user.id);
        res.json(days.map(d => d.date));
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/tracking/period-days/toggle
router.post('/period-days/toggle', auth, async (req, res) => {
    const { date } = req.body;
    try {
        const logged = await db.togglePeriodDay(req.user.id, date);
        res.json({ msg: logged ? 'Added' : 'Removed', logged });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// --- Daily Log Routes ---

// @route   GET api/tracking/logs  (optional ?from=YYYY-MM-DD&to=YYYY-MM-DD)
router.get('/logs', auth, async (req, res) => {
    try {
        const { from, to } = req.query;
        const range = {};
        if (typeof from === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(from)) range.from = from;
        if (typeof to === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(to)) range.to = to;
        const logs = await db.findLogsByUserId(req.user.id, range);
        res.json(Array.isArray(logs) ? logs : []);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/tracking/logs
router.post('/logs', auth, async (req, res) => {
    try {
        const log = await db.saveLog(normalizeLogPayload(req.user.id, req.body));
        res.json(log);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/tracking/logs/:id
router.delete('/logs/:id', auth, async (req, res) => {
    try {
        await db.deleteLog(req.user.id, req.params.id);
        res.json({ msg: 'Log removed' });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

module.exports = router;
