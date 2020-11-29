create schema board;

create view board.natural_numbers as (
  with recursive natural_numbers as (
    select 1 as n
    union
    select (n + 1)
    from natural_numbers
  )
  select *
  from natural_numbers 
);

create view board.board as (
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

create materialized view board.linear_movement_basis_vectors as (
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
create index linear_movement on board.linear_movement_basis_vectors(num_dimensions_active);

create view board.lines as (
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

create materialized view board.initial_board as (
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
