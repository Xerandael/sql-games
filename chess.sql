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

-- TODO: replace this with an initial board?  Merge that with the board definition?  Fancy crosstab notation?
create view pieces as (
  with types(type) as (
    values
      ('p'),
      ('r'),
      ('k'),
      ('b'),
      ('Q'),
      ('K')
  ),
  colors(color) as (
    values (1) (-1)
  )
  select *
  from types
  cross join colors
);

-- TODO: outdated.  See next paragraph for new definition in progress
create table events ( -- TODO: This is the raw player input state. Validate state by self-join of recursv view?
  game int not null,
  turn int not null check (turn > 0 && ((turn > 1) || (prev is null))),
  prev int references squares(turn) check ((prev is null) || ((turn - prev) = 1)),
  timeline int  -- timeline_above, timeline_below -- can't have both -- only need one -- maybe can take advantage of the natural ordering of the integers.  Move toward zero?  FK(abs(thing) - 1)
);

create sequence game_seq;

create table moves (
  game          int not null default nextval(game_seq),
  to_timeline   int not null,
  from_timeline int not null,
  to_turn       int not null,
  from_turn     int not null,
  previous_turn int not null,
  to_x          int not null,
  from_x        int not null,
  to_y          int not null,
  from_y        int not null,
  piece_type    varchar(1) not null,
  piece_color   int not null check (abs(piece_color) = 1)
);
create unique index can_only_move_once_per_board_turn on moves(from_timeline, from_turn);


-- TODO: initial board state
-- TODO: active and inactive timelines.  prolly need be in view
-- TODO: filter invalid movements and all subsequent events per game
create view state as (
  with recursive state -- TODO recursive, grouped self-join???
);

-- TODO: pawns might actually be one of the more curious constructions
-- black and white should be + and - 1 for the purposes of pawn movements as well as timelines.
-- castling + en-passant
