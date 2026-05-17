const mongoose = require('mongoose');

const logSchema = new mongoose.Schema({
    userId: { type: String, required: true },
    date: { type: String, required: true },
    moods: { type: [String], default: [] },
    symptoms: { type: [String], default: [] },
    energy: { type: String, default: 'Normal' },
    /** 1–5 daily energy check-in (numeric; distinct from legacy `energy` string). */
    energyLevel: { type: Number, min: 1, max: 5 },
    /** 1–5 stress intensity */
    stressLevel: { type: Number, min: 1, max: 5 },
    /** 1–5 sleep quality */
    sleepQuality: { type: Number, min: 1, max: 5 },
    cravingsNote: { type: String, default: '' },
    anxietyNote: { type: String, default: '' },
    period: { type: Boolean, default: false },
    notes: { type: String, default: '' },
    flow: { type: String, default: '' },
    audioUrl: { type: String, default: null },
    voiceNotePath: { type: String, default: null }
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

logSchema.virtual('id').get(function() {
    return this._id.toHexString();
});
logSchema.virtual('dateStr').get(function() {
    return this.date;
});

module.exports = mongoose.model('Log', logSchema);
