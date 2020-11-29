create schema events;

create sequence events.game_seq;

create table events.moves (
  game            int not null default nextval('game_seq'),
  to_timeline     int not null,
  from_timeline   int not null,
  order           int not null check (order > 0), -- mostly used as a way of tracking the order moves were made in in actual time
  to_turn         int not null check (to_turn > 0),
  from_turn       int not null,
  to_x            int not null,
  from_x          int not null,
  to_y            int not null,
  from_y          int not null,

  prev_turn       int generated always as (nullif((order - 1), 0)) stored,
  -- black is 1 and white is -1 the purposes of pawn movements as well as timelines
  player          int generated always as (((from_turn % 2) * 2) - 1) stored,

  -- you have to actually move
  check ((from_timeline != to_timeline) or (from_turn != to_turn) or (from_x != to_x) or (from_y != to_y)),
  -- validate sequentiality of real turns starting at turn 1 each game
  unique(game, order),
  foreign key (game,prev_turn) references moves(game,order),
  -- can only move to boards of own color
  check ((from_turn % 2) = (to_turn % 2))
);

create unique index  can_only_move_once_per_board_turn           on events.moves(game, from_timeline, from_turn);
create        index  starting_location                           on events.moves(game, from_timeline, from_turn, from_x, from_y);
create        index  ending_location                             on events.moves(game, to_timeline, to_turn, to_x, to_y);
create unique index  order                                       on events.moves(game, order);
create        index  ordered_list_of_moves_onto_any_given_board  on events.moves(game, to_timeline, to_turn, order);
