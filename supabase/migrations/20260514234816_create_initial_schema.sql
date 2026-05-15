create extension if not exists vector;

CREATE TABLE public.users (
  id uuid references auth.users (id) on delete cascade not null primary key,
  email text,
  full_name text,
  avatar_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

CREATE TABLE public.items (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users (id) on delete cascade not null,
  item_name text,
  item_code text,
  description text,
  quantity int,
  embedding vector(1536),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

CREATE TABLE public.scans(
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users (id) on delete cascade not null,
  item_id uuid references public.items (id) on delete cascade not null,
  quantity int,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email)
  values (new.id, new.email);
  return new;
end;

$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


ALTER TABLE items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access their own items"
ON items
FOR ALL
USING (auth.uid() = user_id);

ALTER TABLE scans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access their own scans"
ON scans
FOR ALL
USING (auth.uid() = user_id);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access their own profile data"
ON users
FOR ALL
USING (auth.uid() = id);