# Airline Bingo - Online Multiplayer Game

A real-time multiplayer bingo game featuring European airlines, built with Oracle Database, ORDS REST API, Node.js, and Socket.IO.

## Features

- **5x5 Bingo Grid** with 42 unique European airlines
- **Real-time Multiplayer** via WebSockets (Socket.IO)
- **Admin Role** - Draw airlines, manage game
- **Player Role** - View personal bingo card, auto-mark drawn airlines
- **Server-side Validation** - Anti-cheating measures
- **Unique Cards** - Each player gets a different randomized card

## Tech Stack

- **Database**: Oracle Database with ORDS REST API
- **Backend**: Node.js + Express + Socket.IO
- **Frontend**: HTML5 + CSS3 + Vanilla JavaScript
- **Real-time**: Socket.IO for WebSocket communication

## Project Structure

```
airline_bingo/
├── database/
│   ├── tables/           # Database table definitions
│   ├── packages/         # PL/SQL packages
│   └── ords/             # ORDS REST API setup
├── server/
│   ├── server.js         # Node.js server
│   └── package.json      # Node dependencies
└── public/
    ├── index.html        # Main game UI
    ├── css/
    │   └── style.css     # Game styles
    └── js/
        └── game.js       # Client-side game logic
```

## Setup Instructions

### 1. Database Setup

Run the SQL scripts in order:

```bash
# 1. Create tables
sqlcl user/pass@db @database/tables/airlines.sql
sqlcl user/pass@db @database/tables/game_rooms.sql
sqlcl user/pass@db @database/tables/players.sql
sqlcl user/pass@db @database/tables/player_cards.sql
sqlcl user/pass@db @database/tables/drawn_airlines.sql

# 2. Create packages
sqlcl user/pass@db @database/packages/bingo_game_pkg.pks
sqlcl user/pass@db @database/packages/bingo_game_pkg.pkb

# 3. Setup ORDS
sqlcl user/pass@db @database/ords/bingo_ords.sql
```

### 2. Server Setup

```bash
cd server
npm install
npm start
```

### 3. Access the Game

Open your browser to: `http://localhost:3000`

## Game Rules

1. Admin creates a game room
2. Players join with the room code
3. Admin starts the game - each player receives a unique 5x5 card
4. Admin draws airlines one at a time
5. Matching cells on player cards are auto-marked
6. First player to complete a line (horizontal, vertical, or diagonal) wins!

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/bingo/rooms | Create new game room |
| GET | /api/bingo/rooms/:id | Get room details |
| POST | /api/bingo/rooms/:id/join | Join a room |
| POST | /api/bingo/rooms/:id/start | Start the game |
| POST | /api/bingo/rooms/:id/draw | Draw an airline |
| GET | /api/bingo/players/:id/card | Get player's card |
| POST | /api/bingo/rooms/:id/claim-bingo | Claim bingo |

## Airlines Included

Wizzair, Ryanair, Easy Jet, Bulgaria Air, Air Serbia, Helvetic, Lufthansa, Austrian, Finnair, British Airways, Transavia, Tarom, Air France, KLM, Brussels Airlines, Iberia, Vueling, SAS Scandinavian Airlines, TAP Air Portugal, ITA Airways, Aegean Airlines, Turkish Airlines, LOT, Czech Airlines, Icelandair, Aer Lingus, Norwegian, Pegasus, Eurowings, Luxair, Croatia Airlines, Air Baltic, Condor, Discover Airlines, Volotea, Smartwings, Jet2.com, Flybe, Lauda, Buzz, Air Dolomiti, TUI

## License

MIT
