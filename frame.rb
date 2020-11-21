tests = <<-SQL
  create table test_cases(name varchar(128), status varchar(8));

  -- TODO: test cases
  -- you have to actually move
  -- you can only capture the enemy's pieces
  -- any linear movement stops as soon as it encounters another piece
  -- any linear movement stops if it hits an edge of a board
  -- any linear movement through time or timelines stops if there's no board, a gap
  -- knights can jump over gaps 
  -- any given board cannot be moved from twice -- unless castling
  -- the move has to actually make sense for the given piece
  -- the move has to make sense at the clock time it's made;  all moves have to form an accumulably-correct state
  -- if a move is made, it must be from a position previously moved to or from the starting position
  -- a timeline is created when moving to a board which has already been moved to
  -- timelines stack according to their creator
  -- moves alternate between pieces of opposing color
  -- pieces are removed when taken
  -- moving between boards uses up the moves of both
  -- if one is in check, one cannot move a piece except to leave check
  -- one cannot move a piece such that one enters oneself into check
  -- pawns move one square forward in the direction of their color
  -- pawns can move two squares on initial movement
  -- pawns must move diagonally to capture
  -- pawns can only move diagonally when capturing
  -- pawns can en-passant each other
  -- castling can only happen if neither piece has moved
  -- castling can only happen if there are not pieces between the two
  -- castling cannot happen in check
  -- when castling, the king moves 2 squares
  -- pawn promotion
  -- a timeline cannot be moved from if it is inactive (this might actually be enforeceable in `moves`)
SQL

------------------------------------------------------------------------------------------------------------------------
statements = (File.readlines 'chess.sql') + tests
statements.reverse.each {|l|
  if(rel = l.match(/^create table \w+/))
    puts "drop table if exists #{rel.to_s.split(' ').last}"
  elsif (rel = l.match(/^create materialized view \w+/))
    puts "drop materialized view if exists #{rel.to_s.split(' ').last}"
  elsif (rel = l.match(/^create view \w+/))
    puts "drop view if exists #{rel.to_s.split(' ').last}"
  end
}
statements.each {|l| puts l}
