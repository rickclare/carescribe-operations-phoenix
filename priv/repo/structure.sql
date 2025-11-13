--
-- PostgreSQL database dump
--

\restrict Oh76aKjXBHccQdAMkxqwbEHWEPvqzoHvZ47xATBZlCzqy2Dc7p4tWzapDcsMVpX

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: operators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operators (
    id bigint NOT NULL,
    email public.citext NOT NULL,
    hashed_password character varying(255),
    confirmed_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: operators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operators_id_seq OWNED BY public.operators.id;


--
-- Name: operators_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operators_tokens (
    id bigint NOT NULL,
    operator_id bigint NOT NULL,
    token bytea NOT NULL,
    context character varying(255) NOT NULL,
    sent_to character varying(255),
    authenticated_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: operators_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operators_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operators_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operators_tokens_id_seq OWNED BY public.operators_tokens.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: operators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators ALTER COLUMN id SET DEFAULT nextval('public.operators_id_seq'::regclass);


--
-- Name: operators_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators_tokens ALTER COLUMN id SET DEFAULT nextval('public.operators_tokens_id_seq'::regclass);


--
-- Name: operators operators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators
    ADD CONSTRAINT operators_pkey PRIMARY KEY (id);


--
-- Name: operators_tokens operators_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators_tokens
    ADD CONSTRAINT operators_tokens_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: operators_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX operators_email_index ON public.operators USING btree (email);


--
-- Name: operators_tokens_context_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX operators_tokens_context_token_index ON public.operators_tokens USING btree (context, token);


--
-- Name: operators_tokens_operator_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX operators_tokens_operator_id_index ON public.operators_tokens USING btree (operator_id);


--
-- Name: operators_tokens operators_tokens_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators_tokens
    ADD CONSTRAINT operators_tokens_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.operators(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict Oh76aKjXBHccQdAMkxqwbEHWEPvqzoHvZ47xATBZlCzqy2Dc7p4tWzapDcsMVpX

INSERT INTO public."schema_migrations" (version) VALUES (20250912201343);
