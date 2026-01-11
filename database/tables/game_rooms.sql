--------------------------------------------------------
--  DDL for Table BINGO_GAME_ROOMS
--  Contains game room information
--------------------------------------------------------

create table bingo_game_rooms (
    id               number generated always as identity
   ,room_code        varchar2(10 char)   not null
   ,room_name        varchar2(100 char)
   ,admin_id         varchar2(50 char)   not null
   ,status           varchar2(20 char)   default 'WAITING' not null
   ,winner_id        varchar2(50 char)
   ,max_players      number              default 20 not null
   ,use_free_center  number(1)           default 1 not null
   ,created_at       timestamp           default systimestamp not null
   ,started_at       timestamp
   ,ended_at         timestamp
   ,constraint bingo_game_rooms_pk primary key (id)
   ,constraint bingo_game_rooms_code_uk unique (room_code)
   ,constraint bingo_game_rooms_status_ck check (status in ('WAITING', 'STARTED', 'FINISHED', 'CANCELLED'))
   ,constraint bingo_game_rooms_free_ck check (use_free_center in (0, 1))
);

create index bingo_game_rooms_status_idx on bingo_game_rooms (status);
create index bingo_game_rooms_admin_idx on bingo_game_rooms (admin_id);

comment on table bingo_game_rooms is 'Game rooms for bingo sessions';
comment on column bingo_game_rooms.id is 'Primary key - auto-generated';
comment on column bingo_game_rooms.room_code is 'Short code for players to join';
comment on column bingo_game_rooms.room_name is 'Friendly name for the room';
comment on column bingo_game_rooms.admin_id is 'User ID of the room admin';
comment on column bingo_game_rooms.status is 'WAITING=Not started, STARTED=In progress, FINISHED=Complete, CANCELLED=Abandoned';
comment on column bingo_game_rooms.winner_id is 'User ID of the winner';
comment on column bingo_game_rooms.max_players is 'Maximum allowed players';
comment on column bingo_game_rooms.use_free_center is '1=Center cell is FREE, 0=Center is airline';
