create or replace package body bingo_game_pkg as

    -- Private constants
    k_grid_size       constant pls_integer := 5;
    k_center_position constant pls_integer := 2;

    /**
    * Generates a unique room code
    * @return 6-character alphanumeric code
    */
    function generate_room_code return varchar2 is
        l_code      varchar2(6);
        l_exists    number;
    begin
        loop
            l_code := dbms_random.string('X', 6);
            
            select count(*)
              into l_exists
              from bingo_game_rooms
             where room_code = l_code;
            
            exit when l_exists = 0;
        end loop;
        
        return l_code;
    end generate_room_code;

    /**
    * Gets room ID from room code
    * @param p_room_code Room code
    * @return Room ID or null if not found
    */
    function get_room_id(p_room_code in varchar2) return number is
        l_room_id number;
    begin
        select id
          into l_room_id
          from bingo_game_rooms
         where room_code = p_room_code;
        
        return l_room_id;
    exception
        when no_data_found then
            return null;
    end get_room_id;

    /**
    * Gets player ID from room and user
    * @param p_room_id Room ID
    * @param p_user_id User ID
    * @return Player ID or null if not found
    */
    function get_player_id(
        p_room_id in number
       ,p_user_id in varchar2
    ) return number is
        l_player_id number;
    begin
        select id
          into l_player_id
          from bingo_players
         where room_id = p_room_id
           and user_id = p_user_id
           and is_active = 1;
        
        return l_player_id;
    exception
        when no_data_found then
            return null;
    end get_player_id;

    /**
    * Generates a random bingo card for a player
    * @param p_player_id Player ID
    * @param p_use_free_center Whether to use FREE center cell
    */
    procedure generate_player_card(
        p_player_id       in number
       ,p_use_free_center in number
    ) is
        type t_airlines is table of bingo_airlines%rowtype;
        l_airlines    t_airlines;
        l_shuffled    t_airlines := t_airlines();
        l_idx         pls_integer;
        l_temp        bingo_airlines%rowtype;
        l_cell_count  pls_integer := 0;
    begin
        -- Get all active airlines
        select *
          bulk collect into l_airlines
          from bingo_airlines
         where is_active = 1;
        
        -- Fisher-Yates shuffle
        l_shuffled := l_airlines;
        for i in reverse 2..l_shuffled.count loop
            l_idx := trunc(dbms_random.value(1, i + 1));
            l_temp := l_shuffled(i);
            l_shuffled(i) := l_shuffled(l_idx);
            l_shuffled(l_idx) := l_temp;
        end loop;
        
        -- Fill the 5x5 grid
        l_cell_count := 0;
        for l_row in 0..k_grid_size - 1 loop
            for l_col in 0..k_grid_size - 1 loop
                -- Check if this is center cell and should be FREE
                if l_row = k_center_position 
                   and l_col = k_center_position 
                   and p_use_free_center = 1 then
                    insert into bingo_player_cards (
                        player_id
                       ,row_num
                       ,col_num
                       ,airline_id
                       ,airline_name
                       ,is_marked
                       ,is_free
                       ,marked_at
                    ) values (
                        p_player_id
                       ,l_row
                       ,l_col
                       ,null
                       ,'FREE'
                       ,1  -- FREE cell is always marked
                       ,1
                       ,systimestamp
                    );
                else
                    l_cell_count := l_cell_count + 1;
                    insert into bingo_player_cards (
                        player_id
                       ,row_num
                       ,col_num
                       ,airline_id
                       ,airline_name
                       ,is_marked
                       ,is_free
                    ) values (
                        p_player_id
                       ,l_row
                       ,l_col
                       ,l_shuffled(l_cell_count).id
                       ,l_shuffled(l_cell_count).airline_name
                       ,0
                       ,0
                    );
                end if;
            end loop;
        end loop;
    end generate_player_card;

    /**
    * Checks if a player has bingo
    * @param p_player_id Player ID
    * @return 1 if bingo, 0 otherwise
    */
    function check_bingo(p_player_id in number) return number is
        l_has_bingo number := 0;
        l_count     number;
    begin
        -- Check rows
        for l_row in 0..4 loop
            select count(*)
              into l_count
              from bingo_player_cards
             where player_id = p_player_id
               and row_num = l_row
               and is_marked = 1;
            
            if l_count = 5 then
                return 1;
            end if;
        end loop;
        
        -- Check columns
        for l_col in 0..4 loop
            select count(*)
              into l_count
              from bingo_player_cards
             where player_id = p_player_id
               and col_num = l_col
               and is_marked = 1;
            
            if l_count = 5 then
                return 1;
            end if;
        end loop;
        
        -- Check diagonal (top-left to bottom-right)
        select count(*)
          into l_count
          from bingo_player_cards
         where player_id = p_player_id
           and row_num = col_num
           and is_marked = 1;
        
        if l_count = 5 then
            return 1;
        end if;
        
        -- Check diagonal (top-right to bottom-left)
        select count(*)
          into l_count
          from bingo_player_cards
         where player_id = p_player_id
           and row_num + col_num = 4
           and is_marked = 1;
        
        if l_count = 5 then
            return 1;
        end if;
        
        return 0;
    end check_bingo;

    -- Public function implementations

    function create_room(
        p_admin_id        in varchar2
       ,p_admin_name      in varchar2
       ,p_room_name       in varchar2 default null
       ,p_use_free_center in number   default 1
    ) return clob is
        l_room_code varchar2(6);
        l_room_id   number;
        l_player_id number;
        l_result    json_object_t := json_object_t();
    begin
        l_room_code := generate_room_code();
        
        insert into bingo_game_rooms (
            room_code
           ,room_name
           ,admin_id
           ,use_free_center
        ) values (
            l_room_code
           ,nvl(p_room_name, 'Airline Bingo - ' || l_room_code)
           ,p_admin_id
           ,p_use_free_center
        ) returning id into l_room_id;
        
        -- Add admin as first player
        insert into bingo_players (
            room_id
           ,user_id
           ,display_name
           ,is_admin
        ) values (
            l_room_id
           ,p_admin_id
           ,p_admin_name
           ,1
        ) returning id into l_player_id;
        
        l_result.put('success', true);
        l_result.put('roomCode', l_room_code);
        l_result.put('roomId', l_room_id);
        l_result.put('playerId', l_player_id);
        l_result.put('message', 'Room created successfully');
        
        return l_result.to_clob();
    exception
        when others then
            l_result.put('success', false);
            l_result.put('error', sqlerrm);
            return l_result.to_clob();
    end create_room;

    function get_room(
        p_room_code in varchar2
    ) return clob is
        l_result json_object_t := json_object_t();
        r_room   bingo_game_rooms%rowtype;
    begin
        select *
          into r_room
          from bingo_game_rooms
         where room_code = p_room_code;
        
        l_result.put('success', true);
        l_result.put('roomId', r_room.id);
        l_result.put('roomCode', r_room.room_code);
        l_result.put('roomName', r_room.room_name);
        l_result.put('adminId', r_room.admin_id);
        l_result.put('status', r_room.status);
        l_result.put('winnerId', r_room.winner_id);
        l_result.put('useFreeCenter', r_room.use_free_center);
        
        return l_result.to_clob();
    exception
        when no_data_found then
            l_result.put('success', false);
            l_result.put('error', 'Room not found');
            return l_result.to_clob();
        when others then
            l_result.put('success', false);
            l_result.put('error', sqlerrm);
            return l_result.to_clob();
    end get_room;

    function join_room(
        p_room_code    in varchar2
       ,p_user_id      in varchar2
       ,p_display_name in varchar2
    ) return clob is
        l_result     json_object_t := json_object_t();
        l_room_id    number;
        l_player_id  number;
        l_status     varchar2(20);
        l_count      number;
        l_max        number;
    begin
        -- Get room
        select id, status, max_players
          into l_room_id, l_status, l_max
          from bingo_game_rooms
         where room_code = p_room_code;
        
        -- Check if game already started
        if l_status != 'WAITING' then
            l_result.put('success', false);
            l_result.put('error', 'Game has already started or finished');
            return l_result.to_clob();
        end if;
        
        -- Check if already joined
        select count(*)
          into l_count
          from bingo_players
         where room_id = l_room_id
           and user_id = p_user_id
           and is_active = 1;
        
        if l_count > 0 then
            -- Get existing player ID
            select id
              into l_player_id
              from bingo_players
             where room_id = l_room_id
               and user_id = p_user_id
               and is_active = 1;
            
            l_result.put('success', true);
            l_result.put('playerId', l_player_id);
            l_result.put('message', 'Already in room');
            return l_result.to_clob();
        end if;
        
        -- Check max players
        select count(*)
          into l_count
          from bingo_players
         where room_id = l_room_id
           and is_active = 1;
        
        if l_count >= l_max then
            l_result.put('success', false);
            l_result.put('error', 'Room is full');
            return l_result.to_clob();
        end if;
        
        -- Add player
        insert into bingo_players (
            room_id
           ,user_id
           ,display_name
        ) values (
            l_room_id
           ,p_user_id
           ,p_display_name
        ) returning id into l_player_id;
        
        l_result.put('success', true);
        l_result.put('playerId', l_player_id);
        l_result.put('message', 'Joined successfully');
        
        return l_result.to_clob();
    exception
        when no_data_found then
            l_result.put('success', false);
            l_result.put('error', 'Room not found');
            return l_result.to_clob();
        when others then
            l_result.put('success', false);
            l_result.put('error', sqlerrm);
            return l_result.to_clob();
    end join_room;

    function get_players(
        p_room_code in varchar2
    ) return clob is
        l_result  json_object_t := json_object_t();
        l_players json_array_t := json_array_t();
        l_player  json_object_t;
        l_room_id number;
    begin
        l_room_id := get_room_id(p_room_code);
        
        if l_room_id is null then
            l_result.put('success', false);
            l_result.put('error', 'Room not found');
            return l_result.to_clob();
        end if;
        
        for r in (
            select id
                  ,user_id
                  ,display_name
                  ,is_admin
                  ,has_bingo
              from bingo_players
             where room_id = l_room_id
               and is_active = 1
             order by is_admin desc, joined_at
        ) loop
            l_player := json_object_t();
            l_player.put('id', r.id);
            l_player.put('userId', r.user_id);
            l_player.put('displayName', r.display_name);
            l_player.put('isAdmin', r.is_admin);
            l_player.put('hasBingo', r.has_bingo);
            l_players.append(l_player);
        end loop;
        
        l_result.put('success', true);
        l_result.put('players', l_players);
        
        return l_result.to_clob();
    exception
        when others then
            l_result.put('success', false);
            l_result.put('error', sqlerrm);
            return l_result.to_clob();
    end get_players;

    function start_game(
        p_room_code in varchar2
       ,p_admin_id  in varchar2
    ) return clob is
        l_result          json_object_t := json_object_t();
        l_room_id         number;
        l_status          varchar2(20);
        l_admin           varchar2(50);
        l_use_free_center number;
    begin
        -- Get room info
        select id, status, admin_id, use_free_center
          into l_room_id, l_status, l_admin, l_use_free_center
          from bingo_game_rooms
         where room_code = p_room_code;
        
        -- Validate admin
        if l_admin != p_admin_id then
            l_result.put('success', false);
            l_result.put('error', 'Only admin can start the game');
            return l_result.to_clob();
        end if;
        
        -- Check status
        if l_status != 'WAITING' then
            l_result.put('success', false);
            l_result.put('error', 'Game already started or finished');
            return l_result.to_clob();
        end if;
        
        -- Generate cards for all players
        for r in (
            select id
              from bingo_players
             where room_id = l_room_id
               and is_active = 1
        ) loop
            generate_player_card(r.id, l_use_free_center);
        end loop;
        
        -- Update room status
        update bingo_game_rooms
           set status = 'STARTED'
              ,started_at = systimestamp
         where id = l_room_id;
        
        l_result.put('success', true);
        l_result.put('message', 'Game started');
        
        return l_result.to_clob();
    exception
        when no_data_found then
            l_result.put('success', false);
            l_result.put('error', 'Room not found');
            return l_result.to_clob();
        when others then
            l_result.put('success', false);
            l_result.put('error', sqlerrm);
            return l_result.to_clob();
    end start_game;

    function draw_airline(
        p_room_code in varchar2
       ,p_admin_id  in varchar2
    ) return clob is
        l_result       json_object_t := json_object_t();
        l_room_id      number;
        l_status       varchar2(20);
        l_admin        varchar2(50);
        l_airline_id   number;
        l_airline_name varchar2(100);
        l_draw_order   number;
        l_marked_count number := 0;
    begin
        -- Get room info
        select id, status, admin_id
          into l_room_id, l_status, l_admin
          from bingo_game_rooms
         where room_code = p_room_code;
        
        -- Validate admin
        if l_admin != p_admin_id then
            l_result.put('success', false);
            l_result.put('error', 'Only admin can draw airlines');
            return l_result.to_clob();
        end if;
        
        -- Check status
        if l_status != 'STARTED' then
            l_result.put('success', false);
            l_result.put('error', 'Game not in progress');
            return l_result.to_clob();
        end if;
        
        -- Get next draw order
        select nvl(max(draw_order), 0) + 1
          into l_draw_order
          from bingo_drawn_airlines
         where room_id = l_room_id;
        
        -- Pick random airline not yet drawn
        begin
            select id, airline_name
              into l_airline_id, l_airline_name
              from (
                  select a.id, a.airline_name
                    from bingo_airlines a
                   where a.is_active = 1
                     and not exists (
                         select 1
                           from bingo_drawn_airlines d
                          where d.room_id = l_room_id
                            and d.airline_id = a.id
                     )
                   order by dbms_random.value
              )
             where rownum = 1;
        exception
            when no_data_found then
                l_result.put('success', false);
                l_result.put('error', 'All airlines have been drawn');
                return l_result.to_clob();
        end;
        
        -- Record the draw
        insert into bingo_drawn_airlines (
            room_id
           ,airline_id
           ,airline_name
           ,draw_order
        ) values (
            l_room_id
           ,l_airline_id
           ,l_airline_name
           ,l_draw_order
        );
        
        -- Mark all matching cells for all players
        update bingo_player_cards
           set is_marked = 1
              ,marked_at = systimestamp
         where airline_id = l_airline_id
           and player_id in (
               select id
                 from bingo_players
                where room_id = l_room_id
                  and is_active = 1
           );
        
        l_marked_count := sql%rowcount;
        
        l_result.put('success', true);
        l_result.put('airlineId', l_airline_id);
        l_result.put('airlineName', l_airline_name);
        l_result.put('drawOrder', l_draw_order);
        l_result.put('markedCount', l_marked_count);
        
        return l_result.to_clob();
    exception
        when no_data_found then
            l_result.put('success', false);
            l_result.put('error', 'Room not found');
            return l_result.to_clob();
        when others then
            l_result.put('success', false);
            l_result.put('error', sqlerrm);
            return l_result.to_clob();
    end draw_airline;

    function get_player_card(
        p_room_code in varchar2
       ,p_user_id   in varchar2
    ) return clob is
        l_result    json_object_t := json_object_t();
        l_card      json_array_t := json_array_t();
        l_row       json_array_t;
        l_cell      json_object_t;
        l_room_id   number;
        l_player_id number;
        l_has_bingo number;
    begin
        l_room_id := get_room_id(p_room_code);
        
        if l_room_id is null then
            l_result.put('success', false);
            l_result.put('error', 'Room not found');
            return l_result.to_clob();
        end if;
        
        l_player_id := get_player_id(l_room_id, p_user_id);
        
        if l_player_id is null then
            l_result.put('success', false);
            l_result.put('error', 'Player not found');
            return l_result.to_clob();
        end if;
        
        -- Build card as 2D array
        for l_row_num in 0..4 loop
            l_row := json_array_t();
            for r in (
                select airline_name
                      ,is_marked
                      ,is_free
                  from bingo_player_cards
                 where player_id = l_player_id
                   and row_num = l_row_num
                 order by col_num
            ) loop
                l_cell := json_object_t();
                l_cell.put('airline', r.airline_name);
                l_cell.put('marked', r.is_marked);
                l_cell.put('free', r.is_free);
                l_row.append(l_cell);
            end loop;
            l_card.append(l_row);
        end loop;
        
        -- Check if player has bingo
        l_has_bingo := check_bingo(l_player_id);
        
        l_result.put('success', true);
        l_result.put('card', l_card);
        l_result.put('hasBingo', l_has_bingo);
        
        return l_result.to_clob();
    exception
        when others then
            l_result.put('success', false);
            l_result.put('error', sqlerrm);
            return l_result.to_clob();
    end get_player_card;

    function get_drawn_airlines(
        p_room_code in varchar2
    ) return clob is
        l_result   json_object_t := json_object_t();
        l_airlines json_array_t := json_array_t();
        l_airline  json_object_t;
        l_room_id  number;
    begin
        l_room_id := get_room_id(p_room_code);
        
        if l_room_id is null then
            l_result.put('success', false);
            l_result.put('error', 'Room not found');
            return l_result.to_clob();
        end if;
        
        for r in (
            select airline_id
                  ,airline_name
                  ,draw_order
              from bingo_drawn_airlines
             where room_id = l_room_id
             order by draw_order
        ) loop
            l_airline := json_object_t();
            l_airline.put('id', r.airline_id);
            l_airline.put('name', r.airline_name);
            l_airline.put('order', r.draw_order);
            l_airlines.append(l_airline);
        end loop;
        
        l_result.put('success', true);
        l_result.put('airlines', l_airlines);
        
        return l_result.to_clob();
    exception
        when others then
            l_result.put('success', false);
            l_result.put('error', sqlerrm);
            return l_result.to_clob();
    end get_drawn_airlines;

    function claim_bingo(
        p_room_code in varchar2
       ,p_user_id   in varchar2
    ) return clob is
        l_result    json_object_t := json_object_t();
        l_room_id   number;
        l_player_id number;
        l_status    varchar2(20);
        l_has_bingo number;
        l_name      varchar2(100);
    begin
        -- Get room
        select id, status
          into l_room_id, l_status
          from bingo_game_rooms
         where room_code = p_room_code;
        
        if l_status != 'STARTED' then
            l_result.put('success', false);
            l_result.put('error', 'Game not in progress');
            return l_result.to_clob();
        end if;
        
        l_player_id := get_player_id(l_room_id, p_user_id);
        
        if l_player_id is null then
            l_result.put('success', false);
            l_result.put('error', 'Player not found');
            return l_result.to_clob();
        end if;
        
        -- Validate bingo
        l_has_bingo := check_bingo(l_player_id);
        
        if l_has_bingo = 0 then
            l_result.put('success', false);
            l_result.put('error', 'Invalid bingo claim');
            l_result.put('valid', false);
            return l_result.to_clob();
        end if;
        
        -- Get player name
        select display_name
          into l_name
          from bingo_players
         where id = l_player_id;
        
        -- Mark player as winner
        update bingo_players
           set has_bingo = 1
         where id = l_player_id;
        
        -- End game
        update bingo_game_rooms
           set status = 'FINISHED'
              ,winner_id = p_user_id
              ,ended_at = systimestamp
         where id = l_room_id;
        
        l_result.put('success', true);
        l_result.put('valid', true);
        l_result.put('winnerId', p_user_id);
        l_result.put('winnerName', l_name);
        l_result.put('message', l_name || ' wins!');
        
        return l_result.to_clob();
    exception
        when no_data_found then
            l_result.put('success', false);
            l_result.put('error', 'Room not found');
            return l_result.to_clob();
        when others then
            l_result.put('success', false);
            l_result.put('error', sqlerrm);
            return l_result.to_clob();
    end claim_bingo;

    function reset_game(
        p_room_code in varchar2
       ,p_admin_id  in varchar2
    ) return clob is
        l_result  json_object_t := json_object_t();
        l_room_id number;
        l_admin   varchar2(50);
    begin
        select id, admin_id
          into l_room_id, l_admin
          from bingo_game_rooms
         where room_code = p_room_code;
        
        if l_admin != p_admin_id then
            l_result.put('success', false);
            l_result.put('error', 'Only admin can reset the game');
            return l_result.to_clob();
        end if;
        
        -- Delete player cards
        delete from bingo_player_cards
         where player_id in (
             select id
               from bingo_players
              where room_id = l_room_id
         );
        
        -- Delete drawn airlines
        delete from bingo_drawn_airlines
         where room_id = l_room_id;
        
        -- Reset player bingo status
        update bingo_players
           set has_bingo = 0
         where room_id = l_room_id;
        
        -- Reset room status
        update bingo_game_rooms
           set status = 'WAITING'
              ,winner_id = null
              ,started_at = null
              ,ended_at = null
         where id = l_room_id;
        
        l_result.put('success', true);
        l_result.put('message', 'Game reset successfully');
        
        return l_result.to_clob();
    exception
        when no_data_found then
            l_result.put('success', false);
            l_result.put('error', 'Room not found');
            return l_result.to_clob();
        when others then
            l_result.put('success', false);
            l_result.put('error', sqlerrm);
            return l_result.to_clob();
    end reset_game;

    function kick_player(
        p_room_code in varchar2
       ,p_admin_id  in varchar2
       ,p_user_id   in varchar2
    ) return clob is
        l_result    json_object_t := json_object_t();
        l_room_id   number;
        l_admin     varchar2(50);
        l_player_id number;
    begin
        select id, admin_id
          into l_room_id, l_admin
          from bingo_game_rooms
         where room_code = p_room_code;
        
        if l_admin != p_admin_id then
            l_result.put('success', false);
            l_result.put('error', 'Only admin can kick players');
            return l_result.to_clob();
        end if;
        
        if p_admin_id = p_user_id then
            l_result.put('success', false);
            l_result.put('error', 'Cannot kick yourself');
            return l_result.to_clob();
        end if;
        
        l_player_id := get_player_id(l_room_id, p_user_id);
        
        if l_player_id is null then
            l_result.put('success', false);
            l_result.put('error', 'Player not found');
            return l_result.to_clob();
        end if;
        
        -- Deactivate player
        update bingo_players
           set is_active = 0
         where id = l_player_id;
        
        l_result.put('success', true);
        l_result.put('message', 'Player removed');
        
        return l_result.to_clob();
    exception
        when no_data_found then
            l_result.put('success', false);
            l_result.put('error', 'Room not found');
            return l_result.to_clob();
        when others then
            l_result.put('success', false);
            l_result.put('error', sqlerrm);
            return l_result.to_clob();
    end kick_player;

end bingo_game_pkg;
/
