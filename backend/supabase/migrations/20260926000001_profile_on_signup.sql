-- Auto-create a profiles row (and a streaks row) when a new auth user signs
-- up, so the client never has to insert into profiles itself and RLS's
-- `own_profile` policy always has a row to match against.

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id) values (new.id);
  insert into public.streaks (user_id) values (new.id);
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
