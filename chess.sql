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
  with starting_positions as (
    select x as start_x, y as start_y, m.n as start_w, n.n as start_z
    from board
    cross join natural_numbers m,
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
    cross join natural_numbers n -- TODO: use in arithmetic condition for moving 2 squares
    cross join (values (1), (-1)) as piece_color -- TODO use in multiplication?
    cross join directions -- TODO?
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

create view state as (
  with recursive state as (
    -- TODO: how get the initial board in here?
    with board_events as (
      -- TODO: I think the moving player has to be determined by the color of the piece being moved
      with previous_state as (
        -- TODO: unpack
      ),
      new_state as (
        -- TODO: compute
        -- TODO: `moved_to_by, moved_to_at`
      )
      select * from old_state union all select * from new_state
    ),
    piece_positions as (
      with previous_state as (
        -- TODO: unpack
      ),
      new_state as (
        -- TODO: compute
      )
      select * from old_state union all select * from new_state
    ),
    available_moves as (
      with previous_state as (
        -- TODO: unpack
      ),
      new_state as (
        -- TODO: compute
        -- TODO:  join positions of moveable pieces against piece movements
        -- TODO: check for board edges, then check for pieces between the lines cast from the starting position.  Allow ending on an enemy but not an ally.
        -- join against the set of all pieces on whether they're linearly-between the start and end
      )
      select * from old_state union all select * from new_state
    ),
    timelines as (
      with previous_state as (
        -- TODO: unpack
      ),
      new_state as (
        -- TODO: compute
      )
      select * from old_state union all select * from new_state
    ),
    pack as (
      select *
      from board_events
      full join available_moves on 0 = 1
      full join timelines       on 0 = 1
      full join piece_positions on 0 = 1
    )
    select *
    from pack
  )
  select *
  from state
);
