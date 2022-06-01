% This file is part of Jiffy released under the MIT license.
% See the LICENSE file for more information.

-module(jiffy_06_object_tests).


-include_lib("eunit/include/eunit.hrl").
-include("jiffy_util.hrl").


object_success_test_() ->
    [gen(ok, Case) || Case <- cases(ok)].


object_failure_test_() ->
    [gen(error, Case) || Case <- cases(error)].


nested_object_test_() ->
    Obj = nested(256),
    Enc = enc(Obj),
    ?_assertEqual(Obj, dec(Enc)).


nested(0) -> <<"bottom">>;
nested(N) -> {[{to_bin(N), nested(N - 1)}]}.


to_bin(N) when is_integer(N) ->
    list_to_binary(integer_to_list(N)).


elixir_structs_test_() ->
    Obj = #{id => 1, '__struct__' => 'An.Elixit.Struct', name => <<"Leto">>},
    Enc = enc(Obj),
    ?_assertEqual(<<"{\"name\":\"Leto\",\"id\":1}">>, Enc).

elixir_datetime_test_() ->
    Obj = #{d => #{'__struct__' => 'Elixir.DateTime', year => 2022, month => 5, day => 8, hour => 2, minute => 6, second => 1, microsecond => {123456, 6}}},
    Enc = enc(Obj),
    ?_assertEqual(<<"{\"d\":\"2022-05-08T02:06:01.123Z\"}">>, Enc).

elixir_datetime_error_test_() ->
    Obj = #{d => #{'__struct__' => 'Elixir.DateTime'}},
    ?_assertError(invalid_datetime, jiffy:encode(Obj)).

gen(ok, {J, E}) ->
    gen(ok, {J, E, J});
gen(ok, {J1, E, J2}) ->
    {msg("~s", [J1]), [
        {"Decode", ?_assertEqual(E, dec(J1))},
        {"Encode", ?_assertEqual(J2, enc(E))}
    ]};

gen(error, J) ->
    {msg("Error: ~s", [J]), [
        ?_assertError(_, dec(J))
    ]}.


cases(ok) ->
    [
        {<<"{}">>, {[]}},
        {<<"{\"foo\": \"bar\"}">>,
            {[{<<"foo">>, <<"bar">>}]},
            <<"{\"foo\":\"bar\"}">>},
        {<<"\n\n{\"foo\":\r \"bar\",\n \"baz\"\t: 123 }">>,
            {[{<<"foo">>, <<"bar">>}, {<<"baz">>, 123}]},
            <<"{\"foo\":\"bar\",\"baz\":123}">>}
    ];

cases(error) ->
    [
        <<"{">>,
        <<"{,}">>,
        <<"{123:true}">>,
        <<"{false:123}">>,
        <<"{:\"stuff\"}">>,
        <<"{\"key\":}">>,
        <<"{\"key\": 123">>,
        <<"{\"key\": 123 true">>,
        <<"{\"key\": 123,}">>
    ].
