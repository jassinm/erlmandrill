%%-----------------------------------
%% @author: locojay<locojaydev@gmail.com>
%% @doc: Mandrill erlang api
%% @end
%%-----------------------------------
-module(mandrill).

-export([start/0,
         stop/0,
         send_template/3,
         send_template/6,
         mandrill_call/2]).

-define(MANDRILL_MESSAGES_URL, "https://mandrillapp.com/api/1.0/").

-spec start() -> ok | {error, already_started, mandrill}.
start() ->
    _ = application:start(inets),
    _ = application:start(asn1),
    _ = application:start(crypto),
    _ = application:start(public_key),
    _ = application:start(ssl),
    lager:start(),
    application:start(mandrill).

-spec stop() -> ok.
stop() ->
    application:stop(mandrill).

%% @doc send a mandrill transactional email throught a template
-spec send_template(TemplateName::binary(),
                    TemplateContent::binary(),
                    Message::list(),
                    Async::boolean(),
                    IPPool::list(),
                    SendAt::binary()) -> {ok, term()} | {error, term()}.
send_template(TemplateName, TemplateContent, Message, Async, IPPool, SendAt) ->
    Params = [{<<"template_name">>, TemplateName},
              {<<"template_content">>, TemplateContent},
              {<<"message">>, {Message}},
              {<<"async">>, Async},
              {<<"ip_pool">>, IPPool},
              {<<"send_at">>, SendAt}],
    lager:debug("Sending Template message", []),

    mandrill_call("messages/send-template", Params).


-spec send_template(TemplateName::binary(),
                    TemplateContent::binary(),
                    Message::list())-> {ok, term()} | {error, term()}.
send_template(TemplateName, TemplateContent, Message) ->
    send_template(TemplateName, TemplateContent, Message, false, [], []).

-spec mandrill_call(MUrl::string(),
                    Params::list()) -> {ok, term()} | {error, term()}.
mandrill_call(MUrl, Params) ->
    {ok, Apikey} = application:get_env(mandrill, apikey),
    Url = ?MANDRILL_MESSAGES_URL ++ MUrl ++ ".json",
    PostData = [{<<"key">>, Apikey}] ++  Params,
    lager:debug("Postdata: ~p~n", [PostData]),
    PostBody = jiffy:encode({PostData}),
    Request = {Url, [], "application/json", PostBody},
    case httpc:request(post, Request, [], []) of
        {ok, {{"HTTP/1.1", 200, "OK"}, _, Content}} ->
            {ok, jiffy:decode(Content)};
        _ ->
            {error, "Call to mandrill failed"}
    end.
