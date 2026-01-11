--------------------------------------------------------
--  ORDS REST API for Airline Bingo Game
--  Setup module, templates, and handlers
--------------------------------------------------------

declare
    l_modules     owa.vc_arr;
    l_module_exists boolean := false;
begin
    -- Check if module exists
    select name 
      bulk collect into l_modules
      from user_ords_modules 
     where name = 'bingo';
    
    l_module_exists := l_modules.count > 0;
    
    -- Only create module if it doesn't exist
    if not l_module_exists then
        ords.define_module(
            p_module_name    => 'bingo'
           ,p_base_path      => '/bingo/'
           ,p_items_per_page => 0
        );
    end if;

    -----------------------------------------------
    -- Create Room: POST /bingo/rooms
    -----------------------------------------------
    ords.define_template(
        p_module_name => 'bingo'
       ,p_pattern     => 'rooms'
    );
    
    ords.define_handler(
        p_module_name  => 'bingo'
       ,p_pattern      => 'rooms'
       ,p_method       => 'POST'
       ,p_source_type  => ords.source_type_plsql
       ,p_source       => 'declare
                              l_body    json_object_t;
                              l_result  clob;
                          begin
                              l_body := json_object_t.parse(:body_text);
                              
                              l_result := bingo_game_pkg.create_room(
                                  p_admin_id        => l_body.get_string(''adminId'')
                                 ,p_admin_name      => l_body.get_string(''adminName'')
                                 ,p_room_name       => l_body.get_string(''roomName'')
                                 ,p_use_free_center => nvl(l_body.get_number(''useFreeCenter''), 1)
                              );
                              
                              htp.p(l_result);
                              :status := 200;
                          end;'
    );

    -----------------------------------------------
    -- Get Room: GET /bingo/rooms/:code
    -----------------------------------------------
    ords.define_template(
        p_module_name => 'bingo'
       ,p_pattern     => 'rooms/:room_code'
    );
    
    ords.define_handler(
        p_module_name  => 'bingo'
       ,p_pattern      => 'rooms/:room_code'
       ,p_method       => 'GET'
       ,p_source_type  => ords.source_type_plsql
       ,p_source       => 'declare
                              l_result clob;
                          begin
                              l_result := bingo_game_pkg.get_room(:room_code);
                              htp.p(l_result);
                          end;'
    );

    -----------------------------------------------
    -- Join Room: POST /bingo/rooms/:code/join
    -----------------------------------------------
    ords.define_template(
        p_module_name => 'bingo'
       ,p_pattern     => 'rooms/:room_code/join'
    );
    
    ords.define_handler(
        p_module_name  => 'bingo'
       ,p_pattern      => 'rooms/:room_code/join'
       ,p_method       => 'POST'
       ,p_source_type  => ords.source_type_plsql
       ,p_source       => 'declare
                              l_body   json_object_t;
                              l_result clob;
                          begin
                              l_body := json_object_t.parse(:body_text);
                              
                              l_result := bingo_game_pkg.join_room(
                                  p_room_code    => :room_code
                                 ,p_user_id      => l_body.get_string(''userId'')
                                 ,p_display_name => l_body.get_string(''displayName'')
                              );
                              
                              htp.p(l_result);
                              :status := 200;
                          end;'
    );

    -----------------------------------------------
    -- Get Players: GET /bingo/rooms/:code/players
    -----------------------------------------------
    ords.define_template(
        p_module_name => 'bingo'
       ,p_pattern     => 'rooms/:room_code/players'
    );
    
    ords.define_handler(
        p_module_name  => 'bingo'
       ,p_pattern      => 'rooms/:room_code/players'
       ,p_method       => 'GET'
       ,p_source_type  => ords.source_type_plsql
       ,p_source       => 'declare
                              l_result clob;
                          begin
                              l_result := bingo_game_pkg.get_players(:room_code);
                              htp.p(l_result);
                          end;'
    );

    -----------------------------------------------
    -- Start Game: POST /bingo/rooms/:code/start
    -----------------------------------------------
    ords.define_template(
        p_module_name => 'bingo'
       ,p_pattern     => 'rooms/:room_code/start'
    );
    
    ords.define_handler(
        p_module_name  => 'bingo'
       ,p_pattern      => 'rooms/:room_code/start'
       ,p_method       => 'POST'
       ,p_source_type  => ords.source_type_plsql
       ,p_source       => 'declare
                              l_body   json_object_t;
                              l_result clob;
                          begin
                              l_body := json_object_t.parse(:body_text);
                              
                              l_result := bingo_game_pkg.start_game(
                                  p_room_code => :room_code
                                 ,p_admin_id  => l_body.get_string(''adminId'')
                              );
                              
                              htp.p(l_result);
                              :status := 200;
                          end;'
    );

    -----------------------------------------------
    -- Draw Airline: POST /bingo/rooms/:code/draw
    -----------------------------------------------
    ords.define_template(
        p_module_name => 'bingo'
       ,p_pattern     => 'rooms/:room_code/draw'
    );
    
    ords.define_handler(
        p_module_name  => 'bingo'
       ,p_pattern      => 'rooms/:room_code/draw'
       ,p_method       => 'POST'
       ,p_source_type  => ords.source_type_plsql
       ,p_source       => 'declare
                              l_body   json_object_t;
                              l_result clob;
                          begin
                              l_body := json_object_t.parse(:body_text);
                              
                              l_result := bingo_game_pkg.draw_airline(
                                  p_room_code => :room_code
                                 ,p_admin_id  => l_body.get_string(''adminId'')
                              );
                              
                              htp.p(l_result);
                              :status := 200;
                          end;'
    );

    -----------------------------------------------
    -- Get Player Card: GET /bingo/rooms/:code/card/:user_id
    -----------------------------------------------
    ords.define_template(
        p_module_name => 'bingo'
       ,p_pattern     => 'rooms/:room_code/card/:user_id'
    );
    
    ords.define_handler(
        p_module_name  => 'bingo'
       ,p_pattern      => 'rooms/:room_code/card/:user_id'
       ,p_method       => 'GET'
       ,p_source_type  => ords.source_type_plsql
       ,p_source       => 'declare
                              l_result clob;
                          begin
                              l_result := bingo_game_pkg.get_player_card(
                                  p_room_code => :room_code
                                 ,p_user_id   => :user_id
                              );
                              htp.p(l_result);
                          end;'
    );

    -----------------------------------------------
    -- Get Drawn Airlines: GET /bingo/rooms/:code/drawn
    -----------------------------------------------
    ords.define_template(
        p_module_name => 'bingo'
       ,p_pattern     => 'rooms/:room_code/drawn'
    );
    
    ords.define_handler(
        p_module_name  => 'bingo'
       ,p_pattern      => 'rooms/:room_code/drawn'
       ,p_method       => 'GET'
       ,p_source_type  => ords.source_type_plsql
       ,p_source       => 'declare
                              l_result clob;
                          begin
                              l_result := bingo_game_pkg.get_drawn_airlines(:room_code);
                              htp.p(l_result);
                          end;'
    );

    -----------------------------------------------
    -- Claim Bingo: POST /bingo/rooms/:code/claim
    -----------------------------------------------
    ords.define_template(
        p_module_name => 'bingo'
       ,p_pattern     => 'rooms/:room_code/claim'
    );
    
    ords.define_handler(
        p_module_name  => 'bingo'
       ,p_pattern      => 'rooms/:room_code/claim'
       ,p_method       => 'POST'
       ,p_source_type  => ords.source_type_plsql
       ,p_source       => 'declare
                              l_body   json_object_t;
                              l_result clob;
                          begin
                              l_body := json_object_t.parse(:body_text);
                              
                              l_result := bingo_game_pkg.claim_bingo(
                                  p_room_code => :room_code
                                 ,p_user_id   => l_body.get_string(''userId'')
                              );
                              
                              htp.p(l_result);
                              :status := 200;
                          end;'
    );

    -----------------------------------------------
    -- Reset Game: POST /bingo/rooms/:code/reset
    -----------------------------------------------
    ords.define_template(
        p_module_name => 'bingo'
       ,p_pattern     => 'rooms/:room_code/reset'
    );
    
    ords.define_handler(
        p_module_name  => 'bingo'
       ,p_pattern      => 'rooms/:room_code/reset'
       ,p_method       => 'POST'
       ,p_source_type  => ords.source_type_plsql
       ,p_source       => 'declare
                              l_body   json_object_t;
                              l_result clob;
                          begin
                              l_body := json_object_t.parse(:body_text);
                              
                              l_result := bingo_game_pkg.reset_game(
                                  p_room_code => :room_code
                                 ,p_admin_id  => l_body.get_string(''adminId'')
                              );
                              
                              htp.p(l_result);
                              :status := 200;
                          end;'
    );

    -----------------------------------------------
    -- Kick Player: POST /bingo/rooms/:code/kick
    -----------------------------------------------
    ords.define_template(
        p_module_name => 'bingo'
       ,p_pattern     => 'rooms/:room_code/kick'
    );
    
    ords.define_handler(
        p_module_name  => 'bingo'
       ,p_pattern      => 'rooms/:room_code/kick'
       ,p_method       => 'POST'
       ,p_source_type  => ords.source_type_plsql
       ,p_source       => 'declare
                              l_body   json_object_t;
                              l_result clob;
                          begin
                              l_body := json_object_t.parse(:body_text);
                              
                              l_result := bingo_game_pkg.kick_player(
                                  p_room_code => :room_code
                                 ,p_admin_id  => l_body.get_string(''adminId'')
                                 ,p_user_id   => l_body.get_string(''userId'')
                              );
                              
                              htp.p(l_result);
                              :status := 200;
                          end;'
    );

    commit;
end;
/
