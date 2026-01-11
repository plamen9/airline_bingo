create or replace package bingo_game_pkg as
    /**
    * @package bingo_game_pkg
    * @description Package for managing airline bingo game operations
    * @author Copilot
    * @version 1.0
    */

    /**
    * Creates a new game room
    * @param p_admin_id User ID of the admin creating the room
    * @param p_admin_name Display name of the admin
    * @param p_room_name Optional friendly name for the room
    * @param p_use_free_center Whether center cell should be FREE (1) or airline (0)
    * @return JSON with room details
    */
    function create_room(
        p_admin_id        in varchar2
       ,p_admin_name      in varchar2
       ,p_room_name       in varchar2 default null
       ,p_use_free_center in number   default 1
    ) return clob;

    /**
    * Gets room details
    * @param p_room_code Room code
    * @return JSON with room details
    */
    function get_room(
        p_room_code in varchar2
    ) return clob;

    /**
    * Player joins a room
    * @param p_room_code Room code to join
    * @param p_user_id User ID of the player
    * @param p_display_name Display name of the player
    * @return JSON with join result
    */
    function join_room(
        p_room_code    in varchar2
       ,p_user_id      in varchar2
       ,p_display_name in varchar2
    ) return clob;

    /**
    * Gets list of players in a room
    * @param p_room_code Room code
    * @return JSON array of players
    */
    function get_players(
        p_room_code in varchar2
    ) return clob;

    /**
    * Admin starts the game
    * @param p_room_code Room code
    * @param p_admin_id Admin user ID for validation
    * @return JSON with start result
    */
    function start_game(
        p_room_code in varchar2
       ,p_admin_id  in varchar2
    ) return clob;

    /**
    * Admin draws an airline
    * @param p_room_code Room code
    * @param p_admin_id Admin user ID for validation
    * @return JSON with drawn airline details
    */
    function draw_airline(
        p_room_code in varchar2
       ,p_admin_id  in varchar2
    ) return clob;

    /**
    * Gets player's bingo card
    * @param p_room_code Room code
    * @param p_user_id User ID
    * @return JSON with card details
    */
    function get_player_card(
        p_room_code in varchar2
       ,p_user_id   in varchar2
    ) return clob;

    /**
    * Gets drawn airlines history
    * @param p_room_code Room code
    * @return JSON array of drawn airlines
    */
    function get_drawn_airlines(
        p_room_code in varchar2
    ) return clob;

    /**
    * Player claims bingo - validates the claim
    * @param p_room_code Room code
    * @param p_user_id User ID claiming bingo
    * @return JSON with validation result
    */
    function claim_bingo(
        p_room_code in varchar2
       ,p_user_id   in varchar2
    ) return clob;

    /**
    * Admin resets the game
    * @param p_room_code Room code
    * @param p_admin_id Admin user ID for validation
    * @return JSON with reset result
    */
    function reset_game(
        p_room_code in varchar2
       ,p_admin_id  in varchar2
    ) return clob;

    /**
    * Removes a player from the room
    * @param p_room_code Room code
    * @param p_admin_id Admin user ID for validation
    * @param p_user_id User ID to remove
    * @return JSON with result
    */
    function kick_player(
        p_room_code in varchar2
       ,p_admin_id  in varchar2
       ,p_user_id   in varchar2
    ) return clob;

end bingo_game_pkg;
/
