--------------------------------------------------------
--  Uninstall all Airline Bingo database objects
--  Run this script as the schema owner
--------------------------------------------------------

prompt Removing ORDS module...
begin
    ords.delete_module(p_module_name => 'bingo');
    commit;
exception
    when others then
        null; -- Module may not exist
end;
/

prompt Dropping tables...
drop table bingo_drawn_airlines cascade constraints purge;
drop table bingo_player_cards cascade constraints purge;
drop table bingo_players cascade constraints purge;
drop table bingo_game_rooms cascade constraints purge;
drop table bingo_airlines cascade constraints purge;

prompt Dropping packages...
drop package bingo_game_pkg;

prompt Uninstall complete!
