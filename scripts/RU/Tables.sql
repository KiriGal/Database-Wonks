set search_path = "wonks_ru";

CREATE TABLE Users
(
    id            SERIAL,
    avatar_url    VARCHAR(255) NOT NULL DEFAULT 'noimage.png',
    username      VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id       INTEGER      NOT NULL,
    status        USER_STATUS  NOT NULL DEFAULT 'activated',
    last_login    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE Categories
(
    id   SERIAL,
    name VARCHAR(255) NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

CREATE TABLE Comments
(
    id         SERIAL,
    article_id INTEGER      NOT NULL,
    user_id    INTEGER      NOT NULL,
    content    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (id)
);

CREATE TABLE Articles
(
    id          SERIAL,
    slug        TEXT             NOT NULL UNIQUE,
    user_id     INTEGER          NOT NULL,
    content     TEXT             NOT NULL,
    short_description TEXT NOT NULL,
    image       VARCHAR(255)     NOT NULL DEFAULT 'noimage.png',
    category_id INTEGER          NOT NULL,
    status      ARTICLE_STATUS   NOT NULL,
    title       VARCHAR(255)     NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE TABLE Tags
(
    id   SERIAL,
    name VARCHAR(255) NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

CREATE TABLE Article_tags
(
    id         SERIAL,
    tag_id     INTEGER NOT NULL,
    article_id INTEGER NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE Favourites
(
    id         SERIAL,
    user_id    INTEGER NOT NULL,
    article_id INTEGER NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE Ratings
(
    id         SERIAL,
    user_id    INTEGER NOT NULL,
    article_id INTEGER NOT NULL,
    value      INTEGER NOT NULL CHECK (value BETWEEN 1 AND 5),
    PRIMARY KEY (id)
);

CREATE TABLE Notifications
(
    id      SERIAL,
    user_id INTEGER NOT NULL,
    text    TEXT    NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE TABLE Subscriptions
(
    id                  SERIAL,
    follower_id         INTEGER NOT NULL,
    followed_id         INTEGER NOT NULL,
    notices             BOOLEAN NOT NULL DEFAULT false,
    PRIMARY KEY (id)
);

CREATE TABLE Reports
(
    id          SERIAL,
    reporter_id INTEGER            NOT NULL,
    target_id   INTEGER            NOT NULL,
    content     TEXT               NOT NULL,
    status      COMPLAINT_STATUS NOT NULL DEFAULT 'dispatched',
    date        TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE TABLE Roles
(
    id         SERIAL,
    name       VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
);

ALTER TABLE Articles
    ADD FOREIGN KEY (user_id) REFERENCES Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Articles
    ADD FOREIGN KEY (category_id) REFERENCES Categories (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Comments
    ADD FOREIGN KEY (article_id) REFERENCES Articles (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Comments
    ADD FOREIGN KEY (user_id) REFERENCES Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Article_tags
    ADD FOREIGN KEY (tag_id) REFERENCES Tags (id)
        ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE Article_tags
    ADD FOREIGN KEY (article_id) REFERENCES Articles (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Favourites
    ADD FOREIGN KEY (user_id) REFERENCES Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Favourites
    ADD FOREIGN KEY (article_id) REFERENCES Articles (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Ratings
    ADD FOREIGN KEY (user_id) REFERENCES Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Ratings
    ADD FOREIGN KEY (article_id) REFERENCES Articles (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Notifications
    ADD FOREIGN KEY (user_id) REFERENCES Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Subscriptions
    ADD FOREIGN KEY (follower_id) REFERENCES Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Subscriptions
    ADD FOREIGN KEY (followed_id) REFERENCES Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Reports
    ADD FOREIGN KEY (reporter_id) REFERENCES Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Reports
    ADD FOREIGN KEY (target_id) REFERENCES Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Users
    ADD FOREIGN KEY (role_id) REFERENCES Roles (id)
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE Subscriptions
    ADD CONSTRAINT fk_subscriptions_follower FOREIGN KEY (follower_id) REFERENCES Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Subscriptions
    ADD CONSTRAINT fk_subscriptions_followed FOREIGN KEY (followed_id) REFERENCES Users (id)
        ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE Subscriptions
    ADD CONSTRAINT uq_follower_followed UNIQUE (follower_id, followed_id);

ALTER TABLE Article_tags
    ADD CONSTRAINT uq_article_tags_article_tag UNIQUE (article_id, tag_id);

ALTER TABLE Favourites
    ADD CONSTRAINT uq_favourites_user_article UNIQUE (user_id, article_id);

ALTER TABLE Ratings
    ADD CONSTRAINT uq_ratings_user_article UNIQUE (user_id, article_id);
