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

-module(chapter2).
-export([draw/1, pages/0, page15/0, page16/0, page17/0, page18/0, page19/0, page20/0, page21/0, page22/0, page23/0, page24/0, page26/0, page29/0]).
-include_lib("eunit/include/eunit.hrl").
-include_lib("position.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% API
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pages() ->
	timer:start(),
	Functions = [page15, page16, page17, page18, page19, page20, page21, page22, page23, page24, page26, page29],
	[ timer:apply_after(Seq * 1000, chapter2, lists:nth(Seq, Functions), []) || Seq <- lists:seq(1, length(Functions)) ].

page15() ->
	draw(?LONG_UNDERLYING).

page16() ->
	draw(?LONG_CALL).

page17() ->
	draw(?SHORT_CALL).

page18() ->
	draw(?LONG_PUT).

page19() ->
	draw(?SHORT_PUT).

page20() ->
	draw(?LONG_STRADDLE).	

page21() ->
	draw(?SHORT_STRADDLE).

page22() ->
	draw(?SHORT_STRANGLE).

page23() ->
	draw(?PAGE_23).

page24() ->
	draw(?PAGE_24).

page26() ->
	draw(?CALL_RATIO_VERTICAL_SPREAD).

page29() ->
	draw(?PAGE_29).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Implementation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

draw(Position) ->
	Msg = Position#position.description,
	view:draw(pxByPnl(Position), Msg).

pxByPnl(Position) ->
	Pxs = pxs(Position),
	Pnls = [ chapter1:pnl(Px, Position) || Px <- Pxs ],
	lists:zip(Pxs, Pnls).

pxs(Position = #position{long = Long, short = Short}) ->
	LongPxs = pxs(Long),
	ShortPxs = pxs(Short),
	Pxs = lists:usort(LongPxs ++ ShortPxs),
	{DownsideRisk, UpsideRisk} = risk(Position),
	Low = hd(Pxs),
	LowPx = Low - break_even(Low, DownsideRisk, Position),
	High = lists:last(Pxs),
	HighPx = High + break_even(High, UpsideRisk, Position),
	[common:floor(LowPx)] ++ Pxs ++ [common:ceiling(HighPx)];
pxs(#side{underlyings = Underlyings, calls = Calls, puts = Puts}) ->
	[Underlying#underlying.px || Underlying <- Underlyings] ++ 
	[Option#option.strike || Option <- Calls ++ Puts].

break_even(Px, Risk, Position) ->
	Pnl = chapter1:pnl(Px, Position),
	if Risk * Pnl < 0 ->
		Pnl / -Risk;
	   true ->
		2 % stretch the x axis by 2 if pnl does not approach 0
	end.

risk(#position{long = Long, short = Short}) ->
	#side{underlyings = LongUnderlyings, calls = LongCalls, puts = LongPuts} = Long,
	#side{underlyings = ShortUnderlyings, calls = ShortCalls, puts = ShortPuts} = Short,
	{length(LongPuts) - length(ShortPuts) + length(ShortUnderlyings) - length(LongUnderlyings), 
	 length(LongCalls) - length(ShortCalls) - length(ShortUnderlyings) + length(LongUnderlyings)}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Unit Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

risk_underlying_test() ->
	Underlying = #underlying{px = 99.0},
	?assertMatch({-1, 1}, risk(#position{ long = #side{underlyings = [Underlying]} })),
	?assertMatch({1, -1}, risk(#position{ short = #side{underlyings = [Underlying]} })),
	?assertMatch({2, -2}, risk(#position{ short = #side{underlyings = [Underlying, Underlying]} })).

risk_calls_test() ->
	Call = #option{px = 1.0, strike = 100.0},
	?assertMatch({0, 1}, risk(#position{ long = #side{calls = [Call]} })),
	?assertMatch({0, -1}, risk(#position{ short = #side{calls = [Call]} })),
	?assertMatch({0, -2}, risk(#position{ short = #side{calls = [Call, Call]} })).

risk_puts_test() ->
	Put = #option{px = 1.0, strike = 100.0},
	?assertMatch({1, 0}, risk(#position{ long = #side{puts = [Put]} })),
	?assertMatch({-1, 0}, risk(#position{ short = #side{puts = [Put]} })),
	?assertMatch({-2, 0}, risk(#position{ short = #side{puts = [Put, Put]} })).

risk_spread_test() ->
	LongCall = #option{px = 9.35, strike = 90.0},
	ShortCall = #option{px = 2.7, strike = 100.0},
	Long = #side{calls = [LongCall]},
	Short = #side{calls = [ShortCall]},
	Position = #position{long = Long, short = Short},	
	?assertMatch({0, 0}, risk(Position)).

pxs_one_short_one_put_test() ->
	Put = #option{px = 2.00, strike = 100.0},
	Short = #side{puts = [Put]},
	Position = #position{ short = Short },
	?assertMatch([98, 100.0, 102], pxs(Position)).

pxs_one_short_one_put_force_stretch_test() ->
	Put = #option{px = 2.01, strike = 100.0},
	Short = #side{puts = [Put]},
	Position = #position{ short = Short },
	?assertMatch([97, 100.0, 102], pxs(Position)).

pxs_long_straddle_test() ->
	Call = #option{px = 0.70, strike = 100.0},
	Put = #option{px = 1.70, strike = 100.0},
	Long = #side{calls = [Call], puts = [Put]},
	Position = #position{long = Long},	
	?assertMatch([97, 100.0, 103], pxs(Position)).

pxs_short_straddle_test() ->
	Call = #option{px = 0.7, strike = 100.0},
	Put = #option{px = 1.7, strike = 100.0},
	Short = #side{calls = [Call], puts = [Put]},
	Position = #position{short = Short},
	?assertMatch([97, 100.0, 103], pxs(Position)).

pxs_short_straddle_different_strike_test() ->
	Call = #option{px = 1.15, strike = 105.0},
	Put = #option{px = 1.55, strike = 95.0},
	Short = #side{calls = [Call], puts = [Put]},
	Position = #position{short = Short},
	?assertMatch([92, 95.0, 105.0, 108], pxs(Position)).

pxs_one_underlying_test() ->
	Underlying = #underlying{px = 99.0},
	Long = #side{underlyings = [Underlying]},
	Position = #position{ long = Long },
	?assertMatch([97, 99.0, 101], pxs(Position)).
