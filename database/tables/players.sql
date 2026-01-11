--------------------------------------------------------
--  DDL for Table BINGO_PLAYERS
--  Contains player information per game room
--------------------------------------------------------

create table bingo_players (
    id               number generated always as identity
   ,room_id          number              not null
   ,user_id          varchar2(50 char)   not null
   ,display_name     varchar2(100 char)  not null
   ,is_admin         number(1)           default 0 not null
   ,is_active        number(1)           default 1 not null
   ,has_bingo        number(1)           default 0 not null
   ,joined_at        timestamp           default systimestamp not null
   ,constraint bingo_players_pk primary key (id)
   ,constraint bingo_players_room_fk foreign key (room_id)
        references bingo_game_rooms (id) on delete cascade
   ,constraint bingo_players_room_user_uk unique (room_id, user_id)
   ,constraint bingo_players_admin_ck check (is_admin in (0, 1))
   ,constraint bingo_players_active_ck check (is_active in (0, 1))
   ,constraint bingo_players_bingo_ck check (has_bingo in (0, 1))
);

create index bingo_players_room_idx on bingo_players (room_id);
create index bingo_players_user_idx on bingo_players (user_id);

comment on table bingo_players is 'Players participating in bingo game rooms';
comment on column bingo_players.id is 'Primary key - auto-generated';
comment on column bingo_players.room_id is 'Reference to the game room';
comment on column bingo_players.user_id is 'Unique user identifier';
comment on column bingo_players.display_name is 'Player display name';
comment on column bingo_players.is_admin is '1=Admin of room, 0=Regular player';
comment on column bingo_players.is_active is '1=Active, 0=Left/Kicked';
comment on column bingo_players.has_bingo is '1=Has achieved bingo, 0=Not yet';
