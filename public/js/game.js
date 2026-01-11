/**
 * Airline Bingo - Client-side Game Logic
 * 
 * Handles:
 * - User interface interactions
 * - API communication with server
 * - Real-time WebSocket events via Socket.IO
 * - Game state management
 */

(function() {
    'use strict';

    // ============================================
    // Configuration
    // ============================================
    
    const API_BASE = '/api';
    
    // ============================================
    // State Management
    // ============================================
    
    const state = {
        userId: null,
        displayName: null,
        roomCode: null,
        isAdmin: false,
        gameStatus: 'WAITING', // WAITING, STARTED, FINISHED
        card: null,
        drawnAirlines: [],
        players: [],
        hasBingo: false
    };

    // ============================================
    // DOM Elements
    // ============================================
    
    const screens = {
        landing: document.getElementById('landing-screen'),
        lobby: document.getElementById('lobby-screen'),
        game: document.getElementById('game-screen')
    };

    const elements = {
        // Landing
        playerName: document.getElementById('player-name'),
        btnCreateRoom: document.getElementById('btn-create-room'),
        btnJoinRoom: document.getElementById('btn-join-room'),
        joinModal: document.getElementById('join-modal'),
        roomCodeInput: document.getElementById('room-code-input'),
        btnJoinConfirm: document.getElementById('btn-join-confirm'),
        btnJoinCancel: document.getElementById('btn-join-cancel'),
        
        // Lobby
        displayRoomCode: document.getElementById('display-room-code'),
        btnCopyCode: document.getElementById('btn-copy-code'),
        lobbyPlayers: document.getElementById('lobby-players'),
        playerCount: document.getElementById('player-count'),
        useFreeCenter: document.getElementById('use-free-center'),
        adminOptions: document.getElementById('admin-options'),
        btnStartGame: document.getElementById('btn-start-game'),
        btnLeaveLobby: document.getElementById('btn-leave-lobby'),
        waitingMessage: document.getElementById('waiting-message'),
        
        // Game
        gameRoomCode: document.getElementById('game-room-code'),
        currentAirline: document.getElementById('current-airline'),
        drawCount: document.getElementById('draw-count'),
        drawnList: document.getElementById('drawn-list'),
        gamePlayers: document.getElementById('game-players'),
        gameAdminControls: document.getElementById('game-admin-controls'),
        btnDraw: document.getElementById('btn-draw'),
        btnResetGame: document.getElementById('btn-reset-game'),
        bingoGrid: document.getElementById('bingo-grid'),
        bingoStatus: document.getElementById('bingo-status'),
        btnClaimBingo: document.getElementById('btn-claim-bingo'),
        
        // Winner Modal
        winnerModal: document.getElementById('winner-modal'),
        winnerMessage: document.getElementById('winner-message'),
        btnPlayAgain: document.getElementById('btn-play-again'),
        btnExitGame: document.getElementById('btn-exit-game'),
        
        // Toast
        toastContainer: document.getElementById('toast-container')
    };

    // ============================================
    // Socket.IO Connection
    // ============================================
    
    let socket = null;

    function initSocket() {
        socket = io();
        
        socket.on('connect', () => {
            console.log('Connected to server');
        });
        
        socket.on('disconnect', () => {
            console.log('Disconnected from server');
            showToast('Connection lost. Trying to reconnect...', 'error');
        });
        
        socket.on('playerJoined', (data) => {
            showToast(`${data.displayName} joined the game`, 'info');
            refreshPlayers();
        });
        
        socket.on('playerLeft', (data) => {
            showToast(`${data.displayName} left the game`, 'info');
            refreshPlayers();
        });
        
        socket.on('playerDisconnected', (data) => {
            showToast(`${data.displayName} disconnected`, 'info');
            refreshPlayers();
        });
        
        socket.on('gameStarted', (data) => {
            showToast('Game started!', 'success');
            state.gameStatus = 'STARTED';
            loadPlayerCard();
            switchScreen('game');
        });
        
        socket.on('airlineDrawn', (data) => {
            handleAirlineDrawn(data);
        });
        
        socket.on('playerClaimingBingo', (data) => {
            showToast(`${data.displayName} is claiming BINGO!`, 'info');
        });
        
        socket.on('bingoWinner', (data) => {
            handleBingoWinner(data);
        });
        
        socket.on('gameReset', (data) => {
            showToast('Game has been reset', 'info');
            state.gameStatus = 'WAITING';
            state.card = null;
            state.drawnAirlines = [];
            state.hasBingo = false;
            switchScreen('lobby');
            refreshPlayers();
        });
        
        socket.on('playerKicked', (data) => {
            if (data.userId === state.userId) {
                showToast('You have been removed from the game', 'error');
                resetState();
                switchScreen('landing');
            } else {
                refreshPlayers();
            }
        });
    }

    // ============================================
    // API Functions
    // ============================================
    
    async function apiRequest(endpoint, method = 'GET', body = null) {
        const options = {
            method,
            headers: {
                'Content-Type': 'application/json'
            }
        };
        
        if (body) {
            options.body = JSON.stringify(body);
        }
        
        try {
            const response = await fetch(`${API_BASE}${endpoint}`, options);
            return await response.json();
        } catch (error) {
            console.error('API request failed:', error);
            throw error;
        }
    }

    async function createRoom() {
        const name = elements.playerName.value.trim();
        if (!name) {
            showToast('Please enter your name', 'error');
            return;
        }
        
        state.userId = generateUserId();
        state.displayName = name;
        state.isAdmin = true;
        
        try {
            const result = await apiRequest('/rooms', 'POST', {
                adminId: state.userId,
                adminName: state.displayName,
                useFreeCenter: 1
            });
            
            if (result.success) {
                state.roomCode = result.roomCode;
                
                // Join socket room
                socket.emit('joinRoom', {
                    roomCode: state.roomCode,
                    userId: state.userId,
                    displayName: state.displayName,
                    isAdmin: true
                });
                
                switchScreen('lobby');
                updateLobbyUI();
                refreshPlayers();
            } else {
                showToast(result.error || 'Failed to create room', 'error');
            }
        } catch (error) {
            showToast('Failed to create room', 'error');
        }
    }

    async function joinRoom(roomCode) {
        const name = elements.playerName.value.trim();
        if (!name) {
            showToast('Please enter your name', 'error');
            return;
        }
        
        state.userId = generateUserId();
        state.displayName = name;
        
        try {
            // First check if room exists
            const roomResult = await apiRequest(`/rooms/${roomCode}`);
            
            if (!roomResult.success) {
                showToast(roomResult.error || 'Room not found', 'error');
                return;
            }
            
            // Join the room
            const joinResult = await apiRequest(`/rooms/${roomCode}/join`, 'POST', {
                userId: state.userId,
                displayName: state.displayName
            });
            
            if (joinResult.success) {
                state.roomCode = roomCode;
                state.isAdmin = roomResult.adminId === state.userId;
                state.gameStatus = roomResult.status;
                
                // Join socket room
                socket.emit('joinRoom', {
                    roomCode: state.roomCode,
                    userId: state.userId,
                    displayName: state.displayName,
                    isAdmin: state.isAdmin
                });
                
                if (state.gameStatus === 'STARTED') {
                    // Game already in progress
                    await loadPlayerCard();
                    await loadDrawnAirlines();
                    switchScreen('game');
                } else {
                    switchScreen('lobby');
                    updateLobbyUI();
                    refreshPlayers();
                }
            } else {
                showToast(joinResult.error || 'Failed to join room', 'error');
            }
        } catch (error) {
            showToast('Failed to join room', 'error');
        }
    }

    async function startGame() {
        try {
            const result = await apiRequest(`/rooms/${state.roomCode}/start`, 'POST', {
                adminId: state.userId
            });
            
            if (result.success) {
                state.gameStatus = 'STARTED';
                await loadPlayerCard();
                switchScreen('game');
            } else {
                showToast(result.error || 'Failed to start game', 'error');
            }
        } catch (error) {
            showToast('Failed to start game', 'error');
        }
    }

    async function drawAirline() {
        try {
            const result = await apiRequest(`/rooms/${state.roomCode}/draw`, 'POST', {
                adminId: state.userId
            });
            
            if (!result.success) {
                showToast(result.error || 'Failed to draw airline', 'error');
            }
            // The socket event will handle the UI update
        } catch (error) {
            showToast('Failed to draw airline', 'error');
        }
    }

    async function loadPlayerCard() {
        try {
            const result = await apiRequest(`/rooms/${state.roomCode}/card/${state.userId}`);
            
            if (result.success) {
                state.card = result.card;
                state.hasBingo = result.hasBingo === 1;
                renderBingoCard();
                updateBingoButton();
            } else {
                showToast(result.error || 'Failed to load card', 'error');
            }
        } catch (error) {
            showToast('Failed to load card', 'error');
        }
    }

    async function loadDrawnAirlines() {
        try {
            const result = await apiRequest(`/rooms/${state.roomCode}/drawn`);
            
            if (result.success) {
                state.drawnAirlines = result.airlines || [];
                renderDrawnAirlines();
                updateCurrentAirline();
            }
        } catch (error) {
            console.error('Failed to load drawn airlines:', error);
        }
    }

    async function claimBingo() {
        socket.emit('claimingBingo');
        
        try {
            const result = await apiRequest(`/rooms/${state.roomCode}/claim`, 'POST', {
                userId: state.userId
            });
            
            if (result.success && result.valid) {
                // Winner modal will be shown via socket event
            } else if (result.success && !result.valid) {
                showToast('Invalid bingo claim!', 'error');
            } else {
                showToast(result.error || 'Failed to claim bingo', 'error');
            }
        } catch (error) {
            showToast('Failed to claim bingo', 'error');
        }
    }

    async function resetGame() {
        try {
            const result = await apiRequest(`/rooms/${state.roomCode}/reset`, 'POST', {
                adminId: state.userId
            });
            
            if (!result.success) {
                showToast(result.error || 'Failed to reset game', 'error');
            }
        } catch (error) {
            showToast('Failed to reset game', 'error');
        }
    }

    async function refreshPlayers() {
        try {
            const result = await apiRequest(`/rooms/${state.roomCode}/players`);
            
            if (result.success) {
                state.players = result.players || [];
                renderPlayers();
            }
        } catch (error) {
            console.error('Failed to refresh players:', error);
        }
    }

    // ============================================
    // Event Handlers
    // ============================================
    
    function handleAirlineDrawn(data) {
        // Add to drawn airlines
        state.drawnAirlines.push({
            id: data.airlineId,
            name: data.airlineName,
            order: data.drawOrder
        });
        
        // Update UI
        renderDrawnAirlines();
        updateCurrentAirline();
        
        // Mark cell on card
        markCellIfMatches(data.airlineName);
        
        // Check for bingo
        checkForBingo();
        
        showToast(`Drawn: ${data.airlineName}`, 'info');
    }

    function handleBingoWinner(data) {
        state.gameStatus = 'FINISHED';
        
        const isWinner = data.winnerId === state.userId;
        elements.winnerMessage.textContent = isWinner 
            ? 'Congratulations! You won!' 
            : `${data.winnerName} wins!`;
        
        elements.winnerModal.classList.remove('hidden');
        
        // Highlight winning cells
        highlightWinningCells();
    }

    function markCellIfMatches(airlineName) {
        if (!state.card) return;
        
        for (let row = 0; row < 5; row++) {
            for (let col = 0; col < 5; col++) {
                if (state.card[row][col].airline === airlineName) {
                    state.card[row][col].marked = 1;
                    
                    // Animate the cell
                    const cellIndex = row * 5 + col;
                    const cell = elements.bingoGrid.children[cellIndex];
                    if (cell) {
                        cell.classList.add('marked');
                    }
                }
            }
        }
    }

    function checkForBingo() {
        if (!state.card) return;
        
        const marked = state.card.map(row => 
            row.map(cell => cell.marked === 1 || cell.free === 1)
        );
        
        // Check rows
        for (let i = 0; i < 5; i++) {
            if (marked[i].every(Boolean)) {
                state.hasBingo = true;
                updateBingoButton();
                return;
            }
        }
        
        // Check columns
        for (let j = 0; j < 5; j++) {
            if (marked.every(row => row[j])) {
                state.hasBingo = true;
                updateBingoButton();
                return;
            }
        }
        
        // Check diagonals
        if (marked.every((row, i) => row[i])) {
            state.hasBingo = true;
            updateBingoButton();
            return;
        }
        
        if (marked.every((row, i) => row[4 - i])) {
            state.hasBingo = true;
            updateBingoButton();
            return;
        }
        
        state.hasBingo = false;
        updateBingoButton();
    }

    function highlightWinningCells() {
        if (!state.card) return;
        
        const marked = state.card.map(row => 
            row.map(cell => cell.marked === 1 || cell.free === 1)
        );
        
        const winningCells = [];
        
        // Check rows
        for (let i = 0; i < 5; i++) {
            if (marked[i].every(Boolean)) {
                for (let j = 0; j < 5; j++) {
                    winningCells.push(i * 5 + j);
                }
            }
        }
        
        // Check columns
        for (let j = 0; j < 5; j++) {
            if (marked.every(row => row[j])) {
                for (let i = 0; i < 5; i++) {
                    winningCells.push(i * 5 + j);
                }
            }
        }
        
        // Check diagonals
        if (marked.every((row, i) => row[i])) {
            for (let i = 0; i < 5; i++) {
                winningCells.push(i * 5 + i);
            }
        }
        
        if (marked.every((row, i) => row[4 - i])) {
            for (let i = 0; i < 5; i++) {
                winningCells.push(i * 5 + (4 - i));
            }
        }
        
        // Add winning class to cells
        winningCells.forEach(index => {
            const cell = elements.bingoGrid.children[index];
            if (cell) {
                cell.classList.add('winning');
            }
        });
    }

    // ============================================
    // UI Rendering
    // ============================================
    
    function switchScreen(screenName) {
        Object.values(screens).forEach(screen => {
            screen.classList.remove('active');
        });
        screens[screenName].classList.add('active');
        
        if (screenName === 'game') {
            updateGameUI();
        }
    }

    function updateLobbyUI() {
        elements.displayRoomCode.textContent = state.roomCode;
        
        if (state.isAdmin) {
            elements.adminOptions.classList.remove('hidden');
            elements.btnStartGame.classList.remove('hidden');
            elements.waitingMessage.classList.add('hidden');
        } else {
            elements.adminOptions.classList.add('hidden');
            elements.btnStartGame.classList.add('hidden');
            elements.waitingMessage.classList.remove('hidden');
        }
    }

    function updateGameUI() {
        elements.gameRoomCode.textContent = state.roomCode;
        
        if (state.isAdmin) {
            elements.gameAdminControls.classList.remove('hidden');
        } else {
            elements.gameAdminControls.classList.add('hidden');
        }
        
        renderBingoCard();
        renderDrawnAirlines();
        renderPlayers();
        updateCurrentAirline();
        updateBingoButton();
    }

    function renderPlayers() {
        const container = state.gameStatus === 'WAITING' 
            ? elements.lobbyPlayers 
            : elements.gamePlayers;
        
        container.innerHTML = '';
        
        state.players.forEach(player => {
            const li = document.createElement('li');
            
            if (state.gameStatus === 'WAITING') {
                li.innerHTML = `
                    <div class="player-avatar">${player.displayName.charAt(0).toUpperCase()}</div>
                    <span class="player-name">${player.displayName}</span>
                    ${player.isAdmin === 1 ? '<span class="admin-badge">Host</span>' : ''}
                `;
            } else {
                li.innerHTML = `
                    <span class="player-status"></span>
                    <span class="${player.hasBingo === 1 ? 'has-bingo' : ''}">${player.displayName}</span>
                    ${player.isAdmin === 1 ? '<span class="admin-badge">Host</span>' : ''}
                `;
            }
            
            container.appendChild(li);
        });
        
        if (elements.playerCount) {
            elements.playerCount.textContent = `(${state.players.length})`;
        }
    }

    function renderBingoCard() {
        elements.bingoGrid.innerHTML = '';
        
        if (!state.card) return;
        
        for (let row = 0; row < 5; row++) {
            for (let col = 0; col < 5; col++) {
                const cellData = state.card[row][col];
                const cell = document.createElement('div');
                cell.className = 'bingo-cell';
                cell.textContent = cellData.airline;
                
                if (cellData.free === 1) {
                    cell.classList.add('free', 'marked');
                } else if (cellData.marked === 1) {
                    cell.classList.add('marked');
                }
                
                elements.bingoGrid.appendChild(cell);
            }
        }
    }

    function renderDrawnAirlines() {
        elements.drawnList.innerHTML = '';
        
        // Show in reverse order (most recent first)
        const airlines = [...state.drawnAirlines].reverse();
        
        airlines.forEach(airline => {
            const li = document.createElement('li');
            li.innerHTML = `
                <span class="draw-number">#${airline.order}</span>
                <span>${airline.name}</span>
            `;
            elements.drawnList.appendChild(li);
        });
        
        elements.drawCount.textContent = `(${state.drawnAirlines.length})`;
    }

    function updateCurrentAirline() {
        if (state.drawnAirlines.length === 0) {
            elements.currentAirline.innerHTML = '<span class="waiting">Waiting for first draw...</span>';
        } else {
            const latest = state.drawnAirlines[state.drawnAirlines.length - 1];
            elements.currentAirline.innerHTML = `<span class="airline-name">${latest.name}</span>`;
        }
    }

    function updateBingoButton() {
        elements.btnClaimBingo.disabled = !state.hasBingo || state.gameStatus !== 'STARTED';
    }

    // ============================================
    // Utility Functions
    // ============================================
    
    function generateUserId() {
        return 'user_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    function showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;
        
        elements.toastContainer.appendChild(toast);
        
        setTimeout(() => {
            toast.remove();
        }, 4000);
    }

    function copyToClipboard(text) {
        navigator.clipboard.writeText(text).then(() => {
            showToast('Room code copied!', 'success');
        }).catch(() => {
            showToast('Failed to copy', 'error');
        });
    }

    function resetState() {
        state.userId = null;
        state.displayName = null;
        state.roomCode = null;
        state.isAdmin = false;
        state.gameStatus = 'WAITING';
        state.card = null;
        state.drawnAirlines = [];
        state.players = [];
        state.hasBingo = false;
        
        if (socket && state.roomCode) {
            socket.emit('leaveRoom');
        }
    }

    // ============================================
    // Event Listeners
    // ============================================
    
    function initEventListeners() {
        // Landing screen
        elements.btnCreateRoom.addEventListener('click', createRoom);
        
        elements.btnJoinRoom.addEventListener('click', () => {
            if (!elements.playerName.value.trim()) {
                showToast('Please enter your name first', 'error');
                return;
            }
            elements.joinModal.classList.remove('hidden');
            elements.roomCodeInput.focus();
        });
        
        elements.btnJoinConfirm.addEventListener('click', () => {
            const code = elements.roomCodeInput.value.trim().toUpperCase();
            if (code.length !== 6) {
                showToast('Please enter a valid 6-character code', 'error');
                return;
            }
            elements.joinModal.classList.add('hidden');
            joinRoom(code);
        });
        
        elements.btnJoinCancel.addEventListener('click', () => {
            elements.joinModal.classList.add('hidden');
            elements.roomCodeInput.value = '';
        });
        
        elements.roomCodeInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                elements.btnJoinConfirm.click();
            }
        });
        
        // Lobby screen
        elements.btnCopyCode.addEventListener('click', () => {
            copyToClipboard(state.roomCode);
        });
        
        elements.btnStartGame.addEventListener('click', startGame);
        
        elements.btnLeaveLobby.addEventListener('click', () => {
            resetState();
            switchScreen('landing');
        });
        
        // Game screen
        elements.btnDraw.addEventListener('click', drawAirline);
        
        elements.btnResetGame.addEventListener('click', () => {
            if (confirm('Are you sure you want to reset the game?')) {
                resetGame();
            }
        });
        
        elements.btnClaimBingo.addEventListener('click', claimBingo);
        
        // Winner modal
        elements.btnPlayAgain.addEventListener('click', () => {
            elements.winnerModal.classList.add('hidden');
            if (state.isAdmin) {
                resetGame();
            }
        });
        
        elements.btnExitGame.addEventListener('click', () => {
            elements.winnerModal.classList.add('hidden');
            resetState();
            switchScreen('landing');
        });
        
        // Enter key on player name
        elements.playerName.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                elements.btnCreateRoom.click();
            }
        });
    }

    // ============================================
    // Initialization
    // ============================================
    
    function init() {
        initSocket();
        initEventListeners();
        
        // Focus on name input
        elements.playerName.focus();
    }

    // Start the app when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
