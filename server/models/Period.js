const mongoose = require('mongoose');

const PeriodSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    startDate: {
        type: String, // YYYY-MM-DD
        required: true
    },
    endDate: {
        type: String // YYYY-MM-DD
    },
    isPrediction: {
        type: Boolean,
        default: false
    }
});

module.exports = mongoose.model('Period', PeriodSchema);
