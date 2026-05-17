const mongoose = require('mongoose');

const amaSessionSchema = new mongoose.Schema(
    {
        expertSlug: { type: String, required: true, index: true },
        title: { type: String, required: true },
        description: { type: String, default: '' },
        topics: [{ type: String }],
        status: {
            type: String,
            enum: ['scheduled', 'live', 'ended'],
            default: 'scheduled',
            index: true,
        },
        startsAt: { type: Date, required: true },
        endsAt: { type: Date },
        questionCount: { type: Number, default: 0 },
        answeredCount: { type: Number, default: 0 },
    },
    { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

amaSessionSchema.virtual('id').get(function () {
    return this._id.toHexString();
});

module.exports = mongoose.model('AmaSession', amaSessionSchema);
