const mongoose = require('mongoose');

const amaExpertSchema = new mongoose.Schema(
    {
        slug: { type: String, required: true, unique: true, trim: true },
        name: { type: String, required: true },
        title: { type: String, default: '' },
        bio: { type: String, default: '' },
        credentials: { type: String, default: '' },
        avatarUrl: { type: String, default: '' },
        active: { type: Boolean, default: true },
    },
    { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

amaExpertSchema.virtual('id').get(function () {
    return this._id.toHexString();
});

module.exports = mongoose.model('AmaExpert', amaExpertSchema);
