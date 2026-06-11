const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('./models/User');
const Friendship = require('./models/Friendship');
const DirectMessage = require('./models/DirectMessage');

// Store active users: userId -> socketId
const connectedUsers = new Map();

function initSocket(server) {
  const io = socketIo(server, {
    cors: {
      origin: '*', // Adjust for production
      methods: ['GET', 'POST']
    }
  });

  // Authentication Middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.query.token;
      if (!token) return next(new Error('Authentication error'));
      
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
      const user = await User.findById(decoded.id);
      if (!user) return next(new Error('User not found'));
      
      socket.user = user;
      next();
    } catch (err) {
      next(new Error('Authentication error'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`User connected: ${socket.user.username} (${socket.id})`);
    
    // Add to connected users
    connectedUsers.set(socket.user._id.toString(), socket.id);
    
    // Notify friends that user is online
    // This can be optimized later

    // Direct Messaging
    socket.on('send_message', async (data, callback) => {
      try {
        const { recipientId, text } = data;
        
        // Save to database
        const message = new DirectMessage({
          sender: socket.user._id,
          recipient: recipientId,
          text
        });
        await message.save();
        
        // Emit to recipient if online
        const recipientSocketId = connectedUsers.get(recipientId);
        if (recipientSocketId) {
          io.to(recipientSocketId).emit('receive_message', {
            _id: message._id,
            sender: socket.user._id,
            senderName: socket.user.username,
            text,
            createdAt: message.createdAt
          });
        }
        
        if (callback) callback({ status: 'ok', message });
      } catch (err) {
        if (callback) callback({ status: 'error', error: err.message });
      }
    });

    // Handle Disconnect
    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.user.username} (${socket.id})`);
      connectedUsers.delete(socket.user._id.toString());
    });
  });

  return io;
}

module.exports = { initSocket, connectedUsers };
