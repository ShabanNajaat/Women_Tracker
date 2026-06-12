const mongoose = require('mongoose');

const friendshipSchema = new mongoose.Schema({
  requester: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  recipient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'rejected'],
    default: 'pending',
  },
}, { timestamps: true });

// Ensure a user cannot friend themselves (async hook - no next() needed)
friendshipSchema.pre('save', async function() {
  if (this.requester.equals(this.recipient)) {
    throw new Error('You cannot send a friend request to yourself.');
  }
});

// Ensure only one friendship doc exists between two users
friendshipSchema.index({ requester: 1, recipient: 1 }, { unique: true });

module.exports = mongoose.model('Friendship', friendshipSchema);
