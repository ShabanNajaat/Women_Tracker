const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const db = require('../db');

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

const generateCode = () => {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
};

const todayKey = () => {
    const n = new Date();
    const y = n.getFullYear();
    const m = String(n.getMonth() + 1).padStart(2, '0');
    const d = String(n.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
};

const yesterdayKey = (key) => {
    const [y, m, d] = key.split('-').map(Number);
    const dt = new Date(y, m - 1, d);
    dt.setDate(dt.getDate() - 1);
    const yy = dt.getFullYear();
    const mm = String(dt.getMonth() + 1).padStart(2, '0');
    const dd = String(dt.getDate()).padStart(2, '0');
    return `${yy}-${mm}-${dd}`;
};

const userIdOf = (u) => (u && (u.id || u._id)) ? String(u.id || u._id) : '';

const streakPayload = (u) => ({
    streak: u.dailyStreak || 0,
    longest: u.longestStreak || 0,
    checkedInToday: u.lastStreakDate === todayKey(),
    lastStreakDate: u.lastStreakDate || null,
    lastSharedAt: u.lastStreakSharedAt || null,
});

/** Record today's check-in and advance consecutive-day streak. */
const applyStreakCheckIn = (user) => {
    const today = todayKey();
    if (user.lastStreakDate === today) {
        return user;
    }
    const yday = yesterdayKey(today);
    if (user.lastStreakDate === yday) {
        user.dailyStreak = (user.dailyStreak || 0) + 1;
    } else {
        user.dailyStreak = 1;
    }
    if ((user.dailyStreak || 0) > (user.longestStreak || 0)) {
        user.longestStreak = user.dailyStreak;
    }
    user.lastStreakDate = today;
    return user;
};

// @route   GET api/partner/invite-code
router.get('/invite-code', auth, async (req, res) => {
    try {
        let user = await db.findUserById(req.user.id);
        if (!user) return res.status(404).json({ msg: 'User not found' });

        if (user.inviteCode) {
            return res.json({ inviteCode: user.inviteCode });
        }

        let code;
        let exists = true;
        while (exists) {
            code = generateCode();
            const existingUser = await db.findUserByInviteCode(code);
            if (!existingUser) exists = false;
        }

        user.inviteCode = code;
        await db.saveUser(user);
        res.json({ inviteCode: code });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/partner/join
router.post('/join', auth, async (req, res) => {
    const { code } = req.body;
    try {
        const partner = await db.findUserByInviteCode(String(code || '').toUpperCase());
        if (!partner) return res.status(404).json({ msg: 'Invalid invite code' });

        if (userIdOf(partner) === req.user.id) {
            return res.status(400).json({ msg: 'Cannot join yourself' });
        }

        const user = await db.findUserById(req.user.id);
        user.partnerUid = userIdOf(partner);
        await db.saveUser(user);

        res.json({ msg: 'Partner linked — share your daily streak together.', partnerName: partner.name || 'Partner' });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   GET api/partner/streak
router.get('/streak', auth, async (req, res) => {
    try {
        const user = await db.findUserById(req.user.id);
        if (!user) return res.status(404).json({ msg: 'User not found' });

        const inviteCode = user.inviteCode || null;
        const linked = Boolean(user.partnerUid);
        let partner = null;
        let partnerBlock = null;

        if (linked) {
            partner = await db.findUserById(user.partnerUid);
            if (partner) {
                partnerBlock = {
                    name: partner.name || 'Partner',
                    ...streakPayload(partner),
                };
            }
        }

        const nudge = db.peekPartnerNudge(req.user.id);

        res.json({
            linked,
            inviteCode,
            partnerName: partnerBlock ? partnerBlock.name : null,
            me: streakPayload(user),
            partner: partnerBlock,
            bothCheckedInToday: Boolean(
                partnerBlock &&
                user.lastStreakDate === todayKey() &&
                partnerBlock.checkedInToday
            ),
            pendingNudge: nudge
                ? { fromName: nudge.fromName, message: nudge.message, createdAt: nudge.createdAt }
                : null,
        });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/partner/streak/check-in
router.post('/streak/check-in', auth, async (req, res) => {
    try {
        const user = await db.findUserById(req.user.id);
        if (!user) return res.status(404).json({ msg: 'User not found' });

        applyStreakCheckIn(user);
        const today = todayKey();
        const sharedWithPartner = Boolean(user.partnerUid);
        if (sharedWithPartner) {
            user.lastStreakSharedAt = today;
        }
        await db.saveUser(user);

        let partnerBlock = null;
        if (user.partnerUid) {
            const partner = await db.findUserById(user.partnerUid);
            if (partner) {
                partnerBlock = {
                    name: partner.name || 'Partner',
                    ...streakPayload(partner),
                };
            }
        }

        res.json({
            me: streakPayload(user),
            partner: partnerBlock,
            sharedWithPartner,
            bothCheckedInToday: Boolean(
                partnerBlock &&
                user.lastStreakDate === today &&
                partnerBlock.checkedInToday
            ),
        });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   GET api/partner/data
router.get('/data', auth, async (req, res) => {
    try {
        const user = await db.findUserById(req.user.id);
        if (!user || !user.partnerUid) return res.status(404).json({ msg: 'No partner linked' });

        const partnerDays = await db.findPeriodDaysByUserId(user.partnerUid);
        const partnerUser = await db.findUserById(user.partnerUid);

        res.json({
            name: partnerUser ? partnerUser.name : 'Unknown',
            periodDays: partnerDays.map((d) => d.date),
        });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/partner/send-nudge
router.post('/send-nudge', auth, async (req, res) => {
    const { message } = req.body;
    try {
        const user = await db.findUserById(req.user.id);
        if (!user || !user.partnerUid) return res.status(400).json({ msg: 'No partner connected' });

        const text =
            message && String(message).trim().length > 0
                ? String(message).trim()
                : `${user.name || 'Your partner'} is cheering you on — open Glow and keep your streak alive today! 🔥`;

        db.pushPartnerNudge(user.partnerUid, userIdOf(user), user.name, text);
        await db.awardPoints(req.user.id, 10);

        res.json({ success: true, msg: 'Streak nudge sent! +10 Glow Points ✨' });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/partner/nudge/read
router.post('/nudge/read', auth, async (req, res) => {
    try {
        db.markPartnerNudgeRead(req.user.id);
        res.json({ success: true });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/partner/leave
router.post('/leave', auth, async (req, res) => {
    try {
        const user = await db.findUserById(req.user.id);
        if (user) user.partnerUid = null;
        await db.saveUser(user);
        res.json({ success: true });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

module.exports = router;
