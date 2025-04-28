--Types--
set search_path = "wonks_ru";

CREATE TYPE wonks_ru.article_status AS ENUM (
    'moderated',
    'published',
    'rejected'
    );

CREATE TYPE wonks_ru.complaint_status AS ENUM (
    'dispatched',
    'pending',
    'processed'
    );

CREATE TYPE wonks_ru.user_status AS ENUM (
    'activated',
    'banned'
    );