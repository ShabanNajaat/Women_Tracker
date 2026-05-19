/**
 * Doctor chat (Dr. Najaat).
 * Setup (local `server/.env`, never commit secrets):
 *   - OPENAI_API_KEY — preferred when set; uses OpenAI Chat Completions (official `openai` package).
 *   - Optional: OPENAI_CHAT_MODEL (default gpt-4o-mini).
 *   - GEMINI_API_KEY — used when OpenAI key is absent; optional GEMINI_CHAT_MODEL (default gemini-2.0-flash).
 * If neither key is set, clinic keyword fallbacks and a gentle offline message are used.
 */
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const multer = require('multer');
const db = require('../db');
const { GoogleGenAI } = require('@google/genai');
const OpenAI = require('openai');
const { toFile } = require('openai');

const audioUpload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 24 * 1024 * 1024 },
});

function normalizeSecret(value) {
    if (value == null) return '';
    let s = String(value).trim();
    if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
        s = s.slice(1, -1).trim();
    }
    return s;
}

const openaiKey = normalizeSecret(process.env.OPENAI_API_KEY);
const geminiKey = normalizeSecret(process.env.GEMINI_API_KEY);

const PROVIDER_MAX_ATTEMPTS = 3;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function serializeChatMessage(raw) {
    const m = raw && typeof raw.toObject === 'function' ? raw.toObject({ virtuals: true }) : { ...raw };
    let text = m.text != null ? String(m.text) : '';
    if (!text && m.parts != null) {
        if (typeof m.parts === 'string') text = m.parts;
        else if (typeof m.parts === 'object' && m.parts.text != null) text = String(m.parts.text);
    }
    const id = m.id || m._id?.toString?.() || m._id || '';
    return {
        id: String(id),
        userId: String(m.userId || ''),
        role: m.role,
        text,
        voiceUrl: m.voiceUrl || null,
        timestamp: m.timestamp,
    };
}

function isTransientProviderError(err) {
    const msg = `${err?.message || ''} ${err?.cause?.message || ''}`.toLowerCase();
    const status = err?.status ?? err?.statusCode ?? err?.response?.status;
    if (status === 408 || status === 429 || status === 502 || status === 503 || status === 504) return true;
    return (
        msg.includes('timeout') ||
        msg.includes('timed out') ||
        msg.includes('etimedout') ||
        msg.includes('econnreset') ||
        msg.includes('socket') ||
        msg.includes('fetch failed') ||
        msg.includes('rate limit') ||
        msg.includes('overloaded') ||
        msg.includes('try again') ||
        msg.includes('temporar')
    );
}

let openai = null;
if (openaiKey) {
    openai = new OpenAI({
        apiKey: openaiKey,
        // Per-request ceiling; SDK also retries transient failures (default maxRetries: 2).
        timeout: 180000,
        maxRetries: 3,
    });
}

let geminiAi = null;
if (geminiKey) {
    geminiAi = new GoogleGenAI({ apiKey: geminiKey });
}

function logDrNajaatConfig() {
    const model = process.env.OPENAI_CHAT_MODEL || 'gpt-4o-mini';
    const gemModel = process.env.GEMINI_CHAT_MODEL || 'gemini-2.0-flash';
    if (openai) {
        console.log(`[Dr. Najaat] Using OpenAI (${model}).`);
    } else if (geminiAi) {
        console.log(`[Dr. Najaat] OPENAI_API_KEY not set; using Gemini (${gemModel}).`);
    } else {
        console.warn('[Dr. Najaat] No OPENAI_API_KEY or GEMINI_API_KEY — replies use built-in wellness snippets only.');
    }
}
logDrNajaatConfig();

// System instructions for Dr. Najaat (warm, calm, non-judgmental — roadmap-aligned)
const systemPrompt = `You are Dr. Najaat, a caring women's health and wellness companion (educational only — not a substitute for in-person medical care).

**Voice and tone**
- Warm, calm, and non-judgmental. Validate feelings before offering ideas. Never shame food, sleep, bodies, or "compliance."
- Prefer gentle, plain language in short paragraphs. Offer **one** small, optional next step they can try; you may add "if you want, we can also…" for optional depth.
- Avoid cold lecturing, blame, or alarmist framing. It's okay to name patterns without framing them as failure (e.g. "that can stack with stress" rather than "you need to fix this").

**Scope**
- Focus on general wellness, cycle literacy, and self-care ideas. You may discuss common experiences (cramps, mood shifts, sleep, stress) in an educational way.
- For anything that could be urgent (severe or sudden pain, very heavy bleeding, fever with pain, pregnancy concerns, thoughts of self-harm, panic that won't ease, feeling unsafe): encourage reaching **emergency services or a crisis line** (e.g. 988 in the U.S. when relevant) and contacting a clinician promptly. Stay supportive and clear that you cannot diagnose or treat.

**Format**
- Match the user's depth: short friendly answers for quick questions; up to 2–3 short paragraphs when they want real guidance.
- Use their conversation history and any "About this user" context (cycle phase, day in cycle) to personalize — reference it naturally when relevant.
- On simple greetings, respond with a warm welcome and invite them to share what's on their mind — not a one-word reply.
- Give specific, practical ideas (foods, rest, movement, tracking tips) instead of vague platitudes.
- If their question is vague, ask one gentle clarifying question, then offer 2–3 concrete suggestions.
- Do not repeat the same opening every message; vary wording and reference what they just said.

**Ideas you can draw on (not prescriptions)**
- Cramps: heat, rest, gentle movement, hydration; when to consider medical care if symptoms are unusual for them.
- Sleep or fatigue: wind-down routines, consistency, honoring rest; not guilt for hard nights.
- Stress or anxiety: grounding, breath, tiny breaks; professional support when it feels bigger than self-care.

Close serious or uncertain topics with a reminder to check in with a qualified clinician when something doesn't feel right for them.

**Reply structure (important)**
- Line 1: brief empathy that mirrors what they said.
- Then 2–4 bullet points with specific, doable ideas (food, rest, heat, tracking, breathwork).
- End with one short follow-up question OR a calm clinician reminder if symptoms sound severe.
- Never reply with only a greeting if they asked a real question. Never reply with a single vague sentence.`;

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

function buildUserContextBlock(body) {
    const ctx = body?.context;
    if (!ctx || typeof ctx !== 'object') return '';
    const parts = [];
    if (ctx.phase) parts.push(`Cycle phase: ${ctx.phase}`);
    if (ctx.cycleDay != null) parts.push(`Day in cycle (approx.): ${ctx.cycleDay}`);
    if (ctx.cycleLength != null) parts.push(`Typical cycle length: ${ctx.cycleLength} days`);
    if (ctx.recentMood) parts.push(`Recent mood: ${ctx.recentMood}`);
    if (ctx.recentEnergy) parts.push(`Recent energy: ${ctx.recentEnergy}`);
    if (ctx.recentSleep) parts.push(`Recent sleep: ${ctx.recentSleep}`);
    if (parts.length === 0) return '';
    return parts.join('. ') + '.';
}

/** Avoid matching "hi" inside "this", "thinking", etc. */
function matchesKeyword(text, keyword) {
    const k = String(keyword).toLowerCase().trim();
    if (!k) return false;
    if (k.length <= 4) {
        const escaped = k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        return new RegExp(`\\b${escaped}\\b`, 'i').test(text);
    }
    return text.includes(k);
}

async function buildChatMessagesForProvider(userId, userText, extraContext) {
    const history = await db.findChatMessages(userId);
    const trimmed = (userText || '').trim();
    // Drop the message we just saved — we'll add it once at the end.
    let recent = history.slice(-24);
    if (trimmed && recent.length > 0) {
        const last = serializeChatMessage(recent[recent.length - 1]);
        if (last.role === 'user' && (last.text || '').trim() === trimmed) {
            recent = recent.slice(0, -1);
        }
    }
    recent = recent.slice(-16);

    const systemContent = extraContext
        ? `${systemPrompt}\n\n**About this user right now**\n${extraContext}`
        : systemPrompt;

    const messages = [{ role: 'system', content: systemContent }];

    for (const raw of recent) {
        const row = serializeChatMessage(raw);
        const text = (row.text || '').trim();
        if (!text || text.length < 2) continue;
        const role = row.role === 'ai' ? 'assistant' : 'user';
        messages.push({ role, content: text });
    }

    if (trimmed) {
        messages.push({ role: 'user', content: trimmed });
    }

    return messages;
}

async function generateDoctorReply(userId, userText, extraContext = '') {
    const content = userText || 'The user shared their feelings.';
    const messages = await buildChatMessagesForProvider(userId, content, extraContext);

    if (openai) {
        const completion = await openai.chat.completions.create({
            model: process.env.OPENAI_CHAT_MODEL || 'gpt-4o-mini',
            messages,
            max_tokens: 1024,
            temperature: 0.7,
            top_p: 0.95,
            presence_penalty: 0.2,
            frequency_penalty: 0.15,
        });
        const text = completion.choices[0]?.message?.content?.trim();
        return text || null;
    }

    if (geminiAi) {
        const geminiContents = messages
            .filter((m) => m.role !== 'system')
            .map((m) => ({
                role: m.role === 'assistant' ? 'model' : 'user',
                parts: [{ text: m.content }],
            }));
        const result = await geminiAi.models.generateContent({
            model: process.env.GEMINI_CHAT_MODEL || 'gemini-2.0-flash',
            contents: geminiContents.length ? geminiContents : [{ role: 'user', parts: [{ text: content }] }],
            config: {
                systemInstruction: messages[0]?.content || systemPrompt,
                temperature: 0.72,
                maxOutputTokens: 900,
            },
        });
        const text = result.text?.trim();
        return text || null;
    }

    return null;
}

async function generateDoctorReplyWithRetry(userId, userText, extraContext = '') {
    let lastErr;
    for (let attempt = 1; attempt <= PROVIDER_MAX_ATTEMPTS; attempt++) {
        try {
            return await generateDoctorReply(userId, userText, extraContext);
        } catch (err) {
            lastErr = err;
            if (!isTransientProviderError(err) || attempt === PROVIDER_MAX_ATTEMPTS) {
                throw err;
            }
            const delayMs = 800 * attempt;
            console.warn(`[Dr. Najaat] transient provider error (attempt ${attempt}/${PROVIDER_MAX_ATTEMPTS}), retry in ${delayMs}ms`);
            await sleep(delayMs);
        }
    }
    throw lastErr;
}

// @route   POST api/chat/transcribe — OpenAI Whisper (requires OPENAI_API_KEY)
router.post('/transcribe', auth, audioUpload.single('audio'), async (req, res) => {
    if (!req.file || !req.file.buffer) {
        return res.status(400).json({ error: 'no_audio', message: 'No audio file uploaded.' });
    }
    if (!openai) {
        return res.status(503).json({
            error: 'no_openai',
            message: 'Voice notes need OPENAI_API_KEY on the server (Whisper transcription).',
        });
    }
    try {
        const name = (req.file.originalname && String(req.file.originalname)) || 'voice.m4a';
        const file = await toFile(req.file.buffer, name);
        const tr = await openai.audio.transcriptions.create({
            file,
            model: process.env.OPENAI_TRANSCRIBE_MODEL || 'whisper-1',
        });
        const text = (tr.text || '').trim();
        res.json({ text });
    } catch (err) {
        console.error('[Dr. Najaat] Transcribe error:', err?.message || err);
        res.status(500).json({
            error: 'transcribe_failed',
            message: 'Could not transcribe that recording. Try again or type your message.',
        });
    }
});

// @route   GET api/chat
router.get('/', auth, async (req, res) => {
    try {
        const messages = await db.findChatMessages(req.user.id);
        res.json(messages.map((row) => serializeChatMessage(row)));
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/chat
router.post('/', auth, async (req, res) => {
    const { role, text, voiceUrl } = req.body;

    try {
        if (role === 'ai') {
            await db.saveChatMessage({ userId: req.user.id, role: 'ai', text, voiceUrl });
            return res.json({ aiResponse: text, aiConfigured: !!(openai || geminiAi), aiProvider: openai ? 'openai' : geminiAi ? 'gemini' : 'none' });
        }

        await db.saveChatMessage({ userId: req.user.id, role: 'user', text, voiceUrl });

        const cleanText = (text || '').toLowerCase().trim();
        const hasProvider = !!(openai || geminiAi);
        const userContext = buildUserContextBlock(req.body);

        const clinic = [
            { keywords: ['headache', 'migraine', 'head ache'], response: "I'm really sorry your head hurts — that can wear you down. If you can, try a quieter, dimmer space, sips of water or peppermint tea, and a cool cloth on your forehead. If this is new, severe, or comes with fever or stiff neck, it's worth checking in with a clinician." },
            { keywords: ['cramp', 'period pain', 'stomach ache'], response: "Cramps can take a lot out of you, and your body deserves gentleness. Heat on your lower belly, slow breathing, and easy movement sometimes help. If the pain is sudden, much worse than your usual, or paired with fever or heavy bleeding, please reach out to urgent care or your doctor." },
            { keywords: ['bloat', 'bloating', 'heavy'], response: "Bloating can feel heavy and frustrating — you're not doing anything wrong. Easy things to try: steady hydration, a little less salt if that feels right for you, and foods with potassium (like bananas). If something feels off from your normal, a clinician can help you sort it out." },
            { keywords: ['tired', 'fatigue', 'exhausted'], response: "When you're this tired, it makes sense to move more slowly. Your body may be asking for rest, warmth, and nourishing food — iron-rich options with a bit of vitamin C can support energy for some people. If exhaustion is sudden or severe, checking in with a clinician is a kind step." },
            { keywords: ['hi', 'hello', 'hey', 'start'], response: "Hi — I'm glad you're here. However you're feeling today is valid. What's been on your mind, or what would feel supportive to talk through?" }
        ];

        const fallbackMatch = clinic.find((c) => c.keywords.some((k) => matchesKeyword(cleanText, k)));

        if (fallbackMatch && !hasProvider) {
            await db.saveChatMessage({ userId: req.user.id, role: 'ai', text: fallbackMatch.response });
            return res.json({
                aiResponse: fallbackMatch.response,
                aiConfigured: false,
                aiProvider: 'none',
                aiNotice: 'Add OPENAI_API_KEY or GEMINI_API_KEY to server/.env for full AI replies from Dr. Najaat.',
            });
        }

        if (!hasProvider) {
            const aiText = "I'm here with you. My fuller AI mode is resting right now, but you're not alone. What would feel most supportive to focus on — sleep, stress, cramps, or something else on your mind?";
            await db.saveChatMessage({ userId: req.user.id, role: 'ai', text: aiText });
            return res.json({
                aiResponse: aiText,
                aiConfigured: false,
                aiProvider: 'none',
                aiNotice: 'Add OPENAI_API_KEY or GEMINI_API_KEY to server/.env (see server/.env.example) to enable Dr. Najaat AI.',
            });
        }

        let aiText = null;
        let aiWarning = null;
        try {
            aiText = await generateDoctorReplyWithRetry(req.user.id, text, userContext);
        } catch (err) {
            const detail = err?.message || String(err);
            console.error('[Dr. Najaat] Provider error:', detail);
            const isTimeout = /timeout|timed out|etimedout|408|504/i.test(detail);
            const isAuth = /401|403|invalid.*api.*key|incorrect api key|authentication/i.test(detail);
            if (isAuth) {
                aiWarning = 'Server AI key may be invalid or expired. Check OPENAI_API_KEY on Render.';
            } else if (isTimeout) {
                aiWarning = 'The AI service timed out. Tap send again in a moment.';
            } else {
                aiWarning = `AI error: ${detail.slice(0, 120)}`;
            }
        }

        if (!aiText || !String(aiText).trim()) {
            const retryText =
                "I couldn't finish a thoughtful reply just now — that's on my side, not yours. Please tap send again; if it keeps happening, the app's server may need its AI key checked.";
            await db.saveChatMessage({ userId: req.user.id, role: 'ai', text: retryText });
            return res.json({
                aiResponse: retryText,
                aiConfigured: true,
                aiProvider: openai ? 'openai' : 'gemini',
                aiWarning: aiWarning || 'AI returned an empty reply.',
            });
        }

        await db.saveChatMessage({ userId: req.user.id, role: 'ai', text: aiText });

        res.json({
            aiResponse: aiText,
            aiConfigured: true,
            aiProvider: openai ? 'openai' : 'gemini',
            ...(aiWarning ? { aiWarning } : {}),
        });
    } catch (err) {
        console.error('[Dr. Najaat] Chat route error:', err?.message || err);
        const failText = "Something hiccuped on my side, but I'm still glad you're here. When you're ready, try sending your message once more — or share what's worrying you most today.";
        try {
            await db.saveChatMessage({ userId: req.user.id, role: 'ai', text: failText });
        } catch (_) { /* ignore */ }
        res.status(200).json({
            aiResponse: failText,
            aiConfigured: !!(openai || geminiAi),
            aiProvider: openai ? 'openai' : geminiAi ? 'gemini' : 'none',
            aiWarning: 'Something went wrong saving or generating this message. You can try sending again.',
        });
    }
});

function getChatAiStatus() {
    return {
        aiConfigured: !!(openai || geminiAi),
        aiProvider: openai ? 'openai' : geminiAi ? 'gemini' : 'none',
        model: openai
            ? process.env.OPENAI_CHAT_MODEL || 'gpt-4o-mini'
            : geminiAi
              ? process.env.GEMINI_CHAT_MODEL || 'gemini-2.0-flash'
              : null,
    };
}

router.getChatAiStatus = getChatAiStatus;

module.exports = router;
