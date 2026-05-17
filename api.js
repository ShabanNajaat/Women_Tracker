/**
 * Backend API wrapper for Glow Wellness.
 * All data operations go through the Node.js/MongoDB backend.
 */

const API_BASE = 'http://localhost:8081/api';

const api = {
    // ─── Helper ──────────────────────────────────────────
    _headers() {
        const h = { 'Content-Type': 'application/json' };
        const token = session.getToken();
        if (token) h['x-auth-token'] = token;
        return h;
    },

    async _fetch(method, path, body) {
        try {
            const opts = { method, headers: this._headers() };
            if (body) opts.body = JSON.stringify(body);
            const res = await fetch(`${API_BASE}${path}`, opts);
            const text = await res.text();
            let data = {};
            if (text) {
                try {
                    data = JSON.parse(text);
                } catch {
                    data = { msg: text };
                }
            }
            if (res.status === 401) {
                const hadToken = !!session.getToken();
                const isCredentialExchange =
                    path === '/auth/login' ||
                    path === '/auth/register' ||
                    path === '/auth/google' ||
                    path === '/auth/google-login' ||
                    path === '/auth/reset-password';
                if (hadToken && !isCredentialExchange) {
                    session.logout();
                    return {
                        ...data,
                        msg: data.message || data.msg || 'Session expired',
                    };
                }
                return data;
            }
            return data;
        } catch (error) {
            console.error(`API ${method} ${path}:`, error);
            return { msg: 'Network error — is the server running?' };
        }
    },

    async get(path) {
        return await this._fetch('GET', path);
    },

    // ─── AUTH ────────────────────────────────────────────
    async login(email, password) {
        const res = await this._fetch('POST', '/auth/login', { email, password });
        if (res.token) {
            session.storeUser({
                token: res.token,
                name: res.user?.name || 'Beautiful',
                email: res.user?.email || email,
                profile: res.user || {}
            });
        }
        return res;
    },

    async register(name, email, password) {
        const res = await this._fetch('POST', '/auth/register', { name, email, password });
        if (res.token) {
            session.storeUser({
                token: res.token,
                name: name,
                email: email,
                profile: res.user || {}
            });
        }
        return res;
    },

    async resetPassword(email) {
        return await this._fetch('POST', '/auth/reset-password', { email });
    },

    async googleLogin(idToken) {
        const res = await this._fetch('POST', '/auth/google-login', { idToken });
        if (res.token) {
            session.storeUser({
                token: res.token,
                name: res.user?.name || 'Glow member',
                email: res.user?.email || '',
                profile: res.user || {},
            });
        }
        return res;
    },

    async post(path, body) {
        return await this._fetch('POST', path, body);
    },

    // ─── PERIOD TRACKING ────────────────────────────────
    async getPeriodDays() {
        const res = await this._fetch('GET', '/tracking/period-days');
        return Array.isArray(res) ? res : [];
    },

    async togglePeriodDay(dateStr) {
        return await this._fetch('POST', '/tracking/period-days/toggle', { date: dateStr });
    },

    // ─── DAILY LOGS (Mood, Symptoms, Notes) ─────────────
    async saveLog(entry) {
        const dateStr = entry.date || new Date().toISOString().split('T')[0];
        const payload = {
            date: dateStr,
            mood: entry.mood || '',
            symptoms: entry.symptoms || [],
            notes: entry.notes || '',
            flow: entry.flow || '',
        };
        if (entry.energyLevel != null) payload.energyLevel = entry.energyLevel;
        if (entry.stressLevel != null) payload.stressLevel = entry.stressLevel;
        if (entry.sleepQuality != null) payload.sleepQuality = entry.sleepQuality;
        if (entry.cravingsNote != null) payload.cravingsNote = entry.cravingsNote;
        if (entry.anxietyNote != null) payload.anxietyNote = entry.anxietyNote;
        const res = await this._fetch('POST', '/tracking/logs', payload);
        if (res && !res.msg) return { success: true, ...res };
        return res;
    },

    /** @param {{ from?: string, to?: string }} [range]  YYYY-MM-DD */
    async getLogs(range) {
        let path = '/tracking/logs';
        if (range && (range.from || range.to)) {
            const q = new URLSearchParams();
            if (range.from) q.set('from', range.from);
            if (range.to) q.set('to', range.to);
            path += `?${q.toString()}`;
        }
        const res = await this._fetch('GET', path);
        return Array.isArray(res) ? res : [];
    },

    async deleteLog(dateStr) {
        return await this._fetch('DELETE', `/tracking/logs/${dateStr}`);
    },

    // ─── USER PROFILE ───────────────────────────────────
    async saveProfile(data) {
        const res = await this._fetch('POST', '/auth/profile', data);
        if (res && !res.msg) {
            const user = session.getUser();
            user.name = data.name || user.name;
            user.profile = { ...user.profile, ...data };
            session.storeUser(user);
            return { success: true, ...data };
        }
        return res || { msg: 'Failed to save' };
    },

    async getProfile() {
        const res = await this._fetch('GET', '/auth/profile');
        return res || {};
    },

    // ─── POINTS ──────────────────────────────────────────
    async awardPoints(points) {
        return await this._fetch('POST', '/auth/award-points', { points });
    },

    // ─── DR. NAJAT CHAT (same backend as Flutter `POST /api/chat`) ─────
    async getChatHistory() {
        const res = await this._fetch('GET', '/chat');
        return Array.isArray(res) ? res : [];
    },

    async sendChatMessage(payload, options = {}) {
        // Allow slow OpenAI/Gemini responses; must stay above typical provider latency.
        const timeoutMs = options.timeoutMs ?? 120000;
        const ctrl = new AbortController();
        const tid = setTimeout(() => ctrl.abort(), timeoutMs);
        try {
            const res = await fetch(`${API_BASE}/chat`, {
                method: 'POST',
                headers: this._headers(),
                body: JSON.stringify({
                    role: payload.role || 'user',
                    text: payload.text ?? '',
                    voiceUrl: payload.voiceUrl ?? null,
                }),
                signal: ctrl.signal,
            });
            clearTimeout(tid);
            if (res.status === 401) {
                session.logout();
                return { msg: 'Session expired' };
            }
            return await res.json();
        } catch (error) {
            clearTimeout(tid);
            if (error && error.name === 'AbortError') {
                return {
                    msg: 'Dr. Najaat did not finish in time (waited about two minutes). Check your network and that the Glow server is running, then try again.',
                };
            }
            console.error('Chat POST:', error);
            return { msg: 'Network error — is the server running?' };
        }
    },
};

// ─── SESSION HELPER ─────────────────────────────────────
const session = {
    storeUser(userData) {
        localStorage.setItem('glow_token', userData.token || '');
        localStorage.setItem('glow_user', JSON.stringify(userData));
        localStorage.setItem('glow_session_active', 'true');
    },
    getToken() {
        return localStorage.getItem('glow_token');
    },
    getUser() {
        return JSON.parse(localStorage.getItem('glow_user') || '{}');
    },
    isAuthenticated() {
        return localStorage.getItem('glow_session_active') === 'true' && !!localStorage.getItem('glow_token');
    },
    logout() {
        localStorage.removeItem('glow_token');
        localStorage.removeItem('glow_user');
        localStorage.removeItem('glow_session_active');
        window.location.href = 'login.html';
    }
};
