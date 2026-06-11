const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const db = require('../db');

const isProd = process.env.NODE_ENV === 'production';

function jsonUser(doc) {
    if (!doc) return null;
    const o = typeof doc.toObject === 'function' ? doc.toObject() : { ...doc };
    const id = o.id || o._id?.toString?.() || o._id;
        id: String(id),
        username: o.username,
        name: o.name,
        email: o.email,
        photo: o.photo != null && String(o.photo).trim() !== '' ? String(o.photo) : null,
        glowPoints: o.glowPoints || 0,
        profile: o.profile || { cycleLength: 28, periodLength: 5 },
    };
}

function sendError(res, status, { code, message, devDetail }) {
    const body = { error: code || 'error', message: message || 'Something went wrong' };
    if (!isProd && devDetail) body.details = devDetail;
    return res.status(status).json(body);
}

// Helper: verify token middleware
const auth = (req, res, next) => {
    const token = req.header('x-auth-token');
    if (!token) return sendError(res, 401, { code: 'no_token', message: 'Not signed in' });
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded.user;
        next();
    } catch (err) {
        sendError(res, 401, {
            code: 'invalid_token',
            message: 'Session expired. Please sign in again.',
            devDetail: err.message,
        });
    }
};

function signTokenAndRespond(res, userDoc) {
    const user = jsonUser(userDoc);
    const payload = { user: { id: user.id } };
    jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' }, (err, token) => {
        if (err) {
            console.error(err);
            return sendError(res, 500, {
                code: 'token_sign_failed',
                message: 'Could not create session',
                devDetail: err.message,
            });
        }
        res.json({ token, user });
    });
}

let googleOAuthClient;
function getGoogleAudiences() {
    const raw = process.env.GOOGLE_CLIENT_ID || '';
    let s = String(raw).trim();
    if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
        s = s.slice(1, -1).trim();
    }
    return s
        .split(',')
        .map((x) => {
            let p = String(x).trim();
            if ((p.startsWith('"') && p.endsWith('"')) || (p.startsWith("'") && p.endsWith("'"))) {
                p = p.slice(1, -1).trim();
            }
            return p;
        })
        .filter(Boolean);
}

async function verifyGoogleIdToken(idToken) {
    const audiences = getGoogleAudiences();
    if (!audiences.length) {
        const err = new Error('GOOGLE_CLIENT_ID is not configured on the server');
        err.code = 'google_not_configured';
        throw err;
    }
    if (!googleOAuthClient) googleOAuthClient = new OAuth2Client();
    const ticket = await googleOAuthClient.verifyIdToken({
        idToken,
        audience: audiences,
    });
    const payload = ticket.getPayload();
    if (!payload?.sub || !payload.email) {
        const err = new Error('Invalid Google token payload');
        err.code = 'google_token_invalid';
        throw err;
    }
    return {
        sub: payload.sub,
        email: db.normalizeEmail(payload.email),
        emailVerified: payload.email_verified === true,
        name: payload.name || 'Glow member',
        picture: payload.picture,
    };
}

/** Web GIS often returns access_token without id_token; verify via tokeninfo. */
async function verifyGoogleAccessToken(accessToken) {
    const audiences = getGoogleAudiences();
    if (!audiences.length) {
        const err = new Error('GOOGLE_CLIENT_ID is not configured on the server');
        err.code = 'google_not_configured';
        throw err;
    }
    if (!googleOAuthClient) googleOAuthClient = new OAuth2Client();
    const info = await googleOAuthClient.getTokenInfo(accessToken);
    const sub = info.sub || info.user_id;
    if (!sub) {
        const err = new Error('Invalid Google access token');
        err.code = 'google_token_invalid';
        throw err;
    }
    const aud = info.aud || info.azp;
    if (aud && !audiences.includes(String(aud))) {
        const err = new Error(`Google token audience mismatch (${aud})`);
        err.code = 'google_token_invalid';
        throw err;
    }
    let email = info.email;
    let name = info.name;
    let picture = info.picture;
    let emailVerified = info.email_verified === true || info.email_verified === 'true';
    if (!email) {
        const res = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
            headers: { Authorization: `Bearer ${accessToken}` },
        });
        if (!res.ok) {
            const err = new Error('Could not load Google profile from access token');
            err.code = 'google_token_invalid';
            throw err;
        }
        const profile = await res.json();
        email = profile.email;
        name = name || profile.name;
        picture = picture || profile.picture;
        emailVerified = emailVerified || profile.email_verified === true;
    }
    if (!email) {
        const err = new Error('Google account did not include an email');
        err.code = 'google_token_invalid';
        throw err;
    }
    return {
        sub: String(sub),
        email: db.normalizeEmail(email),
        emailVerified,
        name: name || 'Glow member',
        picture,
    };
}

async function googleAuthUpsert(claims) {
    const { sub, email, name, picture } = claims;
    let user = await db.findUserByGoogleSub(sub);
    if (user) {
        let changed = false;
        if (name && user.name !== name) {
            user.name = name;
            changed = true;
        }
        if (picture && user.photo !== picture) {
            user.photo = picture;
            changed = true;
        }
        if (changed) await db.saveUser(user);
        return { user, isNewUser: false };
    }
    user = await db.findUserByEmail(email);
    if (user) {
        if (user.googleSub && user.googleSub !== sub) {
            const err = new Error('This email is linked to a different Google account');
            err.code = 'google_email_conflict';
            throw err;
        }
        user.googleSub = sub;
        if (name) user.name = user.name || name;
        if (picture) user.photo = picture;
        await db.saveUser(user);
        return { user, isNewUser: false };
    }
    user = await db.saveUser({
        name,
        email,
        photo: picture,
        googleSub: sub,
        glowPoints: 0,
        profile: { cycleLength: 28, periodLength: 5 },
    });
    return { user, isNewUser: true };
}

// @route   POST api/auth/register
router.post('/register', async (req, res) => {
    const name = String(req.body.name ?? '').trim();
    const email = db.normalizeEmail(req.body.email);
    const password = req.body.password;
    try {
        if (!process.env.JWT_SECRET) {
            return sendError(res, 500, {
                code: 'server_misconfigured',
                message: 'Server auth is not configured',
            });
        }
        if (!name) return sendError(res, 400, { code: 'validation', message: 'Name is required' });
        if (!email) return sendError(res, 400, { code: 'validation', message: 'Email is required' });
        if (!password || String(password).length < 6) {
            return sendError(res, 400, { code: 'validation', message: 'Password must be at least 6 characters' });
        }

        let user = await db.findUserByEmail(email);
        if (user) return sendError(res, 400, { code: 'user_exists', message: 'An account with this email already exists' });

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        user = await db.saveUser({
            name,
            email,
            password: hashedPassword,
            glowPoints: 0,
            profile: { cycleLength: 28, periodLength: 5 },
        });

        return res.status(201).json({
            success: true,
            message: 'Account created. Sign in with your email and password.',
            email: user.email || email,
        });
    } catch (err) {
        console.error(err.message);
        sendError(res, 500, {
            code: 'server_error',
            message: 'Server error',
            devDetail: err.message,
        });
    }
});

// @route   POST api/auth/login
router.post('/login', async (req, res) => {
    const email = db.normalizeEmail(req.body.email);
    const password = req.body.password;
    try {
        if (!process.env.JWT_SECRET) {
            return sendError(res, 500, {
                code: 'server_misconfigured',
                message: 'Server auth is not configured',
            });
        }
        const user = await db.findUserByEmail(email);
        if (!user) {
            return sendError(res, 401, { code: 'invalid_credentials', message: 'Invalid email or password' });
        }
        if (!user.password) {
            if (user.googleSub) {
                return sendError(res, 401, {
                    code: 'use_google',
                    message: 'This account uses Google sign-in. Continue with Google.',
                });
            }
            return sendError(res, 401, { code: 'invalid_credentials', message: 'Invalid email or password' });
        }
        const hash = user.password;
        if (typeof hash !== 'string' || !hash.startsWith('$2')) {
            console.error('[auth] User has invalid password hash for', email);
            return sendError(res, 401, { code: 'invalid_credentials', message: 'Invalid email or password' });
        }
        const isMatch = await bcrypt.compare(String(password), hash);
        if (!isMatch) {
            return sendError(res, 401, { code: 'invalid_credentials', message: 'Invalid email or password' });
        }

        signTokenAndRespond(res, user);
    } catch (err) {
        console.error(err.message);
        sendError(res, 500, {
            code: 'server_error',
            message: 'Server error',
            devDetail: err.message,
        });
    }
});

// @route   POST api/auth/google  (preferred)
// @route   POST api/auth/google-login (alias)
async function handleGooglePost(req, res) {
    const idToken = req.body.idToken || req.body.id_token;
    const accessToken = req.body.accessToken || req.body.access_token;
    const legacyToken = req.body.token;
    try {
        if (!process.env.JWT_SECRET) {
            return sendError(res, 500, {
                code: 'server_misconfigured',
                message: 'Server auth is not configured',
            });
        }
        const hasId = idToken && typeof idToken === 'string';
        const hasAccess = accessToken && typeof accessToken === 'string';
        const hasLegacy = legacyToken && typeof legacyToken === 'string' && !hasId && !hasAccess;
        if (!hasId && !hasAccess && !hasLegacy) {
            return sendError(res, 400, {
                code: 'validation',
                message: 'idToken or accessToken is required',
            });
        }

        let claims;
        try {
            if (hasId) {
                claims = await verifyGoogleIdToken(idToken);
            } else if (hasAccess) {
                claims = await verifyGoogleAccessToken(accessToken);
            } else {
                claims = await verifyGoogleIdToken(legacyToken);
            }
        } catch (e) {
            if (e.code === 'google_not_configured') {
                return sendError(res, 503, {
                    code: 'google_not_configured',
                    message: 'Google sign-in is not enabled on this server',
                    devDetail: e.message,
                });
            }
            console.error(e.message);
            return sendError(res, 401, {
                code: 'google_verification_failed',
                message: 'Could not verify Google sign-in',
                devDetail: e.message,
            });
        }

        if (!claims.emailVerified && isProd) {
            return sendError(res, 401, {
                code: 'email_not_verified',
                message: 'Please verify your Google email and try again',
            });
        }

        const { user, isNewUser } = await googleAuthUpsert(claims);
        const userPayload = jsonUser(user);
        const payload = { user: { id: userPayload.id } };
        jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' }, (err, token) => {
            if (err) {
                console.error(err);
                return sendError(res, 500, {
                    code: 'token_sign_failed',
                    message: 'Could not create session',
                    devDetail: err.message,
                });
            }
            res.json({ token, user: userPayload, isNewUser });
        });
    } catch (err) {
        console.error(err.message);
        if (err.code === 'google_email_conflict') {
            return sendError(res, 409, { code: err.code, message: err.message });
        }
        sendError(res, 500, {
            code: 'server_error',
            message: 'Server error',
            devDetail: err.message,
        });
    }
}

router.post('/google', handleGooglePost);
router.post('/google-login', handleGooglePost);

// Public values for the web client (OAuth client IDs are not secret).
router.get('/public-config', (req, res) => {
    const ids = getGoogleAudiences();
    res.json({
        googleClientId: ids[0] || null,
        googleClientIds: ids,
    });
});

// @route   GET api/auth/profile
router.get('/profile', auth, async (req, res) => {
    try {
        const user = await db.findUserById(req.user.id);
        if (!user) return sendError(res, 404, { code: 'not_found', message: 'User not found' });
        const u = jsonUser(user);
        res.json({
            ...u,
            cycleLength: user.profile?.cycleLength ?? 28,
            periodLength: user.profile?.periodLength ?? 5,
        });
    } catch (err) {
        console.error(err.message);
        sendError(res, 500, {
            code: 'server_error',
            message: 'Server error',
            devDetail: err.message,
        });
    }
});

// @route   POST api/auth/profile
const MAX_PHOTO_CHARS = 450000; // ~330KB base64 data URL — keeps Mongo documents reasonable

router.post('/profile', auth, async (req, res) => {
    const { name, cycleLength, periodLength, notifications, photo } = req.body;
    try {
        let user = await db.findUserById(req.user.id);
        if (!user) return sendError(res, 404, { code: 'not_found', message: 'User not found' });

        if (name !== undefined) user.name = String(name || '').trim() || user.name;
        if (photo !== undefined) {
            if (photo === null || photo === '') {
                user.photo = null;
            } else {
                const p = String(photo);
                if (p.length > MAX_PHOTO_CHARS) {
                    return sendError(res, 400, {
                        code: 'photo_too_large',
                        message: 'Profile photo is too large. Try a smaller image.',
                    });
                }
                if (!p.startsWith('data:image/')) {
                    return sendError(res, 400, {
                        code: 'invalid_photo',
                        message: 'Photo must be a data URL image (data:image/…;base64,…).',
                    });
                }
                user.photo = p;
            }
        }
        user.profile = {
            ...(user.profile || {}),
            ...(cycleLength != null && { cycleLength: parseInt(cycleLength, 10) }),
            ...(periodLength != null && { periodLength: parseInt(periodLength, 10) }),
            ...(notifications && { notifications }),
        };

        await db.saveUser(user);
        const u = jsonUser(user);
        res.json({ success: true, ...u });
    } catch (err) {
        console.error(err.message);
        sendError(res, 500, {
            code: 'server_error',
            message: 'Server error',
            devDetail: err.message,
        });
    }
});

// @route   POST api/auth/award-points
router.post('/award-points', auth, async (req, res) => {
    const { points } = req.body;
    try {
        const user = await db.awardPoints(req.user.id, points);
        res.json({ glowPoints: user.glowPoints });
    } catch (err) {
        console.error(err.message);
        sendError(res, 500, {
            code: 'server_error',
            message: 'Server error',
            devDetail: err.message,
        });
    }
});

// @route   POST api/auth/reset-password
router.post('/reset-password', async (req, res) => {
    res.json({ success: true, message: 'If that email exists, a reset link has been sent.' });
});

// @route   POST api/auth/set-username
router.post('/set-username', auth, async (req, res) => {
    let { username } = req.body;
    try {
        if (!username) return sendError(res, 400, { code: 'validation', message: 'Username is required' });
        
        username = username.toString().trim().toLowerCase();
        
        if (username.includes(' ')) {
            return sendError(res, 400, { code: 'validation', message: 'Username cannot contain spaces' });
        }
        
        if (username.length < 3) {
            return sendError(res, 400, { code: 'validation', message: 'Username must be at least 3 characters' });
        }

        const existing = await db.findUserByQuery({ username });
        if (existing) {
            if (existing.id === req.user.id) {
                return res.json({ success: true, user: jsonUser(existing) });
            }
            return sendError(res, 400, { code: 'username_taken', message: 'This username is already taken' });
        }

        const user = await db.findUserById(req.user.id);
        if (!user) return sendError(res, 404, { code: 'not_found', message: 'User not found' });

        user.username = username;
        await db.saveUser(user);
        
        res.json({ success: true, user: jsonUser(user) });
    } catch (err) {
        console.error(err.message);
        sendError(res, 500, {
            code: 'server_error',
            message: 'Server error',
            devDetail: err.message,
        });
    }
});

module.exports = router;
