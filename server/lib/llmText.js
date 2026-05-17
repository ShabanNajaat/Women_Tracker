const OpenAI = require('openai');
const { GoogleGenAI } = require('@google/genai');

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

let openai = null;
if (openaiKey) {
    openai = new OpenAI({ apiKey: openaiKey, timeout: 120000, maxRetries: 2 });
}

let geminiAi = null;
if (geminiKey) {
    geminiAi = new GoogleGenAI({ apiKey: geminiKey });
}

function providerName() {
    if (openai) return 'openai';
    if (geminiAi) return 'gemini';
    return 'none';
}

async function generateText({ systemPrompt, userPrompt, maxTokens = 500 }) {
    if (openai) {
        const completion = await openai.chat.completions.create({
            model: process.env.OPENAI_CHAT_MODEL || 'gpt-4o-mini',
            messages: [
                { role: 'system', content: systemPrompt },
                { role: 'user', content: userPrompt },
            ],
            max_tokens: maxTokens,
            response_format: { type: 'json_object' },
        });
        return completion.choices[0]?.message?.content?.trim() || null;
    }

    if (geminiAi) {
        const result = await geminiAi.models.generateContent({
            model: process.env.GEMINI_CHAT_MODEL || 'gemini-2.0-flash',
            contents: `${systemPrompt}\n\n${userPrompt}`,
        });
        return result.text?.trim() || null;
    }

    return null;
}

module.exports = { generateText, providerName };
