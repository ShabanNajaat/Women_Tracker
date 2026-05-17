const mongoose = require('mongoose');

const amaQuestionSchema = new mongoose.Schema(
    {
        sessionId: { type: String, required: true, index: true },
        userId: { type: String, required: true },
        authorName: { type: String, default: 'Glow member' },
        body: { type: String, required: true },
        status: {
            type: String,
            enum: ['pending', 'answered', 'hidden'],
            default: 'pending',
        },
        answer: { type: String, default: '' },
        answeredBySlug: { type: String, default: '' },
        answeredAt: { type: Date },
        upvoteCount: { type: Number, default: 0 },
    },
    { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

amaQuestionSchema.virtual('id').get(function () {
    return this._id.toHexString();
});

module.exports = mongoose.model('AmaQuestion', amaQuestionSchema);
