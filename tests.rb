#!ruby
$output = [ "drop table if exists test_cases; create table test_cases(name varchar(128), status bool);" ]
$game_id = 0
def test(game_id=($game_id += 1),content)
  name,moves,assertion = content.split '---'
  if content.include? 'TODO'
    $output << "insert into test_cases(name,status) values ('#{name.gsub "'", "''"}', false);"
  end
  moves.split("\n")[1..-2].each{|a|
    $output << <<-SQL
      insert into moves(game,real_turn,from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y)
      values (#{game_id},(select count(*) + 1 from moves where game = #{game_id}),#{a});
    SQL
  }.join
  $output << "insert into test_cases(name,status) values ('#{name.gsub "'", "''"}', (#{assertion.gsub '$game_id', $game_id.to_s}));"
end
statements = (File.readlines 'chess.sql')
statements.reverse.each {|l|
  if(rel = l.match(/^create table \w+/))
    $output << "drop table if exists #{rel.to_s.split(' ').last};"
  elsif (rel = l.match(/^create materialized view \w+/))
    $output << "drop materialized view if exists #{rel.to_s.split(' ').last};"
  elsif (rel = l.match(/^create view \w+/))
    $output << "drop view if exists #{rel.to_s.split(' ').last};"
  elsif (rel = l.match(/^create sequence \w+/))
    $output << "drop sequence if exists #{rel.to_s.split(' ').last};"
  end
}
statements.each {|l| $output << l}
############################################################################################################################################################
test <<-TEST
  you have to actually move
  ---
  1,1,1,1 , 1,1,1,1
  ---
  select ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,1,1,1,1)) = 0)
TEST


test <<-TEST
  a timeline is created on the player's stack when moving to a board which has already been moved to
  ---
  1,1,5,2 , 1,1,5,4
  1,2,5,7 , 1,1,5,5
  1,3,7,1 , 1,1,7,3
  ---
  select ((select count(distinct(timeline)) from timelines where (game) = ($game_id)) = 2)
TEST


test <<-TEST
  you can only capture the enemy's pieces
  ---
  1,1,5,2 , 1,1,5,4
  1,2,5,7 , 1,1,5,5
  1,3,5,4 , 1,3,4,5
  1,4,1,7 , 1,4,1,6
  1,5,4,1 , 1,5,4,2
  ---
  (select(
    (select count(*) from timelines where (piece_color = 1) and (game = $game_id))
    >
    (select count(*) from timelines where (piece_color = -1) and (game = $game_id))
  ))
TEST


test <<-TEST
  linear movement cannot go through another piece
  ---
  1,1,4,2 , 1,1,4,4
  1,2,5,7 , 1,1,5,5
  1,3,4,1 , 1,3,4,5
  ---
  select ((select count(distinct(turn)) from timelines where game = $game_id) = 2)
TEST


test <<-TEST
  linear movement cannot go past the edge of a board
  ---
  1,1,5,2 , 1,1,5,4
  1,2,5,7 , 1,1,5,5
  1,3,4,1 , 1,3,9,6
  ---
  select ((select count(distinct(turn)) from timelines where game = $game_id) = 2)
TEST


test <<-TEST
  any linear movement through time or timelines stops if there's no board, a gap
  ---
  TODO moves here
  ---
  TODO assertion here
  select ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1)
TEST


test <<-TEST
  knights can jump over gaps 
  ---
  1,1,7,1 , 1,1,6,3
  1,2,7,8 , 1,2,6,6
  1,3,6,3 , 1,1,6,5
  2,2,7,8 , 2,2,6,6
  2,3,6,5 , 1,3,6,7
  1,4,7,8 , 1,4,6,6
  2,4,6,6 , 2,4,4,5
  1,5,2,1 , 1,5,1,3
  2,5,2,1 , 2,3,2,3
  4,4,6,6 , 4,4,4,5
  1,6,7,8 , 1,6,6,6
  2,6,4,5 , 2,6,6,6
  4,5,6,5 , 2,7,6,5
  ---
  select ((select count(*) from timelines where game = $game_id) = 18)
TEST


test <<-TEST
  any given board cannot be moved from twice -- unless castling
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  the move has to actually make sense for the given piece
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  if a move is made, it must be from a position previously moved to or from the starting position
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  a timeline is created when moving to a board which has already been moved to
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  timelines stack according to their creator
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  moves alternate between pieces of opposing color.  each player moves pieces on each board before the next player can move.
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  pieces are removed when taken
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  moving between boards uses up the moves of both
  ---
  1,1,1,1 , 2,1,1,1
  1,1,1,1 , 3,1,1,1
  2,1,1,1 , 4,1,1,1
  ---
  select (
    ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1)
    and
    ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,3,1,1,1)) = 0)
    and
    ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (2,1,1,1,4,1,1,1)) = 0)
  )
TEST


test <<-TEST
  if one is in check, one cannot move a piece except to leave check
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  one cannot move a piece such that one enters oneself into check
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  pawns move one square forward in the direction of their color
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  pawns can move two squares on initial movement
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  pawns must move diagonally to capture
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  pawns can only move diagonally when capturing
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  pawns can en-passant each other
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  castling can only happen if neither piece has moved
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  castling can only happen if there are not pieces between the two
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  castling cannot happen in check
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  when castling, the king moves 2 squares.  or vice versa
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  when castling, the rook moves along with the king
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  pawn promotion
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  a timeline does not have to be moved from if it is inactive
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  a board moved to cannot be moved from unless both actions happened in the same move or the movement from it happened first
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  checkmate
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  stalemate
  ---
  TODO moves here
  ---
  TODO assertion here
  ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,2,1,1,1)) = 1) and
TEST


test <<-TEST
  can only move to boards of own color
  ---
  1,1,1,1 , 1,2,1,1
  2,2,2,2 , 2,4,2,2
  ---
  select (
    ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,1,2,1,1)) = 0) and
    ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (2,2,2,2,2,4,2,2)) = 1)
  )
TEST


# TODO
# test <<-TEST
#   castling across timelines uses up the moves of 4 boards
#   ---
#   1,1,1,1 , 1,2,1,1
#   2,2,2,2 , 2,4,2,2
#   ---
#   select (
#     ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (1,1,1,1,1,2,1,1)) = 0) and
#     ((select count(*) from moves where (from_timeline,from_turn,from_x,from_y,to_timeline,to_turn,to_x,to_y) = (2,2,2,2,2,4,2,2)) = 1)
#   )
# TEST
############################################################################################################################################################
$output << "select * from test_cases order by status desc;"
psql = IO.popen 'psql', 'w'
psql.puts $output.join("\n")
