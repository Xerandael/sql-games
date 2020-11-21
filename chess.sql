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

--- TODO: everything works up to here

-- raw player inputs plus some validations.  This doesn't validate piece movements.  There are views for that sort of thing.
-- TODO: some of the constraints I see as enforceable here:
--  - you have to actually move
--  ? players must move their own pieces
--  ? any linear movement stops if it hits an edge of a board
--  ? any given board cannot be moved from twice -- unless castling
--  ? timelines stack according to their creator
--  - moves alternate between pieces of opposing color
--  ? moving between boards uses up the moves of both (a board moved to cannot be moved from unless both actions happened in the same move)
--  ? a timeline cannot be moved from if it is inactive (this might actually be enforeceable in `moves`)
create table moves (
  -- TODO: `id` necessary?
  game          int not null default nextval(game_seq),
  to_timeline   int not null,
  from_timeline int not null,
  inward_timeline -- TODO: Postgres generated column -- take advantage of the natural ordering of the integers.  Move toward zero.  FK(abs(thing) - 1)
  to_turn       int not null check ((to_turn > 0) && ((to_turn > 1) || (from_turn is null))), -- TODO: these constraints aren't quite right
  from_turn     int references moves(to_turn), -- TODO: should this be `not null`?
  to_x          int not null,
  from_x        int not null,
  to_y          int not null,
  from_y        int not null,
  piece_type    varchar(1) not null, -- TODO: is this something that can be put into the view? -- alternatively, the FK possibilities might be nice here
  piece_color   int not null check (abs(piece_color) = 1) -- TODO: Postgres generated column?
  -- validate that the board you want to move to exists.  Wait.  What about boards moved _through_?  the knight can jump over missing boards.
  -- foreign key against a view
  -- validate that not more than one starting move exists per game.
  foreign key (game,from_timeline,from_turn) references moves(game,to_timeline,to_turn);
);
create unique index can_only_move_once_per_board_turn on moves(game, from_timeline, from_turn);
create index starting_location on moves(game, from_timeline, from_turn, from_x, from_y);
create index ending_location on moves(game, to_timeline, to_turn, to_x, to_y);
-- TODO: This index was an attempt to specify the semantics of timeline forking.  This doesn't completely capture all cases, namely it does not account for
-- forward creation, where a past timeline jumps forward to a future board on another timeline.  Investigate whether this index is worth keeping and/or what
-- new indexes can support the full semantics of checking whether a board has been moved to twice.
create index potential_timeline_creations on moves(game, from_timeline, to_turn) where (from_turn > to_turn);


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


-- DROP MIC IF EXISTS; (final slide)  GitHub as slides. @TODO
