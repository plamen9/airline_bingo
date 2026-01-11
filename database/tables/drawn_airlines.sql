--------------------------------------------------------
--  DDL for Table BINGO_DRAWN_AIRLINES
--  Contains airlines drawn during a game
--------------------------------------------------------

create table bingo_drawn_airlines (
    id               number generated always as identity
   ,room_id          number              not null
   ,airline_id       number              not null
   ,airline_name     varchar2(100 char)  not null
   ,draw_order       number              not null
   ,drawn_at         timestamp           default systimestamp not null
   ,constraint bingo_drawn_airlines_pk primary key (id)
   ,constraint bingo_drawn_airlines_room_fk foreign key (room_id)
        references bingo_game_rooms (id) on delete cascade
   ,constraint bingo_drawn_airlines_airline_fk foreign key (airline_id)
        references bingo_airlines (id)
   ,constraint bingo_drawn_airlines_room_uk unique (room_id, airline_id)
   ,constraint bingo_drawn_airlines_order_uk unique (room_id, draw_order)
);

create index bingo_drawn_airlines_room_idx on bingo_drawn_airlines (room_id);

comment on table bingo_drawn_airlines is 'Airlines drawn during bingo games';
comment on column bingo_drawn_airlines.id is 'Primary key - auto-generated';
comment on column bingo_drawn_airlines.room_id is 'Reference to the game room';
comment on column bingo_drawn_airlines.airline_id is 'Reference to the airline drawn';
comment on column bingo_drawn_airlines.airline_name is 'Airline name at time of draw';
comment on column bingo_drawn_airlines.draw_order is 'Order in which airline was drawn';
