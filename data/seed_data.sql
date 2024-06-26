--
-- PostgreSQL database dump
--

-- Dumped from database version 12.12 (Ubuntu 12.12-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.12 (Ubuntu 12.12-0ubuntu0.20.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE ONLY public.posts DROP CONSTRAINT posts_author_id_fkey;
ALTER TABLE ONLY public.comments DROP CONSTRAINT comments_post_id_fkey;
ALTER TABLE ONLY public.comments DROP CONSTRAINT comments_author_id_fkey;
ALTER TABLE ONLY public.users DROP CONSTRAINT users_username_key;
ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
ALTER TABLE ONLY public.posts DROP CONSTRAINT posts_pkey;
ALTER TABLE ONLY public.comments DROP CONSTRAINT comments_pkey;
ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.posts ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.comments ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE public.users_id_seq;
DROP TABLE public.users;
DROP SEQUENCE public.posts_id_seq;
DROP TABLE public.posts;
DROP SEQUENCE public.comments_id_seq;
DROP TABLE public.comments;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    id integer NOT NULL,
    post_id integer NOT NULL,
    content text NOT NULL,
    creation_date timestamp without time zone DEFAULT (now())::timestamp(0) without time zone NOT NULL,
    update_date timestamp without time zone DEFAULT (now())::timestamp(0) without time zone NOT NULL,
    author_id integer NOT NULL
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id integer NOT NULL,
    title character varying(100) NOT NULL,
    content text NOT NULL,
    creation_date timestamp without time zone DEFAULT (now())::timestamp(0) without time zone NOT NULL,
    update_date timestamp without time zone DEFAULT (now())::timestamp(0) without time zone NOT NULL,
    author_id integer NOT NULL
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    password text NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.comments (id, post_id, content, creation_date, update_date, author_id) FROM stdin;
1	4	Test comment 1	2023-02-22 17:44:53	2023-02-22 17:44:53	1
2	4	Test comment 2	2023-02-22 17:45:12	2023-02-22 17:45:12	2
3	4	Test comment 3	2023-02-22 17:45:41	2023-02-22 17:45:41	3
4	5	Test comment 1	2023-02-22 17:46:25	2023-02-22 17:46:25	1
5	5	Test comment 2	2023-02-22 17:46:44	2023-02-22 17:46:44	2
6	5	Test comment 3	2023-02-22 17:47:15	2023-02-22 17:47:15	3
7	6	Test comment 1	2023-02-22 17:48:42	2023-02-22 17:48:42	1
8	6	Test comment 2	2023-02-22 17:48:47	2023-02-22 17:48:47	1
9	6	Test comment 3	2023-02-22 17:49:06	2023-02-22 17:49:06	2
10	6	Test comment 4	2023-02-22 17:49:10	2023-02-22 17:49:10	2
11	6	Test comment 5	2023-02-22 17:49:25	2023-02-22 17:49:25	3
12	6	Test comment 6	2023-02-22 17:49:29	2023-02-22 17:49:29	3
13	7	Test comment 1	2023-02-22 17:51:44	2023-02-22 17:51:44	1
14	7	Test comment 2	2023-02-22 17:51:48	2023-02-22 17:51:48	1
15	7	Test comment 3	2023-02-22 17:51:53	2023-02-22 17:51:53	1
16	7	Test comment 4	2023-02-22 17:51:58	2023-02-22 17:51:58	1
17	7	Test comment 5	2023-02-22 17:52:02	2023-02-22 17:52:02	1
18	7	Test comment 6	2023-02-22 17:52:07	2023-02-22 17:52:07	1
19	7	Test comment 7	2023-02-22 17:52:12	2023-02-22 17:52:12	1
20	7	Test comment 8	2023-02-22 17:52:17	2023-02-22 17:52:17	1
21	7	Test comment 9	2023-02-22 17:52:22	2023-02-22 17:52:22	1
22	7	Test comment 10	2023-02-22 17:52:27	2023-02-22 17:52:27	1
23	7	Test comment 11	2023-02-22 17:52:31	2023-02-22 17:52:31	1
24	8	Test comment 1	2023-02-22 17:53:09	2023-02-22 17:53:09	1
26	8	Test comment 3	2023-02-22 17:53:17	2023-02-22 17:53:17	1
27	8	Test comment 4	2023-02-22 17:53:21	2023-02-22 17:53:21	1
28	8	Test comment 5	2023-02-22 17:53:27	2023-02-22 17:53:27	1
29	8	Test comment 6	2023-02-22 17:53:31	2023-02-22 17:53:31	1
30	8	Test comment 7	2023-02-22 17:53:38	2023-02-22 17:53:38	1
25	8	Test comment 2 - Updated	2023-02-22 17:53:13	2023-02-22 17:53:46	1
\.


--
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.posts (id, title, content, creation_date, update_date, author_id) FROM stdin;
5	Test Post 5	Test post 5 content.	2023-02-22 17:46:05	2023-02-22 17:46:05	2
6	Test Post 6	Content for test post 6.	2023-02-22 17:47:41	2023-02-22 17:47:41	3
7	Test Post 7	Content for test post 7.	2023-02-22 17:50:15	2023-02-22 17:50:15	1
8	Test Post 8	Content for test post 8.	2023-02-22 17:50:27	2023-02-22 17:50:27	1
11	Test Post 11	Content for test post 11.	2023-02-22 17:51:21	2023-02-22 17:51:21	1
9	Test Post 9 - Title Updated	Test Post 9 content.	2023-02-22 17:50:40	2023-02-22 17:54:22	1
10	Test Post 10	Test post 10 content. - Content updated	2023-02-22 17:51:02	2023-02-22 17:54:33	1
1	Test Post 1	Test post 1 content.	2023-02-22 17:43:06	2023-02-22 17:43:06	1
2	Test Post 2	Content for test post 2.	2023-02-22 17:43:30	2023-02-22 17:43:30	2
3	Test Post 3	Test post 3 content.	2023-02-22 17:44:02	2023-02-22 17:44:02	3
4	Test Post 4	Content for test post 4.	2023-02-22 17:44:37	2023-02-22 17:44:37	1
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, username, password) FROM stdin;
1	admin	$2a$12$Bs3hrVu0uAh25DqX2oMjOeP76LiL0979mJT7A5GpIAGVT/xUMdcV2
2	test_user	$2a$12$4i9YE6oJQgaAllMz.MM0EOBRPONs3r7gvrCRd1vZs.ctQW1roJdD6
3	test_user_2	$2a$12$g3/6fRIwxCkNbfzhSYN4Zenfgk/M3ZpRyVl0BnF10oTQdyg2NsDcu
\.


--
-- Name: comments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.comments_id_seq', 30, true);


--
-- Name: posts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.posts_id_seq', 11, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 3, true);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: comments comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: comments comments_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: posts posts_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

