const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema({
    userId: { type: String, required: true },
    role: { type: String, required: true },
    text: { type: String, default: '' },
    parts: { type: mongoose.Schema.Types.Mixed },
    voiceUrl: { type: String },
    timestamp: { type: Number, required: true }
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

chatMessageSchema.virtual('id').get(function() {
    return this._id.toHexString();
});

module.exports = mongoose.model('ChatMessage', chatMessageSchema);
