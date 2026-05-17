const mongoose = require('mongoose');

const communityCommentSchema = new mongoose.Schema(
    {
        postId: { type: String, required: true },
        userId: { type: String, required: true },
        authorName: { type: String, default: 'Glow member' },
        body: { type: String, required: true },
    },
    { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

communityCommentSchema.virtual('id').get(function () {
    return this._id.toHexString();
});

module.exports = mongoose.model('CommunityComment', communityCommentSchema);
