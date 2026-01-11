--------------------------------------------------------
--  DDL for Table BINGO_AIRLINES
--  Contains all airlines available for bingo games
--------------------------------------------------------

create table bingo_airlines (
    id               number generated always as identity
   ,airline_name     varchar2(100 char)  not null
   ,airline_code     varchar2(10 char)
   ,logo_url         varchar2(500 char)
   ,is_active        number(1)           default 1 not null
   ,created_at       timestamp           default systimestamp not null
   ,updated_at       timestamp           default systimestamp not null
   ,constraint bingo_airlines_pk primary key (id)
   ,constraint bingo_airlines_name_uk unique (airline_name)
   ,constraint bingo_airlines_active_ck check (is_active in (0, 1))
);

comment on table bingo_airlines is 'Master list of airlines for bingo games';
comment on column bingo_airlines.id is 'Primary key - auto-generated';
comment on column bingo_airlines.airline_name is 'Full name of the airline';
comment on column bingo_airlines.airline_code is 'IATA airline code';
comment on column bingo_airlines.logo_url is 'URL to airline logo image';
comment on column bingo_airlines.is_active is '1=Active, 0=Inactive';

-- Insert all airlines
insert into bingo_airlines (airline_name, airline_code) values ('Wizzair', 'W6');
insert into bingo_airlines (airline_name, airline_code) values ('Ryanair', 'FR');
insert into bingo_airlines (airline_name, airline_code) values ('Easy Jet', 'U2');
insert into bingo_airlines (airline_name, airline_code) values ('Bulgaria Air', 'FB');
insert into bingo_airlines (airline_name, airline_code) values ('Air Serbia', 'JU');
insert into bingo_airlines (airline_name, airline_code) values ('Helvetic', '2L');
insert into bingo_airlines (airline_name, airline_code) values ('Lufthansa', 'LH');
insert into bingo_airlines (airline_name, airline_code) values ('Austrian', 'OS');
insert into bingo_airlines (airline_name, airline_code) values ('Finnair', 'AY');
insert into bingo_airlines (airline_name, airline_code) values ('British Airways', 'BA');
insert into bingo_airlines (airline_name, airline_code) values ('Transavia', 'HV');
insert into bingo_airlines (airline_name, airline_code) values ('Tarom', 'RO');
insert into bingo_airlines (airline_name, airline_code) values ('Air France', 'AF');
insert into bingo_airlines (airline_name, airline_code) values ('KLM', 'KL');
insert into bingo_airlines (airline_name, airline_code) values ('Brussels Airlines', 'SN');
insert into bingo_airlines (airline_name, airline_code) values ('Iberia', 'IB');
insert into bingo_airlines (airline_name, airline_code) values ('Vueling', 'VY');
insert into bingo_airlines (airline_name, airline_code) values ('SAS Scandinavian Airlines', 'SK');
insert into bingo_airlines (airline_name, airline_code) values ('TAP Air Portugal', 'TP');
insert into bingo_airlines (airline_name, airline_code) values ('ITA Airways', 'AZ');
insert into bingo_airlines (airline_name, airline_code) values ('Aegean Airlines', 'A3');
insert into bingo_airlines (airline_name, airline_code) values ('Turkish Airlines', 'TK');
insert into bingo_airlines (airline_name, airline_code) values ('LOT', 'LO');
insert into bingo_airlines (airline_name, airline_code) values ('Czech Airlines', 'OK');
insert into bingo_airlines (airline_name, airline_code) values ('Icelandair', 'FI');
insert into bingo_airlines (airline_name, airline_code) values ('Aer Lingus', 'EI');
insert into bingo_airlines (airline_name, airline_code) values ('Norwegian', 'DY');
insert into bingo_airlines (airline_name, airline_code) values ('Pegasus', 'PC');
insert into bingo_airlines (airline_name, airline_code) values ('Eurowings', 'EW');
insert into bingo_airlines (airline_name, airline_code) values ('Luxair', 'LG');
insert into bingo_airlines (airline_name, airline_code) values ('Croatia Airlines', 'OU');
insert into bingo_airlines (airline_name, airline_code) values ('Air Baltic', 'BT');
insert into bingo_airlines (airline_name, airline_code) values ('Condor', 'DE');
insert into bingo_airlines (airline_name, airline_code) values ('Discover Airlines', '4Y');
insert into bingo_airlines (airline_name, airline_code) values ('Volotea', 'V7');
insert into bingo_airlines (airline_name, airline_code) values ('Smartwings', 'QS');
insert into bingo_airlines (airline_name, airline_code) values ('Jet2.com', 'LS');
insert into bingo_airlines (airline_name, airline_code) values ('Flybe', 'BE');
insert into bingo_airlines (airline_name, airline_code) values ('Lauda', 'OE');
insert into bingo_airlines (airline_name, airline_code) values ('Buzz', 'RR');
insert into bingo_airlines (airline_name, airline_code) values ('Air Dolomiti', 'EN');
insert into bingo_airlines (airline_name, airline_code) values ('TUI', 'X3');

commit;
