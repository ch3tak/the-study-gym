-- Run after apply_all.sh: raises (failing CI) if the course structure didn't land.
do $$
declare n int;
begin
  select count(*) into n from units where subject_id = 'cbse_9_maths';
  if n <> 6 then raise exception 'expected 6 units, got %', n; end if;

  select count(*) into n from chapters where subject_id = 'cbse_9_maths' and unit_id is not null;
  if n <> 15 then raise exception 'expected 15 maths chapters with a unit, got %', n; end if;

  select count(*) into n from chapters where subject_id = 'cbse_9_maths' and unit_id is null;
  if n <> 0 then raise exception '% maths chapters have no unit', n; end if;

  select count(*) into n from questions where level is not null and body ? 'whyAfterPrevious';
  if n <> 62 then raise exception 'expected 62 Trial levels with whyAfterPrevious, got %', n; end if;
end $$;
