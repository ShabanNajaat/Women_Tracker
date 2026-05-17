const mongoose = require('mongoose');

const periodDaySchema = new mongoose.Schema({
    userId: { type: String, required: true },
    date: { type: String, required: true }
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

periodDaySchema.virtual('id').get(function() {
    return this._id.toHexString();
});

module.exports = mongoose.model('PeriodDay', periodDaySchema);
