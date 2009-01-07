-module(data_writer).
-include("../include/egfs.hrl").
-export([handle_write/4]).

-define(STRIP_SIZE, 8192).

generate_write_reply()->
    {ok, Listen} = gen_tcp:listen(0, [binary, {packet, 2}, {active, true}]),
    {ok, IP_Addr} = get_local_addr(),
    {ok, Port} = inet:port(Listen),
    {ok, Listen, {ok, IP_Addr, Port}}.
    
handle_write(FileID, ChunkIndex, ChunkID, []) ->
    {ok, Listen, Reply} = generate_write_reply(),
    spawn(fun() -> write_process(FileID, ChunkIndex, ChunkID, Listen) end),
    Reply;
handle_write(FileID, ChunkIndex, ChunkID, [H|T]) ->
    {ok, Listen, Reply} = generate_write_reply(),
    Next = gen_server:call(H, {writechunk, FileID, ChunkIndex, chunkID, T}),
    {ok, _Next_IP, _Next_Port} = Next,
    spawn(fun() -> write_process(FileID, ChunkIndex, ChunkID, Listen, Next) end),
    Reply.


init_write_process(Listen) ->
    {ok, Socket} = gen_tcp:accept(Listen),
    gen_tcp:close(Listen),
    {ok, ListenData} = gen_tcp:listen(0, [binary, {packet, 2}, {active, true}]),
    Reply = inet:port(ListenData),
    gen_tcp:send(Socket, term_to_binary(Reply)),
    process_flag(trap_exit, true),
    Parent = self(),
    {ok, Socket, ListenData, Parent}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%            Write to Itself
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write_process_tail(FileID, ChunkIndex, ChunkID, Listen) ->
    {ok, Socket, ListenData, Parent} = init_write_process(Listen),
    Child = spawn_link(fun() -> receive_it_tail(Parent, ListenData, ChunkID) end),
    Result = loop_write_control_tail(Socket, Child, FileID, ChunkIndex, ChunkID, 0),
    write_aftercare(Result, ChunkID).

loop_write_control_tail(Socket, Child, FileID, ChunkIndex, ChunkID, State) ->
    receive
	{finish, Child, Len} ->
	    ?DEBUG("[~p, ~p]: write transfer finish, ~pBytes~n", [?MODULE, ?LINE, Len]),
	    {ok, Name} = get_file_name(ChunkID),
	    chunk_db:insert_chunk_info(ChunkID, FileID, Name, Len),
	    gen_tcp:send(Socket, term_to_binary({check, Len})),
	    wait_for_check_result(Socket);
	{error, Child, Why} ->
	    ?DEBUG("[~p, ~p]: data transfer error~p~n", [?MODULE, ?LINE, Why]),
	    {error, data_receive, Why};
	{tcp, Socket, Binary} ->
	    Term = binary_to_term(Binary),
	    case Term of 
		{stop, Why} ->
		    ?DEBUG("[data_server, ~p]: write stop msg from client.~n", [?LINE]),
		    Child ! {stop, self(), Why},
		    gen_tcp:close(Socket),
		    {ok, stop, "write stop from writer"};
		_Any ->
		    loop_write_control_tail(Socket, Child, FileID, ChunkIndex, ChunkID, State)
	    end;
	{tcp_closed, Socket} ->
	    ?DEBUG("[~p, ~p]: write control broken~n", [?MODULE, ?LINE]),
	    {error, write_control, "write control broken"};
	Any ->
	    ?DEBUG("[~p, ~p]: unkown msg ~p~n", [?MODULE, ?LINE, Any]),
	    loop_write_control_tail(Socket, Child, FileID, ChunkIndex, ChunkID, State)
    ok.

receive_it_tail(Parent, ListenData, ChkID) ->
    {ok, SocketData} = gen_tcp:accept(ListenData),
    gen_tcp:close(ListenData),
    {ok, Hdl} = get_file_handle(write, ChkID),
    loop_receive(Parent, SocketData, Hdl, 0),
    gen_tcp:close(SocketData).

loop_receive(Parent, SocketData, Hdl, Len) ->
    receive
	{tcp, SocketData, Binary} ->
	    Len2 = Len + size(Binary),
	    file:write(Hdl, Binary),
	    loop_receive(Parent, SocketData, Hdl, Len2);
	{tcp_closed, SocketData} ->
	    file:close(Hdl),
	    Parent ! {finish, self(), Len};
	{stop, Parent, _Why} ->
	    file:close(Hdl),
	    get_tcp:close(SocketData);
	Any ->
	    ?DEBUG("[data_server, ~p]:loop Any:~p~n", [?LINE, Any])
    end. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%            Relay Write
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
connect_to_next({ok, Next_IP, Next_Port}) ->
    {ok, NextSocket} = gen_tcp:connect(Next_IP, Next_Port, [binary, {packet, 2}, {active, true}]),
    receive 
	{tcp, NextSocket, Binary} ->
	    {ok, Next_DataPort} = binary_to_term(Binary),
	    Reply = {ok, NextSocket, Next_DataPort};
	Any ->
	    Reply = {error, "cann't get next data port", []}
    end;
    Reply.
	    
write_process(FileID, ChunkIndex, ChunkID, Listen, Next) ->
    {ok, Socket, ListenData, Parent} = init_write_process(Listen),
    {ok, NextSocket, Next_DataPort} = connect_to_next(Next),
    Child = spawn_link(fun() -> receive_it(Parent, ListenData, Next_DataPort, ChunkID) end),
    Result = loop_write_control(Socket, NextSocket, Child, FileID, ChunkIndex, ChunkID, 0),
    write_aftercare(Result, ChunkID),
    gen_tcp:close(NextSocket).

write_aftercare(Result, ChunkID) ->
    case Result of
	{ok, check} ->
	    ok;
	_Any ->
	    rm_pending_chunk(ChunkID),
	    chunk_db:remove_chunk_info(ChunkID)
    end.

loop_write_control(Socket, NextSocket, Child, FileID, ChunkIndex, ChunkID, State) ->
    receive
	{finish, Child, Len} ->
	    {ok, Name} = get_file_name(ChunkID),
	    chunk_db:insert_chunk_info(ChunkID, FileID, Name, Len),
	    %% Result = report_metaServer(FileID, ChunkIndex, ChunkID, Len),
	    Child ! {die, self()},
	    wait_for_check(Socket, NextSocket, ChunkID, Len, 0);
	{error, Child, Why} ->
	    ?DEBUG("[~p, ~p] error from child(data transfer) ~n", [?MODULE, ?LINE]),
	    rm_pending_chunk(ChunkID),
	    gen_tcp:send(Socket, term_to_binary({error, "data transfer error"})),
	    gen_tcp:send(NextSocket, term_to_binary({stop, "data transfer error"})),
	    gen_tcp:close(NextSocket),
	    Child ! {die, self()},
	    {error, data_receive, Why};
	{tcp, Socket, Binary} ->
	    gen_tcp:send(NextSocket, Binary),
	    loop_write_control(Socket, NextSocket, Child, FileID, ChunkIndex, ChunkID, State);
	{tcp, NextSocket, Binary} ->
	    gen_tcp:send(Socket, Binary),
	    loop_write_control(Socket, NextSocket, Child, FileID, ChunkIndex, ChunkID, State);
	{tcp_closed, Socket} ->
	    rm_pending_chunk(ChunkID),
	    gen_tcp:send(NextSocket, term_to_binary({stop, "data control error"})),
	    gen_tcp:close(NextSocket),
	    {error, control_socket, "control socket broken"};
	{tcp_closed, NextSocket} ->
	    %%rm_pending_chunk(ChunkID),
	    gen_tcp:send(Socket, term_to_binary({error, "next data control broken"})),
	    {error, next_control_socket, "next control socket broken"};
	Any ->
	    ?DEBUG("[~p, ~p] unkown control msg:~p ~n", [?MODULE, ?LINE, Any]),
	    loop_write_control(Socket, NextSocket, Child, FileID, ChunkIndex, ChunkID, State)
    end.

wait_for_check(Socket, NextSocket, ChunkID, Len, State) ->
    receive
	{tcp, NextSocket, Binary} ->
	    Term = binary_to_term(Binary),
	    Case Term of
		{check, Len} ->
		    Result = {ok, check},
		    gen_tcp:send(NextSocket, term_to_binary(Result)),
		    gen_tcp:send(Socket, Binary),
		    wait_for_check_result(Socket);
		_Other ->
		    Result = {error, check, "length error"},
		    gen_tcp:send(Socket, term_to_binary(Result)),
		    gen_tcp:send(NextSocket, term_to_binary(Result)),
		    Result
	    end;
	Any ->
	    wait_for_check(Socket, NextSocket, ChunkID, Len, State)
    end.

wait_for_check_result(Socket) ->
    receive
	{tcp, Socket, Binary} ->
	    Term = binary_to_term(Binary),
	    Case Term of
		{ok, check} ->
		    Term;
	        {error, check, Why} ->
		    Term;
		Other ->
		    {error, check, Other}
	    end;
	{tcp_closed, Socket} ->
	    {error, check, "broken socket"};
	Any ->
	    wait_for_check_result(Socket)
    end.

receive_it(Parent, ListenData, Next_IP, Next_DataPort, ChunkID) ->
    {ok, SocketData} = gen_tcp:accept(ListenData),
    gen_tcp:close(ListenData),
    {ok, Hdl} = get_file_handle(write, ChunkID),
    {ok, NextSocketData} = gen_tcp:connect(Next_IP, Next_DataPort, [binary, {packet, 2}, {active, true}]),
    loop_receive(Parent, SocketData, NextSocketData, Hdl, 0),
    gen_tcp:close(NextSocketData).

loop_receive(Parent, SocketData, NextSocketData, Hdl, Len) ->
    receive
	{tcp, SocketData, Binary} ->
	    Len2 = Len + size(Binary),
	    file:write(Hdl, Binary),
	    gen_tcp:send(NextSocketData, Binary),
	    loop_receive(Parent, SocketData, NextSocketData, Hdl, Len2);
	{tcp_closed, SocketData} ->
	    file:close(Hdl),
	    Parent ! {finish, self(), Len},
	    receive_death(Parent, NextSocketData, 0);
	{tcp_closed, NextSocketData} ->
	    ?DEBUG("[~p, ~p] next data socket broken ~n", [?MODULE, ?LINE]); 
	    file:close(Hdl),
	    Parent ! {error, self(), "next socket data closed"},
	    receive_death(Parent, NextSocketData, 0);
	Any ->
	    ?DEBUG("[~p, ~p] unknown: ~p~n", [?MODULE, ?LINE, Any]),
	    loop_receive(Parent, SocketData, NextSocketData, Hdl, Len);
    end.

receive_death(Parent, NextSocketData, State) ->
    receive
	{die, Parent} ->
	    gen_tcp:close(NextSocketData),
	    ?DEBUG("[~p, ~p] close next socket data~n", [?MODULE, ?LINE]); 
	Any ->
	    ?DEBUG("[~p, ~p] unknown when wait for death: ~p~n", [?MODULE, ?LINE, Any]),
	    receive_death(Parent, State)
    end.
	    
