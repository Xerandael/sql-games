create view natural_numbers as (
  with recursive natural_numbers as (
    select 1 as n
    union
    select (n + 1)
    from natural_numbers
  )
  select *
  from natural_numbers 
);

create view board as (
  with width as (
    select n as x
    from natural_numbers
    limit 8
  ),
  height as (
    select n as y
    from natural_numbers
    limit 8
  )
  select *, row_number() over () as n
  from height
  cross join width
);

create materialized view linear_movement_basis_vectors as (
  with recursive bitmasks as (
    select 1 n
    union
    select (n + 1)
    from bitmasks
  ),
  combinations as (
    select
      ((n::bit(8) & (2 ^ 3)::int::bit(8))::int != 0)::int as w_dimension_active,
      ((n::bit(8) & (2 ^ 2)::int::bit(8))::int != 0)::int as z_dimension_active,
      ((n::bit(8) & (2 ^ 1)::int::bit(8))::int != 0)::int as y_dimension_active,
      ((n::bit(8) & (2 ^ 0)::int::bit(8))::int != 0)::int as x_dimension_active
    from bitmasks
    limit (2 ^ 4) -- 2 possible states per direction: active or inactive.  4 possible dimensions
  )
  select
    (w_dimension_active + z_dimension_active + x_dimension_active + y_dimension_active) as num_dimensions_active,
    w_dimension_active as w,
    x_dimension_active as x,
    y_dimension_active as y,
    z_dimension_active as z
  from combinations
);
create index linear_movement on linear_movement_basis_vectors(num_dimensions_active);

create view lines as (
  select
    (w*n) as w,
    (x*n) as x,
    (y*n) as y,
    (z*n) as z,
    natural_numbers.n,
    num_dimensions_active
  from linear_movement_basis_vectors
  cross join natural_numbers 
);

create materialized view initial_board as (
  with pieces(type,color) as (
    values
      ('r',-1), ('k',-1), ('b',-1), ('Q',-1), ('K',-1), ('b',-1), ('k',-1), ('r',-1),
      ('p',-1), ('p',-1), ('p',-1), ('p',-1), ('p',-1), ('p',-1), ('p',-1), ('p',-1),
      (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0),
      (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0),
      (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0),
      (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0), (' ', 0),
      ('p', 1), ('p', 1), ('p', 1), ('p', 1), ('p', 1), ('p', 1), ('p', 1), ('p', 1),
      ('r', 1), ('k', 1), ('b', 1), ('K', 1), ('Q', 1), ('b', 1), ('k', 1), ('r', 1)
  ),
  squares as (
    select *, row_number() over () as square_num
    from pieces
  )
  select *
  from squares
  join board on squares.square_num = board.n
);

create view piece_movements as (
-- -- TODO: piece movement definitions
-- switch statement with movement mechanic defintions?  joins of some sort?  left join after left join?
-- dynamic and/or normalized movement defintions?  maybe this even simplifies some things.
);

create sequence game_seq;

--------------------------------------------------------------------------------------------------------------------------------

create table moves (
  -------------------------------------------------------------------------------
  -- base columns
  -------------------------------------------------------------------------------
  game            int not null default nextval('game_seq'),
  to_timeline     int not null,
  from_timeline   int not null,
  real_turn       int not null check (real_turn > 0), -- mostly used as a way of tracking the order moves were made in in actual time
  to_turn         int not null check (to_turn > 0),
  from_turn       int not null,
  to_x            int not null,
  from_x          int not null,
  to_y            int not null,
  from_y          int not null,

  -------------------------------------------------------------------------------
  -- generated columns
  -------------------------------------------------------------------------------
  prev_turn       int generated always as (nullif((real_turn - 1), 0)) stored,
  -- black is 1 and white is -1 the purposes of pawn movements as well as timelines
  player          int generated always as (((from_turn % 2) * 2) - 1) stored,

  -------------------------------------------------------------------------------
  -- constraints
  -------------------------------------------------------------------------------
  -- you have to actually move
  check ((from_timeline != to_timeline) or (from_turn != to_turn) or (from_x != to_x) or (from_y != to_y)),
  -- validate sequentiality of real turns starting at turn 1 each game
  unique(game, real_turn),
  foreign key (game,prev_turn) references moves(game,real_turn),
  -- can only move to boards of own color
  check ((from_turn % 2) = (to_turn % 2))

  -------------------------------------------------------------------------------
  -- indexes
  -------------------------------------------------------------------------------
);
-- castling is handled by just recording the king's move and automatically moving the rook thereafter
create unique index can_only_move_once_per_board_turn on moves(game, from_timeline, from_turn);
create index starting_location on moves(game, from_timeline, from_turn, from_x, from_y);
create index ending_location on moves(game, to_timeline, to_turn, to_x, to_y);
create index real_turns on moves(game,real_turn);
-- index to specify the semantics of timeline forking.  Support checking whether a board has been moved to twice.
create index ending_board_order on moves(game, to_timeline, to_turn, real_turn);

--------------------------------------------------------------------------------------------------------------------------------

create view timelines as (
  with recursive timelines as (
    with available_moves as (
      -- TODO:  join positions of moveable pieces against piece movements
    )
    select *
    from timelines t
    join available_moves a on ((a.from_timeline = t.timeline) and (a.from_turn = t.turn))
  )
  select *
  from timelines
);

create view available_moves as (
  select null -- TODO
);

create view timelines as (
  select 1 game, 1 timeline, 1 turn -- TODO mock data
);
-- -- TODO: filter invalid movements and all subsequent events per game
-- create view state as (
--   with recursive state -- TODO recursive, grouped self-join???
-- );
-- 
-- 
-- -- define betweenness as opposed to defining iteration of moves
-- -- join against the set of all pieces on whether they're linearly-between the start and end
-- TODO: I think the moving player has to be determined by the color of the piece being moved with only validation by determining whether
-- that player can move 

-- TODO: `piece_positions` view
-- TODO: `board_events` view?
