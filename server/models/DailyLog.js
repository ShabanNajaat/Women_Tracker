const mongoose = require('mongoose');

const DailyLogSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    date: {
        type: String, // YYYY-MM-DD
        required: true
    },
    mood: {
        type: String
    },
    symptoms: [String],
    energy: {
        type: Number
    },
    notes: {
        type: String
    },
    voiceNotePath: {
        type: String
    },
    lastUpdated: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('DailyLog', DailyLogSchema);
