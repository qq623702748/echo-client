%%%-------------------------------------------------------------------
%%% @author zhuchaodi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 四月 2017 14:35
%%%-------------------------------------------------------------------
-module(newclient).
-author("zhuchaodi").
-define(PORT,9527).

%% API
-export([start/2,handle_input/2,handle_recv/2, heart_beat_fun/2,print_data/1]).
-record(chat_record_p, {id, username, word}).
start(UserName,PassWord) ->
	{ok, Socket} = gen_tcp:connect("localhost", ?PORT,
		[binary, {packet, 4}]),
	io:format("connect success! ~p~n",[Socket]),
	ok = gen_tcp:send(Socket, term_to_binary({login, UserName, PassWord})),
	A={login, UserName, PassWord},
	io:format("data:~p ~p~n", [A, term_to_binary(A)]),
	spawn(?MODULE, handle_input, [Socket, UserName]),
	Pid = spawn(?MODULE, heart_beat_fun, [Socket, 0]),
	handle_recv(Socket, Pid).

handle_input(Socket, UserName) ->
	Data = io:get_line("info>"),
	Index = string:str(Data,":"),
	case Index of
		%表示此次只是单纯发言
		0 ->
			case gen_tcp:send(Socket, term_to_binary({send_msg,Data})) of
				ok ->
					handle_input(Socket, UserName);
				_  ->
					io:format("socket closed!~n"),
					gen_tcp:close(Socket)
			end;
		_ ->
			{Left, Right} = lists:split(Index, Data),
			case Left of
				"modify:" ->
					NewPassWord = string:substr(Right, 1, length(Right)-1),
					io:format("Left:~p Right:~p~n", [Left, NewPassWord]),
					case gen_tcp:send(Socket, term_to_binary({modify, UserName, NewPassWord})) of
							ok ->
							handle_input(Socket, UserName);
							_  ->
							io:format("socket closed!~n"),
							gen_tcp:close(Socket)
					end;
				"sendto:" ->
					NxtIndex = string:str(Right,":"),
					{Str1,Str2} = lists:split(NxtIndex, Right),
					{DestUser,Word} = {string:substr(Str1, 1, length(Str1)-1), string:substr(Str2, 1, length(Str2)-1)},
					case gen_tcp:send(Socket, term_to_binary({sendto, DestUser, Word})) of
						ok ->
							handle_input(Socket, UserName);
						_  ->
							io:format("socket closed!~n"),
							gen_tcp:close(Socket)
					end;
				"groupto:" ->
					NxtIndex = string:str(Right,":"),
					{Str1,Str2} = lists:split(NxtIndex, Right),
					{GroupId, Word} = {string:substr(Str1, 1, length(Str1)-1), string:substr(Str2, 1, length(Str2)-1)},
					case gen_tcp:send(Socket, term_to_binary({groupto, GroupId, Word})) of
						ok ->
							handle_input(Socket, UserName);
						_  ->
							io:format("socket closed!~n"),
							gen_tcp:close(Socket)
					end;
				"entergroup:" ->
					GroupId = string:substr(Right, 1, length(Right)-1),
					case gen_tcp:send(Socket, term_to_binary({enter_group, GroupId})) of
						ok ->
							handle_input(Socket, UserName);
						_  ->
							io:format("socket closed!~n"),
							gen_tcp:close(Socket)
					end;
				"leavegroup:" ->
					GroupId = string:substr(Right, 1, length(Right)-1),
					case gen_tcp:send(Socket, term_to_binary({leave_group, GroupId})) of
						ok ->
							handle_input(Socket, UserName);
						_  ->
							io:format("socket closed!~n"),
							gen_tcp:close(Socket)
					end;
				"get_world_chat_record:" ->
					case gen_tcp:send(Socket, term_to_binary(get_world_chat_record)) of
						ok ->
							handle_input(Socket, UserName);
						_  ->
							io:format("socket closed!~n"),
							gen_tcp:close(Socket)
					end
			end

	end.

%send_msg(Socket, Data)->
%	case gen_tcp:send(Socket,term_to_binary(Data)) of
%		ok -> handle_input(Socket);
%		_  ->
%			io:format("socket closed!~n"),
%			gen_tcp:close(Socket)
%	end.

handle_recv(Socket, Pid) ->
	receive
		{tcp, Socket, Bin} ->
			case binary_to_term(Bin) of
				{heart_beat_ack, _}->
					Pid ! {heart_beat_ack_success};
				{chat_record_ack, Data} ->
					print_data(Data);
				_ ->
					io:format("~p~n", [binary_to_term(Bin)])
			end,
			handle_recv(Socket, Pid);
		{error, _} ->
			io:format("error occur!~n"),
			gen_tcp:close(Socket);
		{tcp_closed, _} ->
			io:format("socket closed!~n"),
			gen_tcp:close(Socket)
	end.

heart_beat_fun(Socket, Cnt) when Cnt =< 5->
	case gen_tcp:send(Socket, term_to_binary({heart_beat_req, Cnt})) of
		ok ->
			heart_beat(Socket, Cnt);
		_  ->
			io:format("socket closed!~n"),
			gen_tcp:close(Socket)
	end;
heart_beat_fun(Socket, Cnt) ->
	io:format("heartbear find problem! socket close!Cnt:~p~n", [Cnt]),
	gen_tcp:close(Socket).

heart_beat(Socket, Cnt) ->
	receive
		{heart_beat_ack_success} ->
			%io:format("recv heart_beat_ack~n"),
			sleep(5000),
			heart_beat_fun(Socket, 0)
	after 2000 ->
		heart_beat_fun(Socket, 0)
		%heart_beat_fun(Socket, Cnt+1)
	end.

sleep(Sec) ->
	receive
		after Sec ->
			[]
	end.

print_data(Data) ->
	[io:format("record:~p [~p]:[~p]~n", [X#chat_record_p.id, X#chat_record_p.username, X#chat_record_p.word])|| X<-Data].