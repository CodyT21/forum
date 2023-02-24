CREATE DATABASE forum;
\c forum

CREATE TABLE users (
  id serial PRIMARY KEY,
  username varchar(50) NOT NULL UNIQUE,
  password text NOT NULL
);

CREATE TABLE posts (
  id serial PRIMARY KEY,
  title varchar(100) NOT NULL,
  content text NOT NULL,
  creation_date TIMESTAMP NOT NULL DEFAULT NOW()::TIMESTAMP(0),
  update_date TIMESTAMP NOT NULL DEFAULT NOW()::TIMESTAMP(0),
  author_id integer NOT NULL REFERENCES users (id)
);

CREATE TABLE comments (
  id serial PRIMARY KEY,
  post_id integer NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
  content text NOT NULL,
  creation_date TIMESTAMP NOT NULL DEFAULT NOW()::TIMESTAMP(0),
  update_date TIMESTAMP NOT NULL DEFAULT NOW()::TIMESTAMP(0),
  author_id integer NOT NULL REFERENCES users (id)
);
