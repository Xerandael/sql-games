\i definitions.sql
\i events.sql

create schema computation;

create view computation.state as ( with recursive state as (
  -- TODO: how get the initial board in here?
  with board_events as (
    -- TODO: I think the moving player has to be determined by the color of the piece being moved
    with previous_state as (
      select * from state where section = 'board_events'
    ),
    new_state as (
      -- TODO: compute
      -- TODO: `moved_to_by, moved_to_at`
    )
    select * from old_state union all select * from new_state
  ),
  piece_positions as (
    with previous_state as (
      select * from state where section = 'piece_positions'
    ),
    new_state as (
      -- TODO: compute
    )
    select * from old_state union all select * from new_state
  ),
  available_moves as (
    with previous_state as (
      select * from state where section = 'available_moves'
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
      select * from state where section = 'timelines'
    ),
    new_state as (
      -- TODO: compute
    )
    select * from old_state union all select * from new_state
  ),
  pack as (
    select *
    from board_events
    full join available_moves
      on (
         select exists (select * from check_state where turn >= present)
         )
    full join timelines
      on (
         select exists (select * from check_state where turn >= present)
         )
    full join piece_positions
      on (
         select exists (select * from check_state where turn >= present)
         )
) select * from pack) select * from state);
