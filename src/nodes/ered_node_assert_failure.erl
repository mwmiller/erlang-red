-module(ered_node_assert_failure).

-behaviour(ered_node).

-export([start/2]).
-export([handle_msg/2]).
-export([handle_event/2]).

%%
%% Assert node that fails if it receives a message. This is basically a node
%% that indicates paths that should not be reached.
%%

-import(ered_nodered_comm, [
    debug/3,
    node_status/5,
    ws_from/1
]).
-import(ered_nodes, [
    get_prop_value_from_map/2,
    get_prop_value_from_map/3,
    this_should_not_happen/2
]).

start(NodeDef, _WsName) ->
    ered_node:start(NodeDef, ?MODULE).

to_binary_if_not_binary(Obj) when is_binary(Obj) ->
    Obj;
to_binary_if_not_binary(Obj) when is_list(Obj) ->
    list_to_binary(Obj);
to_binary_if_not_binary(Obj) ->
    Obj.

%%
%%
handle_event({stop, WsName}, NodeDef) ->
    case maps:find('_mc_incoming', NodeDef) of
        {ok, 0} ->
            node_status(WsName, NodeDef, "assert succeed", "green", "ring");
        _ ->
            ignore
    end,
    NodeDef;
handle_event(_, NodeDef) ->
    NodeDef.

%% erlfmt:ignore equals and arrows should line up here.
handle_incoming(NodeDef,Msg) ->
    {ok, IdStr}   = maps:find(id,NodeDef),
    {ok, TypeStr} = maps:find(type,NodeDef),

    this_should_not_happen(
      NodeDef,
      io_lib:format(
        "Assert Error: Node should not have been reached [~p](~p) ~p\n",
        [TypeStr,IdStr,Msg])
    ),

    IdStr    = get_prop_value_from_map(id,    NodeDef),
    ZStr     = get_prop_value_from_map(z,     NodeDef),
    NameStr  = get_prop_value_from_map(name,  NodeDef, TypeStr),
    TopicStr = get_prop_value_from_map(topic, Msg, ""),

    Data = #{
             id       => IdStr,
             z        => ZStr,
             '_alias' => IdStr,
             path     => ZStr,
             name     => NameStr,
             topic    => to_binary_if_not_binary(TopicStr),
             msg      => Msg,
             format   => <<"object">>
            },

    debug(ws_from(Msg), Data, error),

    node_status(ws_from(Msg),NodeDef,"assert failed","red","dot"),

    {NodeDef, Msg}.

%%
%%
handle_msg({incoming, Msg}, NodeDef) ->
    {NodeDef2, Msg2} = handle_incoming(NodeDef, Msg),
    {handled, NodeDef2, Msg2};
handle_msg(_, NodeDef) ->
    {unhandled, NodeDef}.
