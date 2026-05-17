const mongoose = require('mongoose');

const profileSchema = new mongoose.Schema({
    cycleLength: { type: Number, default: 28 },
    periodLength: { type: Number, default: 5 },
    notifications: { type: mongoose.Schema.Types.Mixed },
}, { _id: false });

const userSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    name: { type: String },
    photo: { type: String },
    /** Required for email/password accounts; omitted or null for Google-only users */
    password: { type: String },
    profile: { type: profileSchema, default: () => ({}) },
    googleSub: { type: String, sparse: true, unique: true },
    glowPoints: { type: Number, default: 0 },
    inviteCode: { type: String },
    partnerUid: { type: String, default: null },
    /** Consecutive calendar days with a wellness check-in */
    dailyStreak: { type: Number, default: 0 },
    longestStreak: { type: Number, default: 0 },
    lastStreakDate: { type: String, default: null },
    lastStreakSharedAt: { type: String, default: null },
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// Create an alias 'id' for '_id' to match frontend expectations
userSchema.virtual('id').get(function() {
    return this._id.toHexString();
});

module.exports = mongoose.model('User', userSchema);
