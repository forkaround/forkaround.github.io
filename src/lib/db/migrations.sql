CREATE TABLE IF NOT EXISTS todo(
  id serial PRIMARY KEY,
  task text,
  done boolean DEFAULT FALSE
);

