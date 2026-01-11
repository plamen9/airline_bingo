--------------------------------------------------------
--  DDL for Table BINGO_PLAYER_CARDS
--  Contains player's bingo card cells
--------------------------------------------------------

create table bingo_player_cards (
    id               number generated always as identity
   ,player_id        number              not null
   ,row_num          number(1)           not null
   ,col_num          number(1)           not null
   ,airline_id       number
   ,airline_name     varchar2(100 char)  not null
   ,is_marked        number(1)           default 0 not null
   ,is_free          number(1)           default 0 not null
   ,marked_at        timestamp
   ,constraint bingo_player_cards_pk primary key (id)
   ,constraint bingo_player_cards_player_fk foreign key (player_id)
        references bingo_players (id) on delete cascade
   ,constraint bingo_player_cards_airline_fk foreign key (airline_id)
        references bingo_airlines (id)
   ,constraint bingo_player_cards_cell_uk unique (player_id, row_num, col_num)
   ,constraint bingo_player_cards_row_ck check (row_num between 0 and 4)
   ,constraint bingo_player_cards_col_ck check (col_num between 0 and 4)
   ,constraint bingo_player_cards_marked_ck check (is_marked in (0, 1))
   ,constraint bingo_player_cards_free_ck check (is_free in (0, 1))
);

create index bingo_player_cards_player_idx on bingo_player_cards (player_id);
create index bingo_player_cards_airline_idx on bingo_player_cards (airline_id);

comment on table bingo_player_cards is 'Individual cells of player bingo cards';
comment on column bingo_player_cards.id is 'Primary key - auto-generated';
comment on column bingo_player_cards.player_id is 'Reference to the player';
comment on column bingo_player_cards.row_num is 'Row position (0-4)';
comment on column bingo_player_cards.col_num is 'Column position (0-4)';
comment on column bingo_player_cards.airline_id is 'Reference to airline (null for FREE cell)';
comment on column bingo_player_cards.airline_name is 'Airline name or FREE';
comment on column bingo_player_cards.is_marked is '1=Marked/Called, 0=Not marked';
comment on column bingo_player_cards.is_free is '1=Free center cell, 0=Regular';
