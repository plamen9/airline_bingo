--------------------------------------------------------
--  Install all Airline Bingo database objects
--  Run this script as the schema owner
--------------------------------------------------------

-- Create tables
prompt Creating tables...
@@tables/airlines.sql
@@tables/game_rooms.sql
@@tables/players.sql
@@tables/player_cards.sql
@@tables/drawn_airlines.sql

-- Create packages
prompt Creating packages...
@@packages/bingo_game_pkg.pks
@@packages/bingo_game_pkg.pkb

-- Setup ORDS REST API
prompt Setting up ORDS...
@@ords/bingo_ords.sql

prompt Installation complete!
