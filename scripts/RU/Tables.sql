set search_path = "wonks_ru";

CREATE TABLE wonks_ru.Users
(
    id            SERIAL,
    avatar_url    VARCHAR(255) NOT NULL DEFAULT 'noimage.png',
    username      VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id       INTEGER      NOT NULL,
    status        USER_STATUS  NOT NULL DEFAULT 'activated',
    last_login    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE wonks_ru.Categories
(
    id   SERIAL,
    name VARCHAR(255) NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

CREATE TABLE wonks_ru.Comments
(
    id         SERIAL,
    article_id INTEGER      NOT NULL,
    user_id    INTEGER      NOT NULL,
    content    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (id)
);

CREATE TABLE wonks_ru.Articles
(
    id          SERIAL,
    slug        TEXT             NOT NULL UNIQUE,
    user_id     INTEGER          NOT NULL,
    content     TEXT             NOT NULL,
    short_description TEXT NOT NULL,
    image       VARCHAR(255)     NOT NULL DEFAULT 'noimage.png',
    category_id INTEGER          NOT NULL,
    status      ARTICLE_STATUS NOT NULL,
    title       VARCHAR(255)     NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE TABLE wonks_ru.Tags
(
    id   SERIAL,
    name VARCHAR(255) NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

CREATE TABLE wonks_ru.Article_tags
(
    id         SERIAL,
    tag_id     INTEGER NOT NULL,
    article_id INTEGER NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE wonks_ru.Favourites
(
    id         SERIAL,
    user_id    INTEGER NOT NULL,
    article_id INTEGER NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE wonks_ru.Ratings
(
    id         SERIAL,
    user_id    INTEGER NOT NULL,
    article_id INTEGER NOT NULL,
    value      INTEGER NOT NULL CHECK (value BETWEEN 1 AND 5),
    PRIMARY KEY (id)
);

CREATE TABLE wonks_ru.Notifications
(
    id      SERIAL,
    user_id INTEGER NOT NULL,
    text    TEXT    NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE TABLE wonks_ru.Subscriptions
(
    id                  SERIAL,
    follower_id         INTEGER NOT NULL,
    followed_id         INTEGER NOT NULL,
    notices             BOOLEAN NOT NULL DEFAULT false,
    PRIMARY KEY (id)
);

CREATE TABLE wonks_ru.Reports
(
    id          SERIAL,
    reporter_id INTEGER            NOT NULL,
    target_id   INTEGER            NOT NULL,
    content     TEXT               NOT NULL,
    status      COMPLAINT_STATUS NOT NULL DEFAULT 'dispatched',
    date        TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE TABLE wonks_ru.Roles
(
    id         SERIAL,
    name       VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
);

ALTER TABLE wonks_ru.Articles
    ADD FOREIGN KEY (user_id) REFERENCES wonks_ru.Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Articles
    ADD FOREIGN KEY (category_id) REFERENCES wonks_ru.Categories (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Comments
    ADD FOREIGN KEY (article_id) REFERENCES wonks_ru.Articles (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Comments
    ADD FOREIGN KEY (user_id) REFERENCES wonks_ru.Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Article_tags
    ADD FOREIGN KEY (tag_id) REFERENCES wonks_ru.Tags (id)
        ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE wonks_ru.Article_tags
    ADD FOREIGN KEY (article_id) REFERENCES wonks_ru.Articles (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Favourites
    ADD FOREIGN KEY (user_id) REFERENCES wonks_ru.Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Favourites
    ADD FOREIGN KEY (article_id) REFERENCES wonks_ru.Articles (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Ratings
    ADD FOREIGN KEY (user_id) REFERENCES wonks_ru.Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Ratings
    ADD FOREIGN KEY (article_id) REFERENCES wonks_ru.Articles (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Notifications
    ADD FOREIGN KEY (user_id) REFERENCES wonks_ru.Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Subscriptions
    ADD FOREIGN KEY (follower_id) REFERENCES wonks_ru.Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Subscriptions
    ADD FOREIGN KEY (followed_id) REFERENCES wonks_ru.Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Reports
    ADD FOREIGN KEY (reporter_id) REFERENCES wonks_ru.Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Reports
    ADD FOREIGN KEY (target_id) REFERENCES wonks_ru.Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Users
    ADD FOREIGN KEY (role_id) REFERENCES wonks_ru.Roles (id)
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE wonks_ru.Subscriptions
    ADD CONSTRAINT fk_subscriptions_follower FOREIGN KEY (follower_id) REFERENCES wonks_ru.Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Subscriptions
    ADD CONSTRAINT fk_subscriptions_followed FOREIGN KEY (followed_id) REFERENCES wonks_ru.Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE wonks_ru.Subscriptions
    ADD CONSTRAINT uq_follower_followed UNIQUE (follower_id, followed_id);

ALTER TABLE wonks_ru.Article_tags
    ADD CONSTRAINT uq_article_tags_article_tag UNIQUE (article_id, tag_id);

ALTER TABLE wonks_ru.Favourites
    ADD CONSTRAINT uq_favourites_user_article UNIQUE (user_id, article_id);

ALTER TABLE wonks_ru.Ratings
    ADD CONSTRAINT uq_ratings_user_article UNIQUE (user_id, article_id);
