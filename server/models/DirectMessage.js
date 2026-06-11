const mongoose = require('mongoose');

const directMessageSchema = new mongoose.Schema({
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  recipient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  text: {
    type: String,
    required: true,
  },
  read: {
    type: Boolean,
    default: false,
  },
}, { timestamps: true });

// Index for quick retrieval of conversation between two users
directMessageSchema.index({ sender: 1, recipient: 1, createdAt: -1 });

module.exports = mongoose.model('DirectMessage', directMessageSchema);
