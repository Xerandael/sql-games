-- 5-dimensional chess in SQL

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

create view pieces as (
  with pieces(type) as (
    values
      ('pawn'),
      ('rook'),
      ('knight'),
      ('bishop'),
      ('queen'),
      ('king')
  )
  select *
  from pieces
);

-- TODO: active and inactive timelines.  prolly need be in view
create table piece_squares( -- TODO: this should be a view built from events over time.  self-join of recursive view?
  game int not null,
  turn int not null check (turn > 0 && ((turn > 1) || (prev is null))),
  prev int references squares(turn) check ((prev is null) || ((turn - prev) = 1)),
  timeline int  -- timeline_above, timeline_below -- can't have both -- only need one -- maybe can take advantage of the natural ordering of the integers.  Move toward zero?  FK(abs(thing) - 1)
);

-- TODO: pawns might actually be one of the more curious constructions
-- black and white should be + and - 1 for the purposes of pawn movements as well as timelines.
-- castling + en-passant
