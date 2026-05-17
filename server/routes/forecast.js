const express = require('express');
const jwt = require('jsonwebtoken');
const { generateText, providerName } = require('../lib/llmText');

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

const FORECAST_SYSTEM = `You are Glow's cycle forecasting assistant (educational wellness only — not diagnosis).

Given structured cycle and health log statistics, respond with ONLY valid JSON:
{
  "narrative": "2-3 warm sentences about the next ~2 weeks",
  "highlights": ["bullet 1", "bullet 2", "bullet 3"],
  "watchFor": ["optional gentle watch-out", "..."],
  "nextTwoWeeksTip": "one practical self-care sentence"
}

Rules:
- Reference their phase, predicted period timing, and any mood/energy patterns when provided.
- If cycles are irregular, mention a date window not a single exact day.
- Never prescribe medication or claim medical certainty.
- If data is sparse, encourage logging and be honest about uncertainty.`;

function templateForecast(ctx) {
    const phase = ctx.currentPhase || 'your current phase';
    const days = ctx.daysUntilPeriod;
    const periodLine =
        days != null && days >= 0
            ? `Your next period may arrive in about ${days} day${days === 1 ? '' : 's'}${ctx.isIrregular ? ' (wider window if cycles vary)' : ''}.`
            : 'Log period starts to sharpen period timing.';

    return {
        narrative: `You are in the ${phase} phase. ${periodLine} Patterns in your logs suggest honoring rest and hydration as priorities — this is wellness education, not medical advice.`,
        highlights: [
            ctx.confidenceLabel ? `Prediction confidence: ${ctx.confidenceLabel}` : 'Keep logging to personalize forecasts',
            ctx.topSymptom ? `You often log “${ctx.topSymptom}” in similar phases` : 'Track mood & energy to unlock richer forecasts',
        ],
        watchFor: ctx.isIrregular
            ? ['Cycles vary — treat dates as estimates and listen to your body']
            : ['Sudden changes vs your usual pattern are worth mentioning to a clinician'],
        nextTwoWeeksTip: 'Pick one small habit (sleep, water, or gentle movement) and repeat it — consistency beats perfection.',
        source: 'template',
        aiConfigured: false,
    };
}

function parseAiJson(raw) {
    if (!raw) return null;
    try {
        const start = raw.indexOf('{');
        const end = raw.lastIndexOf('}');
        if (start < 0 || end <= start) return null;
        return JSON.parse(raw.slice(start, end + 1));
    } catch (_) {
        return null;
    }
}

// POST /api/forecast/ai — personalized narrative from cycle + health context
router.post('/ai', auth, async (req, res) => {
    try {
        const ctx = req.body?.context;
        if (!ctx || typeof ctx !== 'object') {
            return res.status(400).json({ msg: 'context object is required' });
        }

        const provider = providerName();
        if (provider === 'none') {
            return res.json(templateForecast(ctx));
        }

        const userPrompt = `User cycle forecast context (JSON):\n${JSON.stringify(ctx, null, 2)}`;

        let raw;
        try {
            raw = await generateText({
                systemPrompt: FORECAST_SYSTEM,
                userPrompt,
                maxTokens: 550,
            });
        } catch (err) {
            console.error('[forecast] AI error:', err?.message || err);
            return res.json({
                ...templateForecast(ctx),
                source: 'template',
                aiConfigured: true,
                aiError: 'Provider unavailable — showing offline summary.',
            });
        }

        const parsed = parseAiJson(raw);
        if (!parsed) {
            return res.json({
                ...templateForecast(ctx),
                source: 'template',
                aiConfigured: true,
                aiError: 'Could not parse AI response.',
            });
        }

        res.json({
            narrative: String(parsed.narrative || '').trim() || templateForecast(ctx).narrative,
            highlights: Array.isArray(parsed.highlights)
                ? parsed.highlights.map((s) => String(s)).filter(Boolean).slice(0, 4)
                : [],
            watchFor: Array.isArray(parsed.watchFor)
                ? parsed.watchFor.map((s) => String(s)).filter(Boolean).slice(0, 3)
                : [],
            nextTwoWeeksTip: String(parsed.nextTwoWeeksTip || '').trim(),
            source: provider,
            aiConfigured: true,
        });
    } catch (err) {
        console.error('[forecast] route:', err?.message || err);
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
