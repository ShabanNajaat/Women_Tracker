const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const User = require('./models/User');
const Log = require('./models/Log');
const PeriodDay = require('./models/PeriodDay');
const ChatMessage = require('./models/ChatMessage');
const CommunityPost = require('./models/CommunityPost');
const CommunityComment = require('./models/CommunityComment');
const AmaExpert = require('./models/AmaExpert');
const AmaSession = require('./models/AmaSession');
const AmaQuestion = require('./models/AmaQuestion');

// Zero-Setup In-Memory Store (Fallback for Presentation Mode)
const Store = {
    users: [],
    logs: [],
    periodDays: [],
    chatMessages: [],
    communityPosts: [],
    communityComments: [],
    amaExperts: [],
    amaSessions: [],
    amaQuestions: [],
    amaUpvotes: [],
    partnerNudges: [],
};

const MEMORY_USERS_FILE = path.join(__dirname, 'data', 'memory_users.json');

function loadMemoryUsersFromDisk() {
    if (mongoose.connection.readyState === 1) return;
    try {
        if (!fs.existsSync(MEMORY_USERS_FILE)) return;
        const raw = fs.readFileSync(MEMORY_USERS_FILE, 'utf8');
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) {
            Store.users = parsed;
            console.log(`[auth] Loaded ${Store.users.length} user(s) from memory_users.json`);
        }
    } catch (e) {
        console.warn('[auth] Could not load memory_users.json:', e.message);
    }
}

function persistMemoryUsersToDisk() {
    if (mongoose.connection.readyState === 1) return;
    try {
        const dir = path.dirname(MEMORY_USERS_FILE);
        if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
        fs.writeFileSync(MEMORY_USERS_FILE, JSON.stringify(Store.users, null, 2), 'utf8');
    } catch (e) {
        console.warn('[auth] Could not save memory_users.json:', e.message);
    }
}

function seedMemoryCommunityIfNeeded() {
    if (Store.communityPosts.length > 0) return;
    const now = new Date();
    Store.communityPosts.push({
        id: 'seed-welcome',
        _id: 'seed-welcome',
        userId: 'system',
        authorName: 'Glow Team',
        title: 'Welcome to Glow Community',
        body: 'This space uses your API: with MongoDB connected, posts and comments persist for every user. Without MongoDB the server uses in-memory storage until it restarts — see MONGO_URI in .env.example.',
        commentCount: 0,
        createdAt: now,
        updatedAt: now
    });
    Store.communityPosts.push({
        id: 'seed-tip',
        _id: 'seed-tip',
        userId: 'system',
        authorName: 'Glow Team',
        title: 'Tip: invite a friend',
        body: 'Share your invite code from Settings so your club can find you. Supportive comments help everyone feel seen.',
        commentCount: 0,
        createdAt: new Date(now.getTime() - 3600000),
        updatedAt: new Date(now.getTime() - 3600000)
    });
    const roomSeeds = [
        ['menstrual', 'Rest & restore room', 'A calm corner for cramps, fatigue, and self-compassion during your period.'],
        ['follicular', 'Rising energy room', 'Share wins as estrogen climbs — habits, focus, and gentle strength.'],
        ['ovulatory', 'Peak vitality room', 'Celebrate social energy, movement, and feeling your best.'],
        ['luteal', 'Gentle support room', 'PMS, cravings, and mood shifts — supportive peers, not medical advice.'],
    ];
    roomSeeds.forEach(([phaseRoom, title, body], i) => {
        Store.communityPosts.push({
            id: `seed-room-${phaseRoom}`,
            _id: `seed-room-${phaseRoom}`,
            userId: 'system',
            authorName: 'Glow Team',
            title,
            body,
            phaseRoom,
            commentCount: 0,
            createdAt: new Date(now.getTime() - (i + 2) * 3600000),
            updatedAt: new Date(now.getTime() - (i + 2) * 3600000),
        });
    });
}

seedMemoryCommunityIfNeeded();
loadMemoryUsersFromDisk();

function seedMemoryAmaIfNeeded() {
    if (Store.amaExperts.length > 0) return;
    const now = new Date();
    const inTwoDays = new Date(now.getTime() + 2 * 24 * 3600000);
    const inFiveDays = new Date(now.getTime() + 5 * 24 * 3600000);

    Store.amaExperts.push({
        id: 'expert-najaat',
        _id: 'expert-najaat',
        slug: 'dr-najaat',
        name: 'Dr. Najaat',
        title: 'Women\'s wellness educator',
        bio: 'Answers general cycle, mood, and lifestyle questions in plain language. Not a substitute for your own clinician or emergency care.',
        credentials: 'Wellness education · Glow advisor',
        avatarUrl: '',
        active: true,
        createdAt: now,
        updatedAt: now,
    });

    Store.amaSessions.push({
        id: 'ama-live-cycle',
        _id: 'ama-live-cycle',
        expertSlug: 'dr-najaat',
        title: 'Cycle & mood AMA',
        description: 'Ask about phases, PMS patterns, rest, nutrition, and when to seek in-person care. Educational only.',
        topics: ['cycle', 'mood', 'PMS', 'sleep'],
        status: 'live',
        startsAt: new Date(now.getTime() - 3600000),
        endsAt: inFiveDays,
        questionCount: 2,
        answeredCount: 1,
        createdAt: now,
        updatedAt: now,
    });

    Store.amaSessions.push({
        id: 'ama-scheduled-fertility',
        _id: 'ama-scheduled-fertility',
        expertSlug: 'dr-najaat',
        title: 'Fertility awareness Q&A',
        description: 'Upcoming session on tracking, fertile windows, and communicating with partners — general education.',
        topics: ['fertility', 'tracking', 'TTC'],
        status: 'scheduled',
        startsAt: inTwoDays,
        endsAt: null,
        questionCount: 0,
        answeredCount: 0,
        createdAt: now,
        updatedAt: now,
    });

    Store.amaSessions.push({
        id: 'ama-scheduled-pcos',
        _id: 'ama-scheduled-pcos',
        expertSlug: 'dr-najaat',
        title: 'PCOS lifestyle Q&A',
        description: 'Weekly-style webinar topics: cycles, insulin-friendly habits, and when to see a specialist.',
        topics: ['PCOS', 'cycles', 'nutrition'],
        status: 'scheduled',
        startsAt: inFiveDays,
        endsAt: null,
        questionCount: 0,
        answeredCount: 0,
        createdAt: now,
        updatedAt: now,
    });

    Store.amaSessions.push({
        id: 'ama-scheduled-pms',
        _id: 'ama-scheduled-pms',
        expertSlug: 'dr-najaat',
        title: 'PMS & mood support',
        description: 'Ask about irritability, cravings, sleep, and gentle coping tools in the luteal phase.',
        topics: ['PMS', 'mood', 'sleep'],
        status: 'scheduled',
        startsAt: new Date(now.getTime() + 3 * 24 * 3600000),
        endsAt: null,
        questionCount: 0,
        answeredCount: 0,
        createdAt: now,
        updatedAt: now,
    });

    Store.amaSessions.push({
        id: 'ama-scheduled-skin',
        _id: 'ama-scheduled-skin',
        expertSlug: 'dr-najaat',
        title: 'Hormonal acne & skin',
        description: 'Cycle-linked breakouts, skincare basics, and when dermatology may help.',
        topics: ['acne', 'skin', 'hormones'],
        status: 'scheduled',
        startsAt: new Date(now.getTime() + 4 * 24 * 3600000),
        endsAt: null,
        questionCount: 0,
        answeredCount: 0,
        createdAt: now,
        updatedAt: now,
    });

    Store.amaQuestions.push({
        id: 'q-seed-1',
        _id: 'q-seed-1',
        sessionId: 'ama-live-cycle',
        userId: 'system',
        authorName: 'Glow member',
        body: 'Why do I feel more anxious in the week before my period?',
        status: 'answered',
        answer:
            'Many people notice mood shifts in the luteal phase when progesterone rises and then falls. Tracking sleep, movement, and stress helps you spot patterns — share persistent or severe symptoms with a clinician you trust.',
        answeredBySlug: 'dr-najaat',
        answeredAt: now,
        upvoteCount: 12,
        createdAt: new Date(now.getTime() - 7200000),
        updatedAt: now,
    });

    Store.amaQuestions.push({
        id: 'q-seed-2',
        _id: 'q-seed-2',
        sessionId: 'ama-live-cycle',
        userId: 'system',
        authorName: 'Glow member',
        body: 'Is light exercise okay on heavy flow days?',
        status: 'pending',
        answer: '',
        answeredBySlug: '',
        answeredAt: null,
        upvoteCount: 5,
        createdAt: new Date(now.getTime() - 3600000),
        updatedAt: now,
    });
}

seedMemoryAmaIfNeeded();

// Generate a random 6-character code
function generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

const db = {
    // Helper to check if DB is connected
    isConnected() {
        return mongoose.connection.readyState === 1;
    },

    // User Operations
    normalizeEmail(email) {
        return String(email ?? '').trim().toLowerCase();
    },

    async findUserByEmail(email) {
        const e = this.normalizeEmail(email);
        if (!e) return null;
        if (this.isConnected()) return await User.findOne({ email: e });
        return Store.users.find((u) => this.normalizeEmail(u.email) === e);
    },

    async findUserByGoogleSub(sub) {
        if (!sub) return null;
        if (this.isConnected()) return await User.findOne({ googleSub: sub });
        return Store.users.find((u) => u.googleSub === sub);
    },

    async findUserByInviteCode(code) {
        if (!code) return null;
        if (this.isConnected()) return await User.findOne({ inviteCode: code.toUpperCase() });
        return Store.users.find(u => u.inviteCode === code.toUpperCase());
    },

    async findUserById(id) {
        if (this.isConnected()) {
            if (!mongoose.Types.ObjectId.isValid(id)) return null;
            return await User.findById(id);
        }
        return Store.users.find(u => u.id === id || u._id === id);
    },

    async saveUser(userData) {
        if (this.isConnected()) {
            if (userData.id || userData._id) {
                const userId = userData.id || userData._id;
                if (mongoose.Types.ObjectId.isValid(userId)) {
                    const raw =
                        typeof userData.toObject === 'function'
                            ? userData.toObject({ depopulate: true })
                            : { ...userData };
                    delete raw._id;
                    delete raw.__v;
                    delete raw.id;
                    return await User.findByIdAndUpdate(userId, raw, { new: true });
                }
            }
            const inviteCode = generateInviteCode();
            const user = new User({ ...userData, inviteCode });
            await user.save();
            return user;
        }
        // Memory fallback
        if (userData.id || userData._id) {
            const userId = userData.id || userData._id;
            const index = Store.users.findIndex(u => u.id === userId || u._id === userId);
            if (index !== -1) {
                const merged = { ...Store.users[index], ...userData };
                if (userData.email) merged.email = String(userData.email).trim().toLowerCase();
                Store.users[index] = merged;
                persistMemoryUsersToDisk();
                return Store.users[index];
            }
        }
        const newId = Math.random().toString(36).substring(7);
        const user = {
            _id: newId,
            id: newId,
            inviteCode: generateInviteCode(),
            email: userData.email ? String(userData.email).trim().toLowerCase() : userData.email,
            ...userData,
        };
        Store.users.push(user);
        persistMemoryUsersToDisk();
        return user;
    },

    // Daily Log Operations
    async findLogsByUserId(userId, range = {}) {
        const { from, to } = range;
        if (this.isConnected()) {
            const q = { userId };
            if (from || to) {
                q.date = {};
                if (from) q.date.$gte = from;
                if (to) q.date.$lte = to;
            }
            return await Log.find(q).sort({ date: -1 });
        }
        let logs = Store.logs.filter((l) => l.userId === userId);
        if (from || to) {
            logs = logs.filter(
                (l) => (!from || l.date >= from) && (!to || l.date <= to)
            );
        }
        return logs.sort((a, b) => b.date.localeCompare(a.date));
    },

    async saveLog(logData) {
        const { userId, date } = logData;
        if (this.isConnected()) {
            let log = await Log.findOne({ userId, date });
            if (log) {
                Object.assign(log, logData);
                await log.save();
                return log;
            } else {
                log = new Log(logData);
                await log.save();
                return log;
            }
        }
        // Memory fallback
        const index = Store.logs.findIndex(l => l.userId === userId && l.date === date);
        if (index !== -1) {
            Store.logs[index] = { ...Store.logs[index], ...logData };
            return Store.logs[index];
        }
        const newLog = { id: Math.random().toString(36).substring(7), ...logData };
        Store.logs.push(newLog);
        return newLog;
    },

    async getDailyLog(userId, date) {
        if (this.isConnected()) return await Log.findOne({ userId, date });
        return Store.logs.find(l => l.userId === userId && l.date === date);
    },

    async deleteLog(userId, id) {
        if (this.isConnected()) {
            if (!mongoose.Types.ObjectId.isValid(id)) return false;
            const result = await Log.deleteOne({ _id: id, userId });
            return result.deletedCount > 0;
        }
        const initialLen = Store.logs.length;
        Store.logs = Store.logs.filter(l => !(l.id === id && l.userId === userId));
        return Store.logs.length < initialLen;
    },

    // Period Day Operations
    async findPeriodDaysByUserId(userId) {
        if (this.isConnected()) return await PeriodDay.find({ userId }).sort({ date: 1 });
        return Store.periodDays.filter(p => p.userId === userId).sort((a,b) => a.date.localeCompare(b.date));
    },

    async togglePeriodDay(userId, date) {
        if (this.isConnected()) {
            const existing = await PeriodDay.findOne({ userId, date });
            if (existing) {
                await existing.deleteOne();
                return false;
            } else {
                const period = new PeriodDay({ userId, date });
                await period.save();
                return true;
            }
        }
        // Memory fallback
        const index = Store.periodDays.findIndex(p => p.userId === userId && p.date === date);
        if (index !== -1) {
            Store.periodDays.splice(index, 1);
            return false;
        }
        Store.periodDays.push({ id: Math.random().toString(36).substring(7), userId, date });
        return true;
    },

    async savePeriodRange(userId, dates) {
        if (this.isConnected()) {
            for (const date of dates) {
                const existing = await PeriodDay.findOne({ userId, date });
                if (!existing) {
                    const period = new PeriodDay({ userId, date });
                    await period.save();
                }
            }
            return;
        }
        // Memory fallback
        for (const date of dates) {
            if (!Store.periodDays.find(p => p.userId === userId && p.date === date)) {
                Store.periodDays.push({ id: Math.random().toString(36).substring(7), userId, date });
            }
        }
    },

    // Points Operations
    async awardPoints(userId, points) {
        if (this.isConnected()) {
            if (!mongoose.Types.ObjectId.isValid(userId)) return { glowPoints: 0 };
            const user = await User.findById(userId);
            if (user) {
                user.glowPoints = (user.glowPoints || 0) + points;
                await user.save();
                return user;
            }
            return { glowPoints: 0 };
        }
        const user = Store.users.find(u => u.id === userId || u._id === userId);
        if (user) {
            user.glowPoints = (user.glowPoints || 0) + points;
            return user;
        }
        return { glowPoints: 0 };
    },

    // Chat Operations
    async findChatMessages(userId) {
        if (this.isConnected()) return await ChatMessage.find({ userId }).sort({ timestamp: 1 });
        return Store.chatMessages.filter(m => m.userId === userId).sort((a,b) => a.timestamp - b.timestamp);
    },

    async saveChatMessage(msg) {
        const payload = {
            ...msg,
            timestamp: msg.timestamp != null ? msg.timestamp : Date.now(),
        };
        if ((payload.text === undefined || payload.text === null) && payload.parts && typeof payload.parts === 'object' && payload.parts.text != null) {
            payload.text = String(payload.parts.text);
        }
        if (this.isConnected()) {
            const chat = new ChatMessage(payload);
            await chat.save();
            return chat;
        }
        const newMsg = { id: Math.random().toString(36).substring(7), ...payload };
        Store.chatMessages.push(newMsg);
        return newMsg;
    },

    // Cycle Stats Helper
    async getCycleStats(userId) {
        let days;
        if (this.isConnected()) {
            const daysDocs = await PeriodDay.find({ userId }).sort({ date: 1 });
            days = daysDocs.map(d => d.date);
        } else {
            days = Store.periodDays.filter(p => p.userId === userId).sort((a,b) => a.date.localeCompare(b.date)).map(p => p.date);
        }
        
        if (days.length < 2) return { cycleLength: 28, periodLength: 5 };

        const getDaysDiff = (date1, date2) => {
            const d1 = new Date(date1);
            const d2 = new Date(date2);
            return Math.abs(Math.round((d1 - d2) / (1000 * 60 * 60 * 24)));
        };

        const starts = [];
        for (let i = 0; i < days.length; i++) {
            if (i === 0) { starts.push(days[i]); continue; }
            if (getDaysDiff(days[i], days[i-1]) > 2) {
                starts.push(days[i]);
            }
        }

        if (starts.length < 2) return { cycleLength: 28, periodLength: 5 };
        
        let totalCycle = 0;
        for (let i = 1; i < starts.length; i++) {
            totalCycle += getDaysDiff(starts[i], starts[i-1]);
        }
        
        const avgCycle = Math.round(totalCycle / (starts.length - 1));
        return { cycleLength: avgCycle || 28, periodLength: 5 };
    },

    // Community — posts
    async findCommunityPosts({ phaseRoom } = {}) {
        const filter = phaseRoom ? { phaseRoom } : {};
        if (this.isConnected()) {
            return await CommunityPost.find(filter).sort({ createdAt: -1 }).lean({ virtuals: true });
        }
        return [...Store.communityPosts]
            .filter((p) => !phaseRoom || p.phaseRoom === phaseRoom)
            .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
    },

    async findCommunityPostById(id) {
        if (!id) return null;
        if (this.isConnected()) {
            if (!mongoose.Types.ObjectId.isValid(id)) return null;
            return await CommunityPost.findById(id).lean({ virtuals: true });
        }
        return Store.communityPosts.find((p) => p.id === id || p._id === id);
    },

    async saveCommunityPost(data) {
        if (this.isConnected()) {
            const post = new CommunityPost(data);
            await post.save();
            return post;
        }
        const newId = Math.random().toString(36).substring(7);
        const now = new Date();
        const post = {
            id: newId,
            _id: newId,
            commentCount: 0,
            createdAt: now,
            updatedAt: now,
            ...data,
        };
        Store.communityPosts.push(post);
        return post;
    },

    async findCommunityComments(postId) {
        if (!postId) return [];
        if (this.isConnected()) {
            return await CommunityComment.find({ postId }).sort({ createdAt: 1 }).lean({ virtuals: true });
        }
        return Store.communityComments
            .filter((c) => c.postId === postId)
            .sort((a, b) => new Date(a.createdAt || 0) - new Date(b.createdAt || 0));
    },

    async saveCommunityComment(data) {
        if (this.isConnected()) {
            const comment = new CommunityComment(data);
            await comment.save();
            if (mongoose.Types.ObjectId.isValid(data.postId)) {
                await CommunityPost.findByIdAndUpdate(data.postId, { $inc: { commentCount: 1 } });
            }
            return comment;
        }
        const newId = Math.random().toString(36).substring(7);
        const now = new Date();
        const comment = {
            id: newId,
            _id: newId,
            createdAt: now,
            updatedAt: now,
            ...data,
        };
        Store.communityComments.push(comment);
        const post = Store.communityPosts.find((p) => p.id === data.postId || p._id === data.postId);
        if (post) post.commentCount = (post.commentCount || 0) + 1;
        return comment;
    },

    async seedAmaIfEmpty() {
        if (!this.isConnected()) return;
        const count = await AmaExpert.countDocuments();
        if (count > 0) return;
        const now = new Date();
        const inTwoDays = new Date(now.getTime() + 2 * 24 * 3600000);
        const inFiveDays = new Date(now.getTime() + 5 * 24 * 3600000);

        await AmaExpert.create({
            slug: 'dr-najaat',
            name: 'Dr. Najaat',
            title: 'Women\'s wellness educator',
            bio: 'Answers general cycle, mood, and lifestyle questions in plain language. Not a substitute for your own clinician or emergency care.',
            credentials: 'Wellness education · Glow advisor',
            active: true,
        });

        const live = await AmaSession.create({
            expertSlug: 'dr-najaat',
            title: 'Cycle & mood AMA',
            description: 'Ask about phases, PMS patterns, rest, nutrition, and when to seek in-person care. Educational only.',
            topics: ['cycle', 'mood', 'PMS', 'sleep'],
            status: 'live',
            startsAt: new Date(now.getTime() - 3600000),
            endsAt: inFiveDays,
            questionCount: 2,
            answeredCount: 1,
        });

        await AmaSession.create({
            expertSlug: 'dr-najaat',
            title: 'Fertility awareness Q&A',
            description: 'Upcoming session on tracking, fertile windows, and communicating with partners — general education.',
            topics: ['fertility', 'tracking', 'TTC'],
            status: 'scheduled',
            startsAt: inTwoDays,
        });

        const sessionId = live._id.toString();
        await AmaQuestion.create({
            sessionId,
            userId: 'seed',
            authorName: 'Glow member',
            body: 'Why do I feel more anxious in the week before my period?',
            status: 'answered',
            answer:
                'Many people notice mood shifts in the luteal phase when progesterone rises and then falls. Tracking sleep, movement, and stress helps you spot patterns — share persistent or severe symptoms with a clinician you trust.',
            answeredBySlug: 'dr-najaat',
            answeredAt: now,
            upvoteCount: 12,
        });
        await AmaQuestion.create({
            sessionId,
            userId: 'seed',
            authorName: 'Glow member',
            body: 'Is light exercise okay on heavy flow days?',
            status: 'pending',
            upvoteCount: 5,
        });
    },

    // Expert AMA
    async findAmaExperts() {
        if (this.isConnected()) {
            return await AmaExpert.find({ active: { $ne: false } }).sort({ name: 1 }).lean({ virtuals: true });
        }
        return [...Store.amaExperts].filter((e) => e.active !== false);
    },

    async findAmaExpertBySlug(slug) {
        if (!slug) return null;
        if (this.isConnected()) {
            return await AmaExpert.findOne({ slug }).lean({ virtuals: true });
        }
        return Store.amaExperts.find((e) => e.slug === slug);
    },

    async findAmaSessions({ status, expertSlug } = {}) {
        const filter = {};
        if (status) filter.status = status;
        if (expertSlug) filter.expertSlug = expertSlug;
        if (this.isConnected()) {
            return await AmaSession.find(filter).sort({ startsAt: -1 }).lean({ virtuals: true });
        }
        return Store.amaSessions
            .filter((s) => (!status || s.status === status) && (!expertSlug || s.expertSlug === expertSlug))
            .sort((a, b) => new Date(b.startsAt || 0) - new Date(a.startsAt || 0));
    },

    async findAmaSessionById(id) {
        if (!id) return null;
        if (this.isConnected()) {
            if (!mongoose.Types.ObjectId.isValid(id)) return null;
            return await AmaSession.findById(id).lean({ virtuals: true });
        }
        return Store.amaSessions.find((s) => s.id === id || s._id === id);
    },

    async saveAmaSession(data) {
        if (this.isConnected()) {
            const row = new AmaSession(data);
            await row.save();
            return row;
        }
        const newId = Math.random().toString(36).substring(7);
        const now = new Date();
        const session = {
            id: newId,
            _id: newId,
            questionCount: 0,
            answeredCount: 0,
            createdAt: now,
            updatedAt: now,
            ...data,
        };
        Store.amaSessions.push(session);
        return session;
    },

    async updateAmaSession(id, patch) {
        if (this.isConnected()) {
            if (!mongoose.Types.ObjectId.isValid(id)) return null;
            return await AmaSession.findByIdAndUpdate(id, patch, { new: true }).lean({ virtuals: true });
        }
        const i = Store.amaSessions.findIndex((s) => s.id === id || s._id === id);
        if (i < 0) return null;
        Store.amaSessions[i] = { ...Store.amaSessions[i], ...patch, updatedAt: new Date() };
        return Store.amaSessions[i];
    },

    async findAmaQuestions(sessionId, { sort } = {}) {
        if (!sessionId) return [];
        let rows;
        if (this.isConnected()) {
            rows = await AmaQuestion.find({ sessionId, status: { $ne: 'hidden' } }).lean({ virtuals: true });
        } else {
            rows = Store.amaQuestions.filter((q) => q.sessionId === sessionId && q.status !== 'hidden');
        }
        if (sort === 'recent') {
            rows.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
        } else {
            rows.sort((a, b) => {
                const uv = (b.upvoteCount || 0) - (a.upvoteCount || 0);
                if (uv !== 0) return uv;
                return new Date(b.createdAt || 0) - new Date(a.createdAt || 0);
            });
        }
        return rows;
    },

    async findAmaQuestionById(id) {
        if (!id) return null;
        if (this.isConnected()) {
            if (!mongoose.Types.ObjectId.isValid(id)) return null;
            return await AmaQuestion.findById(id).lean({ virtuals: true });
        }
        return Store.amaQuestions.find((q) => q.id === id || q._id === id);
    },

    async saveAmaQuestion(data) {
        if (this.isConnected()) {
            const row = new AmaQuestion(data);
            await row.save();
            if (mongoose.Types.ObjectId.isValid(data.sessionId)) {
                await AmaSession.findByIdAndUpdate(data.sessionId, { $inc: { questionCount: 1 } });
            }
            return row;
        }
        const newId = Math.random().toString(36).substring(7);
        const now = new Date();
        const question = {
            id: newId,
            _id: newId,
            status: 'pending',
            answer: '',
            answeredBySlug: '',
            answeredAt: null,
            upvoteCount: 0,
            createdAt: now,
            updatedAt: now,
            ...data,
        };
        Store.amaQuestions.push(question);
        const session = Store.amaSessions.find((s) => s.id === data.sessionId || s._id === data.sessionId);
        if (session) session.questionCount = (session.questionCount || 0) + 1;
        return question;
    },

    async upvoteAmaQuestion(questionId, userId) {
        const key = `${questionId}:${userId}`;
        if (Store.amaUpvotes.includes(key) && !this.isConnected()) {
            return this.findAmaQuestionById(questionId);
        }
        if (this.isConnected()) {
            const updated = await AmaQuestion.findByIdAndUpdate(
                questionId,
                { $inc: { upvoteCount: 1 } },
                { new: true }
            ).lean({ virtuals: true });
            return updated;
        }
        if (!Store.amaUpvotes.includes(key)) Store.amaUpvotes.push(key);
        const q = Store.amaQuestions.find((x) => x.id === questionId || x._id === questionId);
        if (q) q.upvoteCount = (q.upvoteCount || 0) + 1;
        return q;
    },

    async answerAmaQuestion(questionId, { answer, answeredBySlug }) {
        const patch = {
            answer,
            answeredBySlug,
            answeredAt: new Date(),
            status: 'answered',
        };
        if (this.isConnected()) {
            const prev = await AmaQuestion.findById(questionId).lean();
            const updated = await AmaQuestion.findByIdAndUpdate(questionId, patch, { new: true }).lean({
                virtuals: true,
            });
            if (prev && prev.status !== 'answered' && mongoose.Types.ObjectId.isValid(prev.sessionId)) {
                await AmaSession.findByIdAndUpdate(prev.sessionId, { $inc: { answeredCount: 1 } });
            }
            return updated;
        }
        const q = Store.amaQuestions.find((x) => x.id === questionId || x._id === questionId);
        if (!q) return null;
        const wasPending = q.status !== 'answered';
        Object.assign(q, patch, { updatedAt: new Date() });
        if (wasPending) {
            const session = Store.amaSessions.find((s) => s.id === q.sessionId || s._id === q.sessionId);
            if (session) session.answeredCount = (session.answeredCount || 0) + 1;
        }
        return q;
    },

    pushPartnerNudge(toUserId, fromUserId, fromName, message) {
        Store.partnerNudges = Store.partnerNudges.filter((n) => n.toUserId !== toUserId);
        Store.partnerNudges.push({
            id: `nudge-${Date.now()}`,
            toUserId,
            fromUserId,
            fromName: fromName || 'Your partner',
            message,
            read: false,
            createdAt: new Date().toISOString(),
        });
    },

    peekPartnerNudge(toUserId) {
        return Store.partnerNudges.find((n) => n.toUserId === toUserId && !n.read) || null;
    },

    markPartnerNudgeRead(toUserId) {
        Store.partnerNudges.forEach((n) => {
            if (n.toUserId === toUserId) n.read = true;
        });
    },
};

module.exports = db;
