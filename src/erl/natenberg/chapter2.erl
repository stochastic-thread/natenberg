-module(chapter2).
-record(underlying, {px}).
-record(option, {px, strike}).
-record(side, { underlyings=[], calls=[], puts=[] }).
-record(position, { long=#side{}, short=#side{} }).
-export([pages/0, page15/0, page16/0, page17/0, page18/0, page19/0, page20/0, page21/0, page22/0]).
-include_lib("eunit/include/eunit.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% API
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pages() ->
	timer:start(),
	pages(1, 1000, [page15, page16, page17, page18, page19, page20, page21]).

pages(Seq, _, []) ->
	Seq;
pages(Seq, Millis, [H|T]) ->
	timer:apply_after(Seq * Millis, chapter2, H, []),
	pages(Seq + 1, Millis, T).

page15() ->
	Underlying = #underlying{px = 99.0},
	Long = #side{underlyings = [Underlying]},
	Position = #position{ long = Long },
	draw(Position).

page16() ->
	Call = #option{px = 1.15, strike = 105.0},
	Long = #side{calls = [Call]},
	Position = #position{long = Long},
	draw(Position).

page17() ->
	Call = #option{px = 1.15, strike = 105.0},
	Short = #side{calls = [Call]},
	Position = #position{short = Short},
	draw(Position).

page18() ->
	Put = #option{px = 1.55, strike = 95.0},
	Long = #side{puts = [Put]},
	Position = #position{long = Long},
	draw(Position).	

page19() ->
	Put = #option{px = 1.55, strike = 95.0},
	Short = #side{puts = [Put]},
	Position = #position{short = Short},
	draw(Position).

page20() ->
	Call = #option{px = 0.70, strike = 100.0},
	Put = #option{px = 1.70, strike = 100.0},
	Long = #side{calls = [Call], puts = [Put]},
	Position = #position{long = Long},
	draw(Position).	

page21() ->
	Call = #option{px = 0.7, strike = 100.0},
	Put = #option{px = 1.7, strike = 100.0},
	Short = #side{calls = [Call], puts = [Put]},
	Position = #position{short = Short},
	draw(Position).

page22() ->
	Call = #option{px = 0.55, strike = 95.0},
	Put = #option{px = 0.15, strike = 105.0},
	Short = #side{calls = [Call], puts = [Put]},
	Position = #position{short = Short},
	draw(Position).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Implementation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

draw(Position) ->
	view:draw(pxByPnl(Position)).

pxByPnl(Position) ->
	Pxs = pxs(Position),
	Pnls = [ pnl(Px, Position) || Px <- Pxs ],
	lists:zip(Pxs, Pnls).

pxs(#position{long = Long, short = Short}) ->
	LongPxs = pxs(Long),
	ShortPxs = pxs(Short),
	Pxs = lists:usort(LongPxs ++ ShortPxs),
	Low = hd(Pxs),
	High = lists:last(Pxs),
	% bug: pxs need to stretch past 0 in at least one direction
	[common:floor(Low - 2)] ++ Pxs ++ [common:ceiling(High + 2)];
pxs(#side{underlyings = Underlyings, calls = Calls, puts = Puts}) ->
	[Underlying#underlying.px || Underlying <- Underlyings] ++ 
	[Option#option.strike || Option <- Calls ++ Puts].

pnl(Px, #position{long = Long, short = Short}) ->
	Pnl = [ Px - U#underlying.px || U <- Long#side.underlyings ] ++
	      [-Px + U#underlying.px || U <- Short#side.underlyings ] ++
	      [-C#option.px || C <- Long#side.calls,  Px =< C#option.strike ] ++
	      [ C#option.px || C <- Short#side.calls, Px =< C#option.strike ] ++
	      [-P#option.px || P <- Long#side.puts,   Px >= P#option.strike ] ++
	      [ P#option.px || P <- Short#side.puts,  Px >= P#option.strike ] ++
	      [ Px - C#option.strike - C#option.px || C <- Long#side.calls,  Px > C#option.strike ] ++
	      [-Px + C#option.strike + C#option.px || C <- Short#side.calls, Px > C#option.strike ] ++
	      [-P#option.strike + Px + P#option.px || P <- Short#side.puts,  Px < P#option.strike ] ++
	      [ P#option.strike - Px - P#option.px || P <- Long#side.puts,   Px < P#option.strike ],
	lists:foldl(fun common:sum/2, 0.0, Pnl).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Unit Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pnls_empty_position_test() ->
	Position = #position{},
	?assertMatch(0.0, pnl(89.0, Position)).

pnls_short_straddle_test() ->
	Call = #option{px = 1.0, strike = 100.0},
	Put = #option{px = 1.0, strike = 100.0},
	Short = #side{calls = [Call], puts = [Put]},
	Position = #position{short = Short},
	?assertMatch(-1.0, pnl(97.0, Position)),
	?assertMatch(-1.0, pnl(103.0, Position)),	
	?assertMatch(0.0, pnl(98.0, Position)),
	?assertMatch(0.0, pnl(102.0, Position)),	
	?assertMatch(2.0, pnl(100.0, Position)).

pnls_long_straddle_test() ->
	Call = #option{px = 1.0, strike = 100.0},
	Put = #option{px = 1.0, strike = 100.0},
	Long = #side{calls = [Call], puts = [Put]},
	Position = #position{long = Long},
	?assertMatch(1.0, pnl(97.0, Position)),
	?assertMatch(1.0, pnl(103.0, Position)),
	?assertMatch(0.0, pnl(98.0, Position)),
	?assertMatch(0.0, pnl(102.0, Position)),
	?assertMatch(-2.0, pnl(100.0, Position)).

pnls_one_short_put_test() ->
	Put = #option{px = 1.0, strike = 100.0},
	Short = #side{puts = [Put]},
	Position = #position{short = Short},
	?assertMatch(-1.0, pnl(98.0, Position)),
	?assertMatch(0.0, pnl(99.0, Position)),
	?assertMatch(1.0, pnl(100.0, Position)),
	?assertMatch(1.0, pnl(101.0, Position)).

pnls_one_short_call_test() ->
	Call = #option{px = 1.0, strike = 100.0},
	Short = #side{calls = [Call]},
	Position = #position{ short = Short },
	?assertMatch(1.0, pnl(99.0, Position)),
	?assertMatch(1.0, pnl(100.0, Position)),
	?assertMatch(0.0, pnl(101.0, Position)),
	?assertMatch(-1.0, pnl(102.0, Position)).

pnls_one_long_call_test() ->
	Call = #option{px = 1.0, strike = 100.0},
	Long = #side{calls = [Call]},
	Position = #position{ long = Long },
	?assertMatch(-1.0, pnl(99.0, Position)),
	?assertMatch(-1.0, pnl(100.0, Position)),
	?assertMatch(0.0, pnl(101.0, Position)),
	?assertMatch(1.0, pnl(102.0, Position)).

pnls_one_long_put_test() ->
	Put = #option{px = 1.0, strike = 100.0},
	Long = #side{puts = [Put]},
	Position = #position{ long = Long },
	?assertMatch(-1.0, pnl(101.0, Position)),
	?assertMatch(-1.0, pnl(100.0, Position)),
	?assertMatch(0.0, pnl(99.0, Position)),
	?assertMatch(1.0, pnl(98.0, Position)).

pxs_one_short_one_put_test() ->
	Put = #option{px = 3.24, strike = 101.4},
	Short = #side{puts = [Put]},
	Position = #position{ short = Short },
	?assertMatch([99, 101.4, 104], pxs(Position)).

pxs_one_underlying_test() ->
	Underlying = #underlying{px = 99.0},
	Long = #side{underlyings = [Underlying]},
	Position = #position{ long = Long },
	?assertMatch([97, 99.0, 101], pxs(Position)).
