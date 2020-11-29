\i board.sql

create view definitions.piece_movements as (
  with starting_positions as (
    select x as start_x, y as start_y, m.n as start_w, n.n as start_z
    from board
    cross join natural_numbers m, -- TODO: should include negatives
    cross join natural_numbers n
  ),
  pawn as (
    with directions as (
      select *
      from linear_movement_basis_vectors
      -- TODO: outside of this view, filter on positivity or negativity of the y axis according to player color
    )
    select *,
      (start_x + f),
      n as steps_moved,
      false as attacking,
      'p' as sym
    from starting_positions
    cross join
      (values (1), (-1)) as piece_color
    join lines
      on  (y = piece_color)
      and (steps_taken in (1, 2))
      and (((end_x - start_x) in (-1, 0, 1)) or ((end_w - start_w) in (-1, 0, 1)))
      and (() * ()) -- TODO
  ),
  rook as (
    -- TODO
  ),
  rook as (
    -- TODO
  ),
  rook as (
    -- TODO
  ),
  rook as (
    -- TODO
  ),
  rook as (
    -- TODO
  ),
  select * from pawn
  union select * from rook
  union select * from knight
  union select * from bishop
  union select * from queen
  union select * from king
);
