%% Copyright 2012 Opscode, Inc. All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%

-module(oc_httpc_tests).

-include_lib("eunit/include/eunit.hrl").

opscoderl_ibrowse_test_() ->
    {setup,
     fun() ->
            application:start(crypto),
            application:start(public_key),
            application:start(ssl),
            application:start(pooler),
            ibrowse:start(),
             ok
     end,
     fun(_) ->
             ok
     end,
     [
      %% assert_200_req("http://www.google.co.uk", "", get),
      assert_200_req("http://www.google.com", "", get),
      assert_200_req("http://www.google.com", "",options),
      assert_200_req("https://mail.google.com", "",get),
      assert_200_req("http://www.sun.com", "",get),
      assert_200_req("http://www.oracle.com", "",get),
      assert_200_req("http://www.bbc.co.uk", "",get),
      assert_200_req("http://www.bbc.co.uk", "",trace),
      assert_200_req("http://www.bbc.co.uk", "",options),
      assert_200_req("http://yaws.hyber.org", "",get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/ChunkedScript", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/TE/foo.txt", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/TE/bar.txt", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/connection.html", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/cc.html", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/cc-private.html", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/cc-proxy-revalidate.html", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/cc-nocache.html", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/h-content-md5.html", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/h-retry-after.html", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/h-retry-after-date.html", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/neg", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/negbad", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/400/toolong/", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/300/", get),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/Basic/", get,[{basic_auth, {"guest", "guest"}}]),
      assert_200_req("https://github.com", "",get, [{ssl_options, [{depth, 2}]}]),
      assert_200_req("http://jigsaw.w3.org/", "HTTP/CL/", get),
      assert_200_req("http://www.httpwatch.com/", "httpgallery/chunked/", get)
     ]}.

assert_200_req(RootUrl, Endpoint, Method) ->
    assert_200_req(RootUrl, Endpoint, Method, []).
assert_200_req(RootUrl, Endpoint, Method, OptionsInput) ->
    {atom_to_list(Method) ++ " " ++ RootUrl ++ "/" ++ Endpoint,
     fun() ->
             Options = [{connect_timeout, 5000}] ++ OptionsInput,
             PoolConfig = [{root_url, RootUrl}, {init_count, 50}, {max_count, 250},
                           {ibrowse_options, Options}],
             oc_httpc:add_pool(list_to_atom(RootUrl), PoolConfig),
             Result = (catch oc_httpc:request(list_to_atom(RootUrl), Endpoint, [], Method, [], 60000)),
             oc_httpc:delete_pool(list_to_atom(RootUrl)),


             ?assertMatch({ok, _, _, _}, Result)
     end}.

multi_request_test() ->
    RootUrl = "http://jigsaw.w3.org/",
    CallbackFun = fun(RequestFun) ->
                          Paths = ["HTTP/ChunkedScript",
                                   "HTTP/TE/foo.txt",
                                   "HTTP/TE/bar.txt",
                                   "HTTP/connection.html",
                                   "HTTP/cc.html",
                                   "HTTP/cc-private.html",
                                   "HTTP/cc-proxy-revalidate.html",
                                   "HTTP/cc-nocache.html",
                                   "HTTP/h-content-md5.html",
                                   "HTTP/h-retry-after.html",
                                   "HTTP/h-retry-after-date.html",
                                   "HTTP/neg",
                                   "HTTP/negbad",
                                   "HTTP/400/toolong/",
                                   "HTTP/300/"],
                          [ RequestFun(P, [], get, []) || P <- Paths ]
                  end,
    Options = [{connect_timeout, 5000}],
    PoolConfig = [{root_url, RootUrl}, {init_count, 50}, {max_count, 250},
			{ibrowse_options, Options}],
		oc_httpc:add_pool(list_to_atom(RootUrl), PoolConfig),
    Results = (catch oc_httpc:multi_request(list_to_atom(RootUrl), CallbackFun , 60000)),
		oc_httpc:delete_pool(list_to_atom(RootUrl)),
    ?assertEqual(15, length(Results)),
    [?assertMatch({ok, _,_,_}, Result) || Result <- Results].

