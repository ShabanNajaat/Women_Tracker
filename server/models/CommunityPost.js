const mongoose = require('mongoose');

const communityPostSchema = new mongoose.Schema(
    {
        userId: { type: String, required: true },
        authorName: { type: String, default: 'Glow member' },
        title: { type: String, required: true },
        body: { type: String, required: true },
        phaseRoom: {
            type: String,
            enum: ['menstrual', 'follicular', 'ovulatory', 'luteal'],
            index: true,
        },
        commentCount: { type: Number, default: 0 },
    },
    { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

communityPostSchema.virtual('id').get(function () {
    return this._id.toHexString();
});

module.exports = mongoose.model('CommunityPost', communityPostSchema);
