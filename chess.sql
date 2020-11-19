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
  select *
  from width
  cross join height
);

create materialized view linear_movement_basis_vectors as (
  with recursive bitmasks as (
    select 1 n
    union
    select (n + 1)
    limit (2 ^ 4) -- 2 possible states per direction: active or inactive.  4 possible dimensions
  ),
  combinations as (
    select(
      ((bit(n) & (2 ^ 4))) as w_dimension_active,
      ((bit(n) & (2 ^ 3))) as z_dimension_active,
      ((bit(n) & (2 ^ 2))) as y_dimension_active,
      ((bit(n) & (2 ^ 1))) as x_dimension_active
    )
    from bitmasks
  )
  select (
    (w_direction_active + z_direction_active + x_direction_active + y_direction_active) as num_directions_active,
    w_direction_active as w,
    x_direction_active as x,
    y_direction_active as y,
    z_direction_active as z
  )
  from combinations
);
create index linear_movement on linear_movement_basis_vectors(num_directions_active);

create view lines as (
  select (
    (w*n) as w,
    (x*n) as x,
    (y*n) as y,
    (z*n) as z,
    natural_numbers.n,
    num_directions_active
  )
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
  )
  select *
  from pieces
  join board on row(pieces) = row(board)
);

create sequence game_seq;

-- raw player inputs plus some validations.  This doesn't validate piece movements.  There are views for that sort of thing.
create table moves (
  -- TODO: `id` necessary?
  game          int not null default nextval(game_seq),
  to_timeline   int not null,
  from_timeline int not null,
  inward_timeline -- TODO: Postgres generated column -- take advantage of the natural ordering of the integers.  Move toward zero.  FK(abs(thing) - 1)
  to_turn       int not null check ((to_turn > 0) && ((to_turn > 1) || (from_turn is null))), -- TODO: these constraints aren't quite right
  from_turn     int references moves(to_turn),
  to_x          int not null,
  from_x        int not null,
  to_y          int not null,
  from_y        int not null,
  piece_type    varchar(1) not null, -- TODO: is this something that can be put into the view?
  piece_color   int not null check (abs(piece_color) = 1) -- TODO: Postgres generated column?
);
create unique index can_only_move_once_per_board_turn on moves(game, from_timeline, from_turn);
create index starting_location on moves(game, from_timeline, from_turn, from_x, from_y);
create index ending_location on moves(game, to_timeline, to_turn, to_x, to_y);
-- TODO: This index was an attempt to specify the semantics of timeline forking.  This doesn't completely capture all cases, namely it does not account for
-- forward creation, where a past timeline jumps forward to a future board on another timeline.  Investigate whether this index is worth keeping and/or what
-- new indexes can support the full semantics of checking whether a board has been moved to twice.
create index potential_timeline_creations on moves(game, from_timeline, to_turn) where (from_turn > to_turn);


-- TODO: initial board state
-- TODO: active and inactive timelines.  prolly need be in view
-- TODO: filter invalid movements and all subsequent events per game
create view state as (
  with recursive state -- TODO recursive, grouped self-join???
);

-- TODO: pawns might actually be one of the more curious constructions
-- black and white should be + and - 1 for the purposes of pawn movements as well as timelines.
-- castling + en-passant
