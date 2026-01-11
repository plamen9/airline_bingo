/**
 * Airline Bingo - Real-time Multiplayer Game Server
 * 
 * This server handles:
 * - HTTP API proxying to Oracle ORDS
 * - WebSocket connections for real-time updates
 * - Room management and player synchronization
 */

require('dotenv').config();

const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const path = require('path');

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST']
    }
});

// Configuration
const PORT = process.env.PORT || 3000;
const ORDS_BASE_URL = process.env.ORDS_BASE_URL || 'http://localhost:8080/ords/bingo_schema';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// In-memory room state for real-time sync
const rooms = new Map();

/**
 * Helper function to make ORDS API calls
 */
async function ordsRequest(endpoint, method = 'GET', body = null) {
    const url = `${ORDS_BASE_URL}/bingo/${endpoint}`;

    console.log('Calling ORDS:', url);
    
    const options = {
        method,
        headers: {
            'Content-Type': 'application/json'
        }
    };
    
    // Add Basic Auth if configured
    if (process.env.ORDS_AUTH_TYPE === 'basic' && process.env.ORDS_USERNAME) {
        const auth = Buffer.from(`${process.env.ORDS_USERNAME}:${process.env.ORDS_PASSWORD}`).toString('base64');
        options.headers['Authorization'] = `Basic ${auth}`;
    }
    
    if (body) {
        options.body = JSON.stringify(body);
    }
    
    try {
        const response = await fetch(url, options);
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('ORDS request failed:', error);
        throw error;
    }
}

// ============================================
// HTTP API Routes (proxy to ORDS)
// ============================================

/**
 * Create a new game room
 */
app.post('/api/rooms', async (req, res) => {
    try {
        const result = await ordsRequest('rooms', 'POST', req.body);
        
        if (result.success && result.roomCode) {
            rooms.set(result.roomCode, {
                players: new Map(),
                status: 'WAITING'
            });
        }
        
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Get room details
 */
app.get('/api/rooms/:roomCode', async (req, res) => {
    try {
        const result = await ordsRequest(`rooms/${req.params.roomCode}`);
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Join a room
 */
app.post('/api/rooms/:roomCode/join', async (req, res) => {
    try {
        const result = await ordsRequest(`rooms/${req.params.roomCode}/join`, 'POST', req.body);
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Get players in a room
 */
app.get('/api/rooms/:roomCode/players', async (req, res) => {
    try {
        const result = await ordsRequest(`rooms/${req.params.roomCode}/players`);
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Start game
 */
app.post('/api/rooms/:roomCode/start', async (req, res) => {
    try {
        const result = await ordsRequest(`rooms/${req.params.roomCode}/start`, 'POST', req.body);
        
        if (result.success) {
            const room = rooms.get(req.params.roomCode);
            if (room) {
                room.status = 'STARTED';
            }
            
            // Notify all players in the room
            io.to(req.params.roomCode).emit('gameStarted', result);
        }
        
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Draw an airline
 */
app.post('/api/rooms/:roomCode/draw', async (req, res) => {
    try {
        const result = await ordsRequest(`rooms/${req.params.roomCode}/draw`, 'POST', req.body);
        
        if (result.success) {
            // Broadcast drawn airline to all players
            io.to(req.params.roomCode).emit('airlineDrawn', {
                airlineId: result.airlineId,
                airlineName: result.airlineName,
                drawOrder: result.drawOrder
            });
        }
        
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Get player card
 */
app.get('/api/rooms/:roomCode/card/:userId', async (req, res) => {
    try {
        const result = await ordsRequest(`rooms/${req.params.roomCode}/card/${req.params.userId}`);
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Get drawn airlines
 */
app.get('/api/rooms/:roomCode/drawn', async (req, res) => {
    try {
        const result = await ordsRequest(`rooms/${req.params.roomCode}/drawn`);
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Claim bingo
 */
app.post('/api/rooms/:roomCode/claim', async (req, res) => {
    try {
        const result = await ordsRequest(`rooms/${req.params.roomCode}/claim`, 'POST', req.body);
        
        if (result.success && result.valid) {
            // Broadcast winner to all players
            io.to(req.params.roomCode).emit('bingoWinner', {
                winnerId: result.winnerId,
                winnerName: result.winnerName
            });
            
            const room = rooms.get(req.params.roomCode);
            if (room) {
                room.status = 'FINISHED';
            }
        }
        
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Reset game
 */
app.post('/api/rooms/:roomCode/reset', async (req, res) => {
    try {
        const result = await ordsRequest(`rooms/${req.params.roomCode}/reset`, 'POST', req.body);
        
        if (result.success) {
            const room = rooms.get(req.params.roomCode);
            if (room) {
                room.status = 'WAITING';
            }
            
            io.to(req.params.roomCode).emit('gameReset', result);
        }
        
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Kick player
 */
app.post('/api/rooms/:roomCode/kick', async (req, res) => {
    try {
        const result = await ordsRequest(`rooms/${req.params.roomCode}/kick`, 'POST', req.body);
        
        if (result.success) {
            io.to(req.params.roomCode).emit('playerKicked', {
                userId: req.body.userId
            });
        }
        
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ============================================
// Socket.IO Real-time Events
// ============================================

io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);
    
    /**
     * Player joins a room
     */
    socket.on('joinRoom', (data) => {
        const { roomCode, userId, displayName, isAdmin } = data;
        
        socket.join(roomCode);
        socket.roomCode = roomCode;
        socket.userId = userId;
        socket.displayName = displayName;
        socket.isAdmin = isAdmin;
        
        // Initialize room if needed
        if (!rooms.has(roomCode)) {
            rooms.set(roomCode, {
                players: new Map(),
                status: 'WAITING'
            });
        }
        
        const room = rooms.get(roomCode);
        room.players.set(socket.id, {
            socketId: socket.id,
            userId,
            displayName,
            isAdmin
        });
        
        // Notify others
        socket.to(roomCode).emit('playerJoined', {
            userId,
            displayName,
            isAdmin,
            playerCount: room.players.size
        });
        
        console.log(`${displayName} joined room ${roomCode}`);
    });
    
    /**
     * Player leaves room
     */
    socket.on('leaveRoom', () => {
        if (socket.roomCode) {
            const room = rooms.get(socket.roomCode);
            if (room) {
                room.players.delete(socket.id);
                
                socket.to(socket.roomCode).emit('playerLeft', {
                    userId: socket.userId,
                    displayName: socket.displayName,
                    playerCount: room.players.size
                });
            }
            
            socket.leave(socket.roomCode);
            console.log(`${socket.displayName} left room ${socket.roomCode}`);
        }
    });
    
    /**
     * Chat message
     */
    socket.on('chatMessage', (data) => {
        if (socket.roomCode) {
            io.to(socket.roomCode).emit('chatMessage', {
                userId: socket.userId,
                displayName: socket.displayName,
                message: data.message,
                timestamp: new Date().toISOString()
            });
        }
    });
    
    /**
     * Player claims potential bingo (for real-time notification)
     */
    socket.on('claimingBingo', () => {
        if (socket.roomCode) {
            socket.to(socket.roomCode).emit('playerClaimingBingo', {
                userId: socket.userId,
                displayName: socket.displayName
            });
        }
    });
    
    /**
     * Handle disconnect
     */
    socket.on('disconnect', () => {
        if (socket.roomCode) {
            const room = rooms.get(socket.roomCode);
            if (room) {
                room.players.delete(socket.id);
                
                socket.to(socket.roomCode).emit('playerDisconnected', {
                    userId: socket.userId,
                    displayName: socket.displayName,
                    playerCount: room.players.size
                });
            }
        }
        
        console.log('Client disconnected:', socket.id);
    });
});

// ============================================
// Start Server
// ============================================

httpServer.listen(PORT, () => {
    console.log(`🎰 Airline Bingo Server running on http://localhost:${PORT}`);
    console.log(`📡 ORDS endpoint: ${ORDS_BASE_URL}`);
});
