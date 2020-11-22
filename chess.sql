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
  from width
  cross join height
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

create sequence game_seq;

--------------------------------------------------------------------------------------------------------------------------------

create table moves (
  -------------------------------------------------------------------------------
  -- base columns
  -------------------------------------------------------------------------------
  game            int not null default nextval(game_seq),
  to_timeline     int not null,
  from_timeline   int not null,
  real_turn       int not null, -- mostly used as a way of tracking the order moves were made in in actual time
  to_turn         int not null check ((to_turn > 0) && ((to_turn > 1) || (from_turn is null))), -- TODO: these constraints aren't quite right
  from_turn       int not null,
  to_x            int not null,
  from_x          int not null,
  to_y            int not null,
  from_y          int not null,
  piece_type      varchar(1) not null,

  -------------------------------------------------------------------------------
  -- generated columns
  -------------------------------------------------------------------------------
  -- validate sequentiality of real turns starting from 1 per game
  prev_turn       int generated always as nullif((real_turn - 1), 0) stored references moves(game, real_turn),
  -- validate that we're not creating timelines at n distance from the origin till we have one at (n-1) distance from the origin
  -- tools for validating the chain of moves made by any given piece -- hacks using nulls and FKs
  has_prev_turn   bool generated always as (real_turn > 1) stored,
  is_not_init     bool generated always as (t),

  -------------------------------------------------------------------------------
  -- constraints
  -------------------------------------------------------------------------------
  -- you have to actually move
  check ((from_timeline != to_timeline) or (from_turn != to_turn) or (from_x != to_x) or (from_y != to_y)),
  --  ? players must move their own pieces
  TODO
  --  ? any linear movement stops if it hits an edge of a board
  TODO
  --  ? any given board cannot be moved from twice -- unless castling.  Need to actually perform both moves if using foreign keys to prior piece locations.
  TODO
  --  ? timelines stack according to their creator
  TODO
  --  - moves alternate between pieces of opposing color -- except all timelines in the present must be moved on in a row by each player
  TODO
  --  ? moving between boards uses up the moves of both (a board moved to cannot be moved from unless both actions happened in the same move) -- what about castling?
  TODO
  --  ? a timeline cannot be moved from if it is inactive (this might actually be enforeceable in `moves`).  -- cannot or does not have to be?
  TODO foreign key from inward_timeline to negation of inward_timeline?  will that work for newly-created but unmoved-upon foreign timelines?
  -- you can only move a piece from where it was -- works for the first move because `has_prev_move` is null which deactivates the constraint
  foreign key (game,from_timeline,from_turn,from_x,from_y,piece,has_prev_turn) references moves(game,to_timeline,to_turn,to_x,to_y,piece,is_not_init),

  -------------------------------------------------------------------------------
  -- indexes -- TODO: go over these once done with data and constraint defs
  -------------------------------------------------------------------------------
);
create unique index game_real_turn on moves(game, real_turn);
create unique index can_only_move_once_per_board_turn on moves(game, from_timeline, from_turn); -- TODO: partial index where king hasn't moved 2 sqs?
create index starting_location on moves(game, from_timeline, from_turn, from_x, from_y);
create index ending_location on moves(game, to_timeline, to_turn, to_x, to_y);
-- TODO: This index was an attempt to specify the semantics of timeline forking.  This doesn't completely capture all cases, namely it does not account for
-- forward creation, where a past timeline jumps forward to a future board on another timeline.  Investigate whether this index is worth keeping and/or what
-- new indexes can support the full semantics of checking whether a board has been moved to twice.
create index potential_timeline_creations on moves(game, from_timeline, to_turn) where (from_turn > to_turn);

--------------------------------------------------------------------------------------------------------------------------------

-- TODO: filter invalid movements and all subsequent events per game
create view state as (
  with recursive state -- TODO recursive, grouped self-join???
);

-- black and white should be + and - 1 for the purposes of pawn movements as well as timelines.

-- define betweenness as opposed to defining iteration of moves
-- join against the set of all pieces on whether they're linearly-between the start and end

-- TODO: `timelines` view
-- TODO: `available_moves` view used for presentation as well as validation
-- TODO: piece movement definitions
big piece switch statement with movement mechanic defintions?  joins of some sort?  left join after left join?
dynamic and/or normalized movement defintions?  maybe this even simplifies some things.
