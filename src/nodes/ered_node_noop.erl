-module(ered_node_noop).

-behaviour(ered_node).

-export([start/2]).
-export([handle_msg/2]).
-export([handle_event/2]).

%%
%% No Operation node that is used for all unknown types. It represents
%% a deadend for a message, it stops here.

-import(ered_nodes, [
    get_prop_value_from_map/2,
    get_prop_value_from_map/3,
    jstr/2,
    this_should_not_happen/2
]).
-import(ered_nodered_comm, [
    debug/3,
    node_status/5,
    unsupported/3,
    ws_from/1
]).

%%
%%
start(NodeDef, WsName) ->
    {ok, TypeStr} = maps:find(type, NodeDef),
    debug(WsName, create_data_for_debug(NodeDef, TypeStr), warning),
    ered_node:start(NodeDef, ?MODULE).

%% erlfmt:ignore equals and arrows should line up here.
create_data_for_debug(NodeDef,TypeStr) ->
    IdStr   = get_prop_value_from_map(id,   NodeDef),
    ZStr    = get_prop_value_from_map(z,    NodeDef),
    NameStr = get_prop_value_from_map(name, NodeDef, TypeStr),

    #{
       id       => IdStr,
       z        => ZStr,
       path     => ZStr,
       name     => NameStr,
       topic    => <<"">>,
       msg      => jstr("node type '~s' is not implemented", [TypeStr]),
       format   => <<"string">>
    }.

%%
%%
handle_event(_, NodeDef) ->
    NodeDef.

%%
%%
handle_incoming(NodeDef, Msg) ->
    {ok, IdStr} = maps:find(id, NodeDef),
    {ok, TypeStr} = maps:find(type, NodeDef),

    %%
    %% This output is for eunit testing. This does in fact does end
    %% up in the Node-RED frontend as a notice, but that's only
    %% because I changed the code after writing the initial comment.
    this_should_not_happen(
        NodeDef,
        io_lib:format(
            "Noop Node (incoming). Nothing Done for [~p](~p) ~p\n",
            [TypeStr, IdStr, Msg]
        )
    ),

    %%
    %% this output is for Node-RED frontend when doing unit testing
    %% inside node red.
    debug(ws_from(Msg), create_data_for_debug(NodeDef, TypeStr), warning),

    %%
    %% again for node red, show a status value for the corresponding node.
    node_status(ws_from(Msg), NodeDef, "type not implemented", "grey", "dot"),

    {handled, NodeDef, Msg}.

%%
%%
handle_outgoing(NodeDef, Msg) ->
    {ok, IdStr} = maps:find(id, NodeDef),
    {ok, TypeStr} = maps:find(type, NodeDef),

    %%
    %% This output is for eunit testing. This does in fact does end
    %% up in the Node-RED frontend as a notice, but that's only
    %% because I changed the code after writing the initial comment.
    this_should_not_happen(
        NodeDef,
        io_lib:format(
            "Noop Node (outgoing) Nothing Done for [~p](~p) ~p\n",
            [TypeStr, IdStr, Msg]
        )
    ),

    %%
    %% this output is for Node-RED frontend when doing unit testing
    %% inside node red.
    debug(ws_from(Msg), create_data_for_debug(NodeDef, TypeStr), warning),

    %%
    %% again for node red, show a status value for the corresponding node.
    node_status(ws_from(Msg), NodeDef, "type not implemented", "grey", "dot"),

    {handled, NodeDef, Msg}.

%%
%%
handle_msg({incoming, Msg}, NodeDef) ->
    handle_incoming(NodeDef, Msg);
handle_msg({outgoing, Msg}, NodeDef) ->
    handle_outgoing(NodeDef, Msg);
handle_msg(_, NodeDef) ->
    {unhandled, NodeDef}.
