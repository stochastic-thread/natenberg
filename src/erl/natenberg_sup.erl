% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License.  You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
% License for the specific language governing permissions and limitations under
% the License.

-module(natenberg_sup).
-behaviour(supervisor).
-export([start_link/1, init/1]).

start_link(Args) ->
  erlang:display(atom_to_list(?MODULE) ++ " starting ..."),
  supervisor:start_link({local, ?MODULE}, ?MODULE, Args).

init(_Args) ->
	{ok, {{one_for_one, 10, 10},
    	[{natenberg, {natenberg, start_link, []},
          permanent, 2000, worker, [natenberg]}]}}.
