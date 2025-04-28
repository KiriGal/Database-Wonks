set search_path = "wonks_ru";
CREATE EXTENSION IF NOT EXISTS pgcrypto;
--Functions--

CREATE OR REPLACE FUNCTION wonks_ru.update_article_timestamp()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION wonks_ru.prevent_self_subscription()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.follower_id = NEW.followed_id THEN
        RAISE EXCEPTION 'Пользователь не может подписаться сам на себя.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION wonks_ru.notify_article_author_on_comment()
    RETURNS TRIGGER AS
$$
DECLARE
    article_owner_id   INTEGER;
    commenter_username VARCHAR(255);
BEGIN
    SELECT user_id INTO article_owner_id FROM wonks_ru.Articles WHERE id = NEW.article_id;
    SELECT username INTO commenter_username FROM wonks_ru.Users WHERE id = NEW.user_id;

    IF article_owner_id <> NEW.user_id THEN
        INSERT INTO wonks_ru.Notifications(user_id, text)
        VALUES (article_owner_id, CONCAT('Новый комментарий от пользователя ', commenter_username, ' к вашей статье.'));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION wonks_ru.notify_followers_on_article_published()
    RETURNS TRIGGER AS
$$
DECLARE
    follower RECORD;
BEGIN
    IF OLD.status IS DISTINCT FROM 'published' AND NEW.status = 'published' THEN
        FOR follower IN
            SELECT follower_id
            FROM wonks_ru.Subscriptions
            WHERE followed_id = NEW.follower_id
              AND notices = true
            LOOP
                INSERT INTO wonks_ru.Notifications(user_id, text)
                VALUES (follower.follower_id,
                        CONCAT(
                                'Пользователь, на которого вы подписаны, опубликовал статью "',
                                NEW.title, '".'
                        ));
            END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION wonks_ru.get_articles_paginated_filtered(
    _limit INTEGER DEFAULT 10,
    _offset INTEGER DEFAULT 0,
    filter_id INTEGER DEFAULT NULL,
    filter_slug TEXT DEFAULT NULL,
    filter_title TEXT DEFAULT NULL,
    filter_category_name TEXT DEFAULT NULL,
    filter_tags TEXT[] DEFAULT NULL,
    filter_created_at_start TIMESTAMPTZ DEFAULT NULL,
    filter_created_at_end TIMESTAMPTZ DEFAULT NULL
)
    RETURNS TABLE
            (
                id                INTEGER,
                slug              TEXT,
                title             TEXT,
                content           TEXT,
                short_description TEXT,
                created_at        TIMESTAMPTZ,
                updated_at        TIMESTAMPTZ,
                image             TEXT,
                category_name     TEXT,
                tags              TEXT[],
                rating            NUMERIC
            )
    LANGUAGE plpgsql SECURITY DEFINER
AS
$$
DECLARE
    query         TEXT;
    where_clauses TEXT[] := '{}';
BEGIN
    query := 'SELECT id, slug, title, content, short_description, created_at, updated_at, image, category_name, tags, rating
              FROM wonks_ru.view_articles';

    IF filter_id IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('id = %L', filter_id));
    END IF;

    IF filter_slug IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('slug = %L', filter_slug));
    END IF;

    IF filter_title IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('title ILIKE %L', '%' || filter_title || '%'));
    END IF;

    IF filter_category_name IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('category_name = %L', filter_category_name));
    END IF;

    IF filter_tags IS NOT NULL AND array_length(filter_tags, 1) > 0 THEN
        where_clauses := array_append(where_clauses, format('tags @> %L', filter_tags));
    END IF;

    IF filter_created_at_start IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('created_at >= %L', filter_created_at_start));
    END IF;

    IF filter_created_at_end IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('created_at <= %L', filter_created_at_end));
    END IF;

    IF array_length(where_clauses, 1) > 0 THEN
        query := query || ' WHERE ' || array_to_string(where_clauses, ' AND ');
    END IF;

    query := query || format(' ORDER BY id DESC LIMIT %L OFFSET %L', _limit, _offset);

    RAISE NOTICE 'Executing query: %', query;

    RETURN QUERY EXECUTE query;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.get_article_comments_paginated_filtered(
    _limit INTEGER DEFAULT 10,
    _offset INTEGER DEFAULT 0,
    filter_article_slug TEXT DEFAULT NULL,
    filter_username TEXT DEFAULT NULL,
    filter_content TEXT DEFAULT NULL,
    filter_created_at_start TIMESTAMPTZ DEFAULT NULL,
    filter_created_at_end TIMESTAMPTZ DEFAULT NULL
)
    RETURNS TABLE
            (
                comment_id   INTEGER,
                article_slug TEXT,
                username     TEXT,
                content      TEXT,
                created_at   TIMESTAMPTZ
            )
    LANGUAGE plpgsql SECURITY DEFINER
AS
$$
DECLARE
    query         TEXT;
    where_clauses TEXT[] := '{}';
BEGIN
    query := 'SELECT comment_id, article_slug, username, content, created_at
              FROM wonks_ru.view_article_comments';

    IF filter_article_slug IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('article_slug = %L', filter_article_slug));
    END IF;

    IF filter_username IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('username = %L', filter_username));
    END IF;

    IF filter_content IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('content ILIKE %L', '%' || filter_content || '%'));
    END IF;

    IF filter_created_at_start IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('created_at >= %L', filter_created_at_start));
    END IF;

    IF filter_created_at_end IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('created_at <= %L', filter_created_at_end));
    END IF;

    IF array_length(where_clauses, 1) > 0 THEN
        query := query || ' WHERE ' || array_to_string(where_clauses, ' AND ');
    END IF;

    query := query || format(' ORDER BY created_at DESC LIMIT %L OFFSET %L', _limit, _offset);

    RAISE NOTICE 'Executing query: %', query;
    RETURN QUERY EXECUTE query;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.get_user_favourite_articles_paginated_filtered(
    _limit INTEGER DEFAULT 10,
    _offset INTEGER DEFAULT 0,
    filter_user_id INTEGER DEFAULT NULL,
    filter_username TEXT DEFAULT NULL,
    filter_article_slug TEXT DEFAULT NULL,
    filter_article_title TEXT DEFAULT NULL
)
    RETURNS TABLE
            (
                favourite_id      INTEGER,
                user_id           INTEGER,
                username          TEXT,
                slug              TEXT,
                title             TEXT,
                image             TEXT,
                short_description TEXT
            )
    LANGUAGE plpgsql SECURITY DEFINER
AS
$$
DECLARE
    query         TEXT;
    where_clauses TEXT[] := '{}';
BEGIN

    query := 'SELECT favourite_id, user_id, username, slug, title, image, short_description
              FROM wonks_ru.view_user_favourite_articles';

    IF filter_user_id IS NOT NULL THEN

        where_clauses := array_append(where_clauses, format('user_id = %L', filter_user_id));
    END IF;

    IF filter_username IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('username = %L', filter_username));
    END IF;

    IF filter_article_slug IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('slug = %L', filter_article_slug));
    END IF;

    IF filter_article_title IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('title ILIKE %L', '%' || filter_article_title || '%'));
    END IF;

    IF array_length(where_clauses, 1) > 0 THEN
        query := query || ' WHERE ' || array_to_string(where_clauses, ' AND ');
    END IF;


    query := query || format(' ORDER BY favourite_id DESC LIMIT %L OFFSET %L', _limit, _offset);

    RAISE NOTICE 'Executing query: %', query;
    RETURN QUERY EXECUTE query;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.get_user_notifications_paginated_filtered(
    _limit INTEGER DEFAULT 10,
    _offset INTEGER DEFAULT 0,
    filter_recipient_id INTEGER DEFAULT NULL,
    filter_recipient_username TEXT DEFAULT NULL,
    filter_text TEXT DEFAULT NULL,
    filter_created_at_start TIMESTAMPTZ DEFAULT NULL,
    filter_created_at_end TIMESTAMPTZ DEFAULT NULL
)
    RETURNS TABLE
            (
                notification_id    INTEGER,
                recipient_id       INTEGER,
                recipient_username TEXT,
                text               TEXT,
                created_at         TIMESTAMPTZ
            )
    LANGUAGE plpgsql SECURITY DEFINER
AS
$$
DECLARE
    query         TEXT;
    where_clauses TEXT[] := '{}';
BEGIN

    query := 'SELECT notification_id, recipient_id, recipient_username, text, created_at
              FROM wonks_ru.view_user_notification';

    IF filter_recipient_id IS NOT NULL THEN

        where_clauses := array_append(where_clauses, format('recipient_id = %L', filter_recipient_id));
    END IF;

    IF filter_recipient_username IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('recipient_username = %L', filter_recipient_username));
    END IF;

    IF filter_text IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('text ILIKE %L', '%' || filter_text || '%'));
    END IF;

    IF filter_created_at_start IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('created_at >= %L', filter_created_at_start));
    END IF;

    IF filter_created_at_end IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('created_at <= %L', filter_created_at_end));
    END IF;


    IF array_length(where_clauses, 1) > 0 THEN
        query := query || ' WHERE ' || array_to_string(where_clauses, ' AND ');
    END IF;


    query := query || format(' ORDER BY created_at DESC, notification_id DESC LIMIT %L OFFSET %L', _limit, _offset);

    RAISE NOTICE 'Executing query: %', query;
    RETURN QUERY EXECUTE query;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.get_user_subscriptions_paginated_filtered(
    _limit INTEGER DEFAULT 10,
    _offset INTEGER DEFAULT 0,
    filter_followed_id INTEGER DEFAULT NULL,
    filter_follower_id INTEGER DEFAULT NULL,
    filter_followed_username TEXT DEFAULT NULL,
    filter_follower_username TEXT DEFAULT NULL,
    filter_notices BOOLEAN DEFAULT NULL
)
    RETURNS TABLE
            (
                followed_id       INTEGER,
                follower_id       INTEGER,
                followed_username TEXT,
                follower_username TEXT,
                notices           BOOLEAN
            )
    LANGUAGE plpgsql SECURITY DEFINER
AS
$$
DECLARE
    query         TEXT;
    where_clauses TEXT[] := '{}';
BEGIN

    query := 'SELECT followed_id, follower_id, followed_username, follower_username, notices
              FROM wonks_ru.view_user_subscription';

    IF filter_followed_id IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('followed_id = %L', filter_followed_id));
    END IF;

    IF filter_follower_id IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('follower_id = %L', filter_follower_id));
    END IF;

    IF filter_followed_username IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('followed_username = %L', filter_followed_username));
    END IF;

    IF filter_follower_username IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('follower_username = %L', filter_follower_username));
    END IF;

    IF filter_notices IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('notices = %L', filter_notices));
    END IF;

    IF array_length(where_clauses, 1) > 0 THEN
        query := query || ' WHERE ' || array_to_string(where_clauses, ' AND ');
    END IF;


    query := query ||
             format(' ORDER BY followed_username ASC, follower_username ASC LIMIT %L OFFSET %L', _limit, _offset);

    RAISE NOTICE 'Executing query: %', query;
    RETURN QUERY EXECUTE query;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.get_reports_paginated_filtered(
    _limit INTEGER DEFAULT 10,
    _offset INTEGER DEFAULT 0,
    filter_reporter_username TEXT DEFAULT NULL,
    filter_target_username TEXT DEFAULT NULL,
    filter_status TEXT DEFAULT NULL,
    filter_date_start TIMESTAMPTZ DEFAULT NULL,
    filter_date_end TIMESTAMPTZ DEFAULT NULL
)
    RETURNS TABLE
            (
                report_id         INTEGER,
                target_id         INTEGER,
                reporter_username TEXT,
                target_username   TEXT,
                content           TEXT,
                status            TEXT,
                date              TIMESTAMPTZ
            )
    LANGUAGE plpgsql SECURITY DEFINER
AS
$$
DECLARE
    query         TEXT;
    where_clauses TEXT[] := '{}';
BEGIN

    query := 'SELECT report_id, target_id, reporter_username, target_username, content, status, date
              FROM wonks_ru.view_reports';

    IF filter_reporter_username IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('reporter_username = %L', filter_reporter_username));
    END IF;

    IF filter_target_username IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('target_username = %L', filter_target_username));
    END IF;

    IF filter_status IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('status = %L', filter_status));
    END IF;

    IF filter_date_start IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('date >= %L', filter_date_start));
    END IF;

    IF filter_date_end IS NOT NULL THEN
        where_clauses := array_append(where_clauses, format('date <= %L', filter_date_end));
    END IF;


    IF array_length(where_clauses, 1) > 0 THEN
        query := query || ' WHERE ' || array_to_string(where_clauses, ' AND ');
    END IF;


    query := query || format(' ORDER BY date DESC LIMIT %L OFFSET %L', _limit, _offset);

    RAISE NOTICE 'Executing query: %', query;
    RETURN QUERY EXECUTE query;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.register_user(
    _username VARCHAR(255),
    _email VARCHAR(255),
    _plain_password TEXT
)
    RETURNS TABLE (
                      registered_user_id INTEGER,
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _hashed_password TEXT;
    _user_role_id INTEGER;
    _existing_user_id INTEGER;
    _new_user_id INTEGER := NULL;
BEGIN
    SELECT id INTO _existing_user_id FROM wonks_ru.Users WHERE lower(email) = lower(_email);
    IF FOUND THEN
        RETURN QUERY SELECT NULL::INTEGER, 'EMAIL_EXISTS'::TEXT, 'Email already registered.'::TEXT;
        RETURN;
    END IF;

    SELECT id INTO _existing_user_id FROM wonks_ru.Users WHERE lower(username) = lower(_username);
    IF FOUND THEN
        RETURN QUERY SELECT NULL::INTEGER, 'USERNAME_EXISTS'::TEXT, 'Username already taken.'::TEXT;
        RETURN;
    END IF;

    SELECT id INTO _user_role_id FROM wonks_ru.Roles WHERE name = 'User';
    IF NOT FOUND THEN
        RAISE WARNING 'Default role "User" not found in wonks_ru.Roles table.';
        RETURN QUERY SELECT NULL::INTEGER, 'ROLE_NOT_FOUND'::TEXT, 'Default user role configuration error.'::TEXT;
        RETURN;
    END IF;

    _hashed_password := crypt(_plain_password, gen_salt('bf'));

    INSERT INTO wonks_ru.Users (username, email, password_hash, role_id)
    VALUES (_username, _email, _hashed_password, _user_role_id)
    RETURNING id INTO _new_user_id;

    IF _new_user_id IS NOT NULL THEN
        RETURN QUERY SELECT _new_user_id, 'OK'::TEXT, 'User registered successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Failed to insert user record.'::TEXT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error during user registration: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'An unexpected error occurred during registration: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.authenticate_user(
    _identifier TEXT,
    _plain_password TEXT
)
    RETURNS TABLE (
                      authenticated_user_id INTEGER,
                      user_role_id INTEGER,
                      username VARCHAR(255),
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _user_record RECORD;
BEGIN
    SELECT
        id,
        password_hash,
        role_id,
        status,
        u.username
    INTO _user_record
    FROM wonks_ru.Users u
    WHERE lower(u.email) = lower(_identifier) OR lower(u.username) = lower(_identifier);

    IF NOT FOUND THEN
        RETURN QUERY SELECT NULL::INTEGER, NULL::INTEGER, NULL::VARCHAR, 'NOT_FOUND'::TEXT, 'User not found.'::TEXT;
        RETURN;
    END IF;

    IF _user_record.status <> 'activated' THEN
        RETURN QUERY SELECT NULL::INTEGER, NULL::INTEGER, NULL::VARCHAR, 'INACTIVE'::TEXT, 'User account is not active.'::TEXT;
        RETURN;
    END IF;

    IF _user_record.password_hash = crypt(_plain_password, _user_record.password_hash) THEN
        RETURN QUERY SELECT
                         _user_record.id,
                         _user_record.role_id,
                         _user_record.username,
                         'OK'::TEXT,
                         'Authentication successful.'::TEXT;
    ELSE
        RETURN QUERY SELECT NULL::INTEGER, NULL::INTEGER, NULL::VARCHAR, 'WRONG_PASSWORD'::TEXT, 'Incorrect password.'::TEXT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error during user authentication: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, NULL::INTEGER, NULL::VARCHAR, 'ERROR'::TEXT, 'An unexpected error occurred during authentication: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.subscribe_to_user(
    _follower_id INTEGER,
    _followed_id INTEGER,
    _receive_notices BOOLEAN DEFAULT false
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _follower_exists BOOLEAN;
    _followed_exists BOOLEAN;
BEGIN
    IF _follower_id = _followed_id THEN
        RETURN QUERY SELECT 'SELF_SUBSCRIPTION'::TEXT, 'Cannot subscribe to yourself.'::TEXT; RETURN;
    END IF;
    SELECT EXISTS (SELECT 1 FROM wonks_ru.Users WHERE id = _follower_id) INTO _follower_exists;
    IF NOT _follower_exists THEN
        RETURN QUERY SELECT 'FOLLOWER_NOT_FOUND'::TEXT, 'Follower user not found.'::TEXT; RETURN;
    END IF;
    SELECT EXISTS (SELECT 1 FROM wonks_ru.Users WHERE id = _followed_id) INTO _followed_exists;
    IF NOT _followed_exists THEN
        RETURN QUERY SELECT 'FOLLOWED_NOT_FOUND'::TEXT, 'User to follow not found.'::TEXT; RETURN;
    END IF;

    INSERT INTO wonks_ru.Subscriptions (follower_id, followed_id, notices)
    VALUES (_follower_id, _followed_id, _receive_notices)
    ON CONFLICT (follower_id, followed_id)
        DO NOTHING;

    RETURN QUERY SELECT 'OK'::TEXT, 'Successfully subscribed (or already subscribed).'::TEXT;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error during subscription: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred during subscription: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.unsubscribe_from_user(
    _follower_id INTEGER,
    _followed_id INTEGER
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _row_count INTEGER;
BEGIN
    IF _follower_id = _followed_id THEN
        RETURN QUERY SELECT 'SELF_UNSUBSCRIPTION'::TEXT, 'Cannot unsubscribe from yourself.'::TEXT; RETURN;
    END IF;

    DELETE FROM wonks_ru.Subscriptions
    WHERE follower_id = _follower_id AND followed_id = _followed_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, 'Successfully unsubscribed.'::TEXT;
    ELSE
        RETURN QUERY SELECT 'NOT_SUBSCRIBED'::TEXT, 'Was not subscribed to this user.'::TEXT;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error during unsubscription: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred during unsubscription: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.set_subscription_notices(
    _follower_id INTEGER,
    _followed_id INTEGER,
    _enable_notices BOOLEAN
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _row_count INTEGER;
BEGIN
    UPDATE wonks_ru.Subscriptions
    SET notices = _enable_notices
    WHERE follower_id = _follower_id AND followed_id = _followed_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;

    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, format('Notification setting for following user %s set to %s.', _followed_id, _enable_notices);
    ELSE
        RETURN QUERY SELECT 'NOT_FOUND'::TEXT, format('Subscription from user %s to user %s not found.', _follower_id, _followed_id);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error setting subscription notices: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred while setting notices: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.add_comment(
    _user_id INTEGER,
    _article_id INTEGER,
    _content TEXT
)
    RETURNS TABLE (
                      new_comment_id INTEGER,
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _trimmed_content TEXT;
    _inserted_id INTEGER := NULL;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Users WHERE id = _user_id) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'USER_NOT_FOUND'::TEXT, 'User not found.'::TEXT;
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Articles WHERE id = _article_id) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'ARTICLE_NOT_FOUND'::TEXT, 'Article not found.'::TEXT;
        RETURN;
    END IF;

    _trimmed_content := TRIM(_content);
    IF _trimmed_content IS NULL OR _trimmed_content = '' THEN
        RETURN QUERY SELECT NULL::INTEGER, 'EMPTY_CONTENT'::TEXT, 'Comment content cannot be empty.'::TEXT;
        RETURN;
    END IF;

    INSERT INTO wonks_ru.Comments (user_id, article_id, content)
    VALUES (_user_id, _article_id, _trimmed_content)
    RETURNING id INTO _inserted_id;

    IF _inserted_id IS NOT NULL THEN
        RETURN QUERY SELECT _inserted_id, 'OK'::TEXT, 'Comment added successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Failed to insert comment record.'::TEXT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error adding comment: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'An unexpected error occurred while adding the comment: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.edit_comment(
    _comment_id INTEGER,
    _user_id INTEGER,
    _new_content TEXT
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _original_author_id INTEGER;
    _trimmed_content TEXT;
    _row_count INTEGER;
BEGIN
    SELECT user_id INTO _original_author_id FROM wonks_ru.Comments WHERE id = _comment_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'NOT_FOUND'::TEXT, 'Comment not found.'::TEXT;
        RETURN;
    END IF;

    IF _original_author_id <> _user_id THEN
        RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'You do not have permission to edit this comment.'::TEXT;
        RETURN;
    END IF;

    _trimmed_content := TRIM(_new_content);
    IF _trimmed_content IS NULL OR _trimmed_content = '' THEN
        RETURN QUERY SELECT 'EMPTY_CONTENT'::TEXT, 'Comment content cannot be empty.'::TEXT;
        RETURN;
    END IF;

    UPDATE wonks_ru.Comments
    SET content = _trimmed_content
    WHERE id = _comment_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, 'Comment updated successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to update comment, possibly due to concurrent deletion.'::TEXT;
    END IF;


EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error editing comment: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred while editing the comment: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.delete_comment(
    _comment_id INTEGER,
    _user_id INTEGER
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _original_author_id INTEGER;
    _row_count INTEGER;
BEGIN
    SELECT user_id INTO _original_author_id FROM wonks_ru.Comments WHERE id = _comment_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'NOT_FOUND'::TEXT, 'Comment not found.'::TEXT;
        RETURN;
    END IF;

    IF _original_author_id <> _user_id THEN
        RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'You do not have permission to delete this comment.'::TEXT;
        RETURN;
    END IF;

    DELETE FROM wonks_ru.Comments
    WHERE id = _comment_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, 'Comment deleted successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to delete comment, possibly already deleted.'::TEXT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error deleting comment: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred while deleting the comment: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.add_to_favourites(
    _user_id INTEGER,
    _article_id INTEGER
)
    RETURNS TABLE (
                      new_favourite_id INTEGER,
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _inserted_id INTEGER := NULL;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Users WHERE id = _user_id) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'USER_NOT_FOUND'::TEXT, 'User not found.'::TEXT;
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Articles WHERE id = _article_id) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'ARTICLE_NOT_FOUND'::TEXT, 'Article not found.'::TEXT;
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM wonks_ru.Favourites WHERE user_id = _user_id AND article_id = _article_id) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'ALREADY_EXISTS'::TEXT, 'Article is already in favourites.'::TEXT;
        RETURN;
    END IF;

    INSERT INTO wonks_ru.Favourites (user_id, article_id)
    VALUES (_user_id, _article_id)
    ON CONFLICT (user_id, article_id)
        DO NOTHING
    RETURNING id INTO _inserted_id;

    IF _inserted_id IS NOT NULL THEN
        RETURN QUERY SELECT _inserted_id, 'OK'::TEXT, 'Article added to favourites successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Failed to add favourite record (or constraint violation occurred).'::TEXT;
    END IF;


EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error adding favourite: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'An unexpected error occurred while adding favourite: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.remove_from_favourites(
    _user_id INTEGER,
    _article_id INTEGER
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _row_count INTEGER;
BEGIN
    DELETE FROM wonks_ru.Favourites
    WHERE user_id = _user_id AND article_id = _article_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;

    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, 'Article removed from favourites successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT 'NOT_FOUND'::TEXT, 'Article was not in favourites for this user.'::TEXT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error removing favourite: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred while removing favourite: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.set_article_rating(
    _user_id INTEGER,
    _article_id INTEGER,
    _rating_value INTEGER
)
    RETURNS TABLE (
                      rating_record_id INTEGER,
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _upserted_id INTEGER := NULL;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Users WHERE id = _user_id) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'USER_NOT_FOUND'::TEXT, 'User not found.'::TEXT;
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Articles WHERE id = _article_id) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'ARTICLE_NOT_FOUND'::TEXT, 'Article not found.'::TEXT;
        RETURN;
    END IF;

    IF _rating_value < 1 OR _rating_value > 5 THEN
        RETURN QUERY SELECT NULL::INTEGER, 'INVALID_RATING'::TEXT, 'Rating value must be between 1 and 5.'::TEXT;
        RETURN;
    END IF;

    INSERT INTO wonks_ru.Ratings (user_id, article_id, value)
    VALUES (_user_id, _article_id, _rating_value)
    ON CONFLICT (user_id, article_id)
        DO UPDATE SET
        value = EXCLUDED.value
    RETURNING id INTO _upserted_id;

    IF _upserted_id IS NOT NULL THEN
        RETURN QUERY SELECT _upserted_id, 'OK'::TEXT, 'Article rating set/updated successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Failed to set/update rating record.'::TEXT;
    END IF;

EXCEPTION
    WHEN CHECK_VIOLATION THEN
        RAISE WARNING 'Check violation during rating: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'INVALID_RATING'::TEXT, 'Rating value is outside the allowed range (1-5).';
    WHEN OTHERS THEN
        RAISE WARNING 'Error setting rating: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'An unexpected error occurred while setting the rating: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.remove_article_rating(
    _user_id INTEGER,
    _article_id INTEGER
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _row_count INTEGER;
BEGIN
    DELETE FROM wonks_ru.Ratings
    WHERE user_id = _user_id AND article_id = _article_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;

    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, 'Article rating removed successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT 'NOT_FOUND'::TEXT, 'No rating found for this user and article.'::TEXT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error removing rating: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred while removing the rating: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.create_article(
    _user_id INTEGER,
    _title VARCHAR(255),
    _slug TEXT,
    _content TEXT,
    _short_description TEXT,
    _category_id INTEGER,
    _status ARTICLE_STATUS,
    _image VARCHAR(255) DEFAULT NULL,
    _tags TEXT[] DEFAULT NULL
)
    RETURNS TABLE (
                      new_article_id INTEGER,
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _inserted_article_id INTEGER := NULL;
    _tag_id INTEGER;
    _tag_name TEXT;
    _final_image VARCHAR(255);
BEGIN
    IF _user_id IS NULL OR _title IS NULL OR TRIM(_title) = '' OR _slug IS NULL OR TRIM(_slug) = '' OR
       _content IS NULL OR TRIM(_content) = '' OR _short_description IS NULL OR TRIM(_short_description) = '' OR
       _category_id IS NULL OR _status IS NULL
    THEN
        RETURN QUERY SELECT NULL::INTEGER, 'INVALID_INPUT'::TEXT, 'Required fields (user, title, slug, content, short_description, category, status) cannot be empty.'::TEXT;
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Users WHERE id = _user_id) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'USER_NOT_FOUND'::TEXT, 'Author user not found.'::TEXT;
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Categories WHERE id = _category_id) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'CATEGORY_NOT_FOUND'::TEXT, 'Category not found.'::TEXT;
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM wonks_ru.Articles WHERE lower(title) = lower(_title)) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'TITLE_EXISTS'::TEXT, 'Article title already exists.'::TEXT;
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM wonks_ru.Articles WHERE slug = _slug) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'SLUG_EXISTS'::TEXT, 'Article slug already exists.'::TEXT;
        RETURN;
    END IF;

    _final_image := COALESCE(_image, (SELECT column_default FROM information_schema.columns
                                      WHERE table_schema = 'wonks_ru' AND table_name = 'articles' AND column_name = 'image'
                                      LIMIT 1)::VARCHAR);
    _final_image := COALESCE(_final_image, 'noimage.png');


    INSERT INTO wonks_ru.Articles
    (user_id, title, slug, content, short_description, category_id, status, image, created_at, updated_at)
    VALUES
        (_user_id, _title, _slug, _content, _short_description, _category_id, _status, _final_image, NOW(), NOW())
    RETURNING id INTO _inserted_article_id;

    IF _inserted_article_id IS NULL THEN
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Failed to insert article record.'::TEXT;
        RETURN;
    END IF;

    IF _tags IS NOT NULL AND array_length(_tags, 1) > 0 THEN
        FOREACH _tag_name IN ARRAY _tags LOOP
                _tag_name := TRIM(_tag_name);
                IF _tag_name <> '' THEN
                    SELECT id INTO _tag_id FROM wonks_ru.Tags WHERE lower(name) = lower(_tag_name);
                    IF NOT FOUND THEN
                        INSERT INTO wonks_ru.Tags (name) VALUES (_tag_name)
                        ON CONFLICT (name) DO NOTHING
                        RETURNING id INTO _tag_id;
                        IF _tag_id IS NULL THEN
                            SELECT id INTO _tag_id FROM wonks_ru.Tags WHERE lower(name) = lower(_tag_name);
                        END IF;
                    END IF;

                    IF _tag_id IS NOT NULL THEN
                        INSERT INTO wonks_ru.Article_tags (article_id, tag_id)
                        VALUES (_inserted_article_id, _tag_id)
                        ON CONFLICT (article_id, tag_id) DO NOTHING;
                    ELSE
                        RAISE WARNING 'Could not find or create tag: %', _tag_name;
                    END IF;
                END IF;
            END LOOP;
    END IF;

    RETURN QUERY SELECT _inserted_article_id, 'OK'::TEXT, 'Article created successfully.'::TEXT;

EXCEPTION
    WHEN unique_violation THEN
        RAISE WARNING 'Unique violation during article creation: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Failed due to unique constraint violation (title or slug).';
    WHEN foreign_key_violation THEN
        RAISE WARNING 'Foreign key violation during article creation: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Failed due to invalid user_id or category_id.';
    WHEN invalid_text_representation THEN
        RAISE WARNING 'Invalid enum value during article creation: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Invalid status value provided.';
    WHEN OTHERS THEN
        RAISE WARNING 'Error creating article: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'An unexpected error occurred during article creation: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.update_article(
    _article_id INTEGER,
    _user_id INTEGER,
    _new_title VARCHAR(255) DEFAULT NULL,
    _new_slug TEXT DEFAULT NULL,
    _new_content TEXT DEFAULT NULL,
    _new_short_description TEXT DEFAULT NULL,
    _new_image VARCHAR(255) DEFAULT NULL,
    _new_category_id INTEGER DEFAULT NULL,
    _new_status ARTICLE_STATUS DEFAULT NULL,
    _new_tags TEXT[] DEFAULT NULL
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _original_author_id INTEGER;
    _update_clauses TEXT[] := '{}';
    _query TEXT;
    _tag_id INTEGER;
    _tag_name TEXT;
    _changes_made BOOLEAN := false;
BEGIN
    SELECT user_id INTO _original_author_id FROM wonks_ru.Articles WHERE id = _article_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'ARTICLE_NOT_FOUND'::TEXT, 'Article not found.'::TEXT;
        RETURN;
    END IF;

    IF _original_author_id <> _user_id THEN
        RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'You do not have permission to edit this article.'::TEXT;
        RETURN;
    END IF;

    IF _new_title IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM wonks_ru.Articles WHERE lower(title) = lower(_new_title) AND id <> _article_id) THEN
            RETURN QUERY SELECT 'TITLE_EXISTS'::TEXT, 'New title is already in use.'::TEXT; RETURN;
        END IF;
        _update_clauses := array_append(_update_clauses, format('title = %L', _new_title));
        _changes_made := true;
    END IF;
    IF _new_slug IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM wonks_ru.Articles WHERE slug = _new_slug AND id <> _article_id) THEN
            RETURN QUERY SELECT 'SLUG_EXISTS'::TEXT, 'New slug is already in use.'::TEXT; RETURN;
        END IF;
        _update_clauses := array_append(_update_clauses, format('slug = %L', _new_slug));
        _changes_made := true;
    END IF;
    IF _new_content IS NOT NULL THEN
        _update_clauses := array_append(_update_clauses, format('content = %L', _new_content));
        _changes_made := true;
    END IF;
    IF _new_short_description IS NOT NULL THEN
        _update_clauses := array_append(_update_clauses, format('short_description = %L', _new_short_description));
        _changes_made := true;
    END IF;
    IF _new_image IS NOT NULL THEN
        _update_clauses := array_append(_update_clauses, format('image = %L', _new_image));
        _changes_made := true;
    END IF;
    IF _new_category_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM wonks_ru.Categories WHERE id = _new_category_id) THEN
            RETURN QUERY SELECT 'CATEGORY_NOT_FOUND'::TEXT, 'Category not found.'::TEXT; RETURN;
        END IF;
        _update_clauses := array_append(_update_clauses, format('category_id = %L', _new_category_id));
        _changes_made := true;
    END IF;
    IF _new_status IS NOT NULL THEN
        _update_clauses := array_append(_update_clauses, format('status = %L', _new_status));
        _changes_made := true;
    END IF;

    IF _changes_made THEN
        _update_clauses := array_append(_update_clauses, 'updated_at = NOW()');
    END IF;

    IF _new_tags IS NOT NULL THEN
        _changes_made := true;

        DELETE FROM wonks_ru.Article_tags WHERE article_id = _article_id;

        IF array_length(_new_tags, 1) > 0 THEN
            FOREACH _tag_name IN ARRAY _new_tags LOOP
                    _tag_name := TRIM(_tag_name);
                    IF _tag_name <> '' THEN
                        SELECT id INTO _tag_id FROM wonks_ru.Tags WHERE lower(name) = lower(_tag_name);
                        IF NOT FOUND THEN
                            INSERT INTO wonks_ru.Tags (name) VALUES (_tag_name)
                            ON CONFLICT (name) DO NOTHING RETURNING id INTO _tag_id;
                            IF _tag_id IS NULL THEN SELECT id INTO _tag_id FROM wonks_ru.Tags WHERE lower(name) = lower(_tag_name); END IF;
                        END IF;
                        IF _tag_id IS NOT NULL THEN
                            INSERT INTO wonks_ru.Article_tags (article_id, tag_id)
                            VALUES (_article_id, _tag_id) ON CONFLICT DO NOTHING;
                        ELSE
                            RAISE WARNING 'Could not find or create tag during update: %', _tag_name;
                        END IF;
                    END IF;
                END LOOP;
        END IF;
    END IF;


    IF NOT _changes_made THEN
        RETURN QUERY SELECT 'NO_CHANGES'::TEXT, 'No changes requested.'::TEXT;
        RETURN;
    END IF;

    IF array_length(_update_clauses, 1) > 0 THEN
        _query := format('UPDATE wonks_ru.Articles SET %s WHERE id = %L',
                         array_to_string(_update_clauses, ', '),
                         _article_id);
        RAISE NOTICE 'Executing update query: %', _query;
        EXECUTE _query;
    END IF;


    RETURN QUERY SELECT 'OK'::TEXT, 'Article updated successfully.'::TEXT;

EXCEPTION
    WHEN unique_violation THEN
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Update failed due to unique constraint violation (title or slug).';
    WHEN foreign_key_violation THEN
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Update failed due to foreign key constraint violation (category_id).';
    WHEN invalid_text_representation THEN
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Invalid status value provided.';
    WHEN OTHERS THEN
        RAISE WARNING 'Error updating article: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred during article update: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.delete_article(
    _article_id INTEGER,
    _user_id INTEGER
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _original_author_id INTEGER;
    _row_count INTEGER;
BEGIN
    SELECT user_id INTO _original_author_id FROM wonks_ru.Articles WHERE id = _article_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'ARTICLE_NOT_FOUND'::TEXT, 'Article not found.'::TEXT;
        RETURN;
    END IF;

    IF _original_author_id <> _user_id THEN
        RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'You do not have permission to delete this article.'::TEXT;
        RETURN;
    END IF;

    DELETE FROM wonks_ru.Articles
    WHERE id = _article_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, 'Article deleted successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to delete article, possibly already deleted.'::TEXT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error deleting article: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred during article deletion: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.report_user(
    _reporter_id INTEGER,
    _target_id INTEGER,
    _content TEXT
)
    RETURNS TABLE (
                      new_report_id INTEGER,
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _trimmed_content TEXT;
    _inserted_report_id INTEGER := NULL;
    _reporter_status USER_STATUS;
BEGIN
    IF _reporter_id = _target_id THEN
        RETURN QUERY SELECT NULL::INTEGER, 'SELF_REPORT'::TEXT, 'Cannot report yourself.'::TEXT;
        RETURN;
    END IF;

    SELECT status INTO _reporter_status FROM wonks_ru.Users WHERE id = _reporter_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT NULL::INTEGER, 'REPORTER_NOT_FOUND'::TEXT, 'Reporter user not found.'::TEXT;
        RETURN;
    END IF;

    IF _reporter_status <> 'activated' THEN
        RETURN QUERY SELECT NULL::INTEGER, 'REPORTER_INACTIVE'::TEXT, 'Reporter user account is not active.'::TEXT;
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Users WHERE id = _target_id) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'TARGET_NOT_FOUND'::TEXT, 'Target user not found.'::TEXT;
        RETURN;
    END IF;

    _trimmed_content := TRIM(_content);
    IF _trimmed_content IS NULL OR _trimmed_content = '' THEN
        RETURN QUERY SELECT NULL::INTEGER, 'EMPTY_CONTENT'::TEXT, 'Report content cannot be empty.'::TEXT;
        RETURN;
    END IF;

    INSERT INTO wonks_ru.Reports (reporter_id, target_id, content)
    VALUES (_reporter_id, _target_id, _trimmed_content)
    RETURNING id INTO _inserted_report_id;

    IF _inserted_report_id IS NOT NULL THEN
        RETURN QUERY SELECT _inserted_report_id, 'OK'::TEXT, 'Report submitted successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Failed to submit report record.'::TEXT;
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE WARNING 'Foreign key violation during report submission: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Failed due to invalid reporter_id or target_id.';
    WHEN OTHERS THEN
        RAISE WARNING 'Error submitting report: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'An unexpected error occurred while submitting the report: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.update_user_profile(
    _user_id INTEGER,
    _new_username VARCHAR(255) DEFAULT NULL,
    _new_email VARCHAR(255) DEFAULT NULL,
    _new_avatar_url VARCHAR(255) DEFAULT NULL
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _current_username VARCHAR(255);
    _current_email VARCHAR(255);
    _update_clauses TEXT[] := '{}';
    _query TEXT;
BEGIN
    RAISE NOTICE '[DEBUG] Entering function for user_id: %', _user_id;

    SELECT username, email INTO _current_username, _current_email
    FROM wonks_ru.Users WHERE id = _user_id;
    IF NOT FOUND THEN
        RAISE NOTICE '[DEBUG] User not found. Returning USER_NOT_FOUND.';
        RETURN QUERY SELECT 'USER_NOT_FOUND'::TEXT, 'User not found.'::TEXT;
        RETURN;
    END IF;
    RAISE NOTICE '[DEBUG] User found: %, %', _current_username, _current_email;

    IF _new_username IS NOT NULL AND _new_username <> _current_username THEN
        IF EXISTS (SELECT 1 FROM wonks_ru.Users WHERE lower(username) = lower(_new_username) AND id <> _user_id) THEN
            RAISE NOTICE '[DEBUG] New username exists. Returning USERNAME_EXISTS.';
            RETURN QUERY SELECT 'USERNAME_EXISTS'::TEXT, 'New username is already taken.'::TEXT;
            RETURN;
        END IF;
        _update_clauses := array_append(_update_clauses, format('username = %L', _new_username));
        RAISE NOTICE '[DEBUG] Added username to clauses.';
    END IF;
    IF _new_email IS NOT NULL AND _new_email <> _current_email THEN
        IF EXISTS (SELECT 1 FROM wonks_ru.Users WHERE lower(email) = lower(_new_email) AND id <> _user_id) THEN
            RAISE NOTICE '[DEBUG] New email exists. Returning EMAIL_EXISTS.';
            RETURN QUERY SELECT 'EMAIL_EXISTS'::TEXT, 'New email is already registered.'::TEXT;
            RETURN;
        END IF;
        _update_clauses := array_append(_update_clauses, format('email = %L', _new_email));
        RAISE NOTICE '[DEBUG] Added email to clauses.';
    END IF;
    IF _new_avatar_url IS NOT NULL THEN
        _update_clauses := array_append(_update_clauses, format('avatar_url = %L', _new_avatar_url));
        RAISE NOTICE '[DEBUG] Added avatar_url to clauses.';
    END IF;

    RAISE NOTICE '[DEBUG] Finished clause assembly. Clause count: %', array_length(_update_clauses, 1);

    IF array_length(_update_clauses, 1) IS NULL OR array_length(_update_clauses, 1) = 0 THEN
        RAISE NOTICE '[DEBUG] No update clauses. Returning NO_CHANGES.';
        RETURN QUERY SELECT 'NO_CHANGES'::TEXT, 'No changes requested.'::TEXT;
        RAISE NOTICE '[DEBUG] This notice should NOT appear if RETURN worked.';
        RETURN;
    END IF;

    RAISE NOTICE '[DEBUG] Proceeding to build and execute UPDATE query.';
    _query := format('UPDATE wonks_ru.Users SET %s WHERE id = %L',
                     array_to_string(_update_clauses, ', '),
                     _user_id);

    RAISE NOTICE '[DEBUG] Executing query: %', _query;
    EXECUTE _query;

    RAISE NOTICE '[DEBUG] Update successful. Returning OK.';
    RETURN QUERY SELECT 'OK'::TEXT, 'User profile updated successfully.'::TEXT;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '[USER_ID: %] Exception during update: %', _user_id, SQLERRM;
        RAISE NOTICE '[DEBUG] Exception occurred. Returning ERROR.';
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred during profile update: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.delete_notification(
    _notification_id INTEGER,
    _user_id INTEGER
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _notification_recipient_id INTEGER;
    _row_count INTEGER;
BEGIN
    SELECT user_id INTO _notification_recipient_id
    FROM wonks_ru.Notifications
    WHERE id = _notification_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 'NOT_FOUND'::TEXT, 'Notification not found.'::TEXT;
        RETURN;
    END IF;

    IF _notification_recipient_id <> _user_id THEN
        RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'You do not have permission to delete this notification.'::TEXT;
        RETURN;
    END IF;

    DELETE FROM wonks_ru.Notifications
    WHERE id = _notification_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, 'Notification deleted successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to delete notification, possibly already deleted.'::TEXT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error deleting notification: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred while deleting the notification: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.delete_all_user_notifications(
    _user_id INTEGER
)
    RETURNS TABLE (
                      deleted_count INTEGER,
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _row_count INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Users WHERE id = _user_id) THEN
        RETURN QUERY SELECT 0, 'USER_NOT_FOUND'::TEXT, 'User not found.'::TEXT;
        RETURN;
    END IF;

    DELETE FROM wonks_ru.Notifications
    WHERE user_id = _user_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;

    RETURN QUERY SELECT _row_count, 'OK'::TEXT, format('%s notifications deleted for user %s.', _row_count, _user_id);

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error deleting all user notifications for user %: %', _user_id, SQLERRM;
        RETURN QUERY SELECT 0, 'ERROR'::TEXT, 'An unexpected error occurred while deleting notifications: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.update_article_status(
    _article_id INTEGER,
    _moderator_id INTEGER,
    _new_status wonks_ru.article_status
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _moderator_role_name TEXT;
    _allowed_roles TEXT[] := ARRAY['Administrator', 'Moderator'];
    _row_count INTEGER;
BEGIN
    SELECT r.name INTO _moderator_role_name
    FROM wonks_ru.Users u
             JOIN wonks_ru.Roles r ON u.role_id = r.id
    WHERE u.id = _moderator_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'Moderator user not found or missing role.'::TEXT;
        RETURN;
    END IF;

    IF NOT (_moderator_role_name = ANY(_allowed_roles)) THEN
        RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'User does not have permission to update article status.'::TEXT;
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Articles WHERE id = _article_id) THEN
        RETURN QUERY SELECT 'ARTICLE_NOT_FOUND'::TEXT, 'Article not found.'::TEXT;
        RETURN;
    END IF;

    UPDATE wonks_ru.Articles
    SET
        status = _new_status,
        updated_at = NOW()
    WHERE id = _article_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, format('Article %s status updated to %s successfully.', _article_id, _new_status);
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to update article status, it might have been deleted concurrently.';
    END IF;

EXCEPTION
    WHEN invalid_text_representation THEN
        RAISE WARNING 'Invalid enum value during article status update: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Invalid status value provided.';
    WHEN OTHERS THEN
        RAISE WARNING 'Error updating article status for article % by user %: %', _article_id, _moderator_id, SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred while updating article status: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.process_report(
    _report_id INTEGER,
    _processor_id INTEGER,
    _new_status wonks_ru.complaint_status
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _processor_role_name TEXT;
    _allowed_roles TEXT[] := ARRAY['Administrator', 'Moderator'];
    _row_count INTEGER;
BEGIN
    SELECT r.name INTO _processor_role_name
    FROM wonks_ru.Users u
             JOIN wonks_ru.Roles r ON u.role_id = r.id
    WHERE u.id = _processor_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'Processor user not found or missing role.'::TEXT;
        RETURN;
    END IF;

    IF NOT (_processor_role_name = ANY(_allowed_roles)) THEN
        RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'User does not have permission to process reports.'::TEXT;
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Reports WHERE id = _report_id) THEN
        RETURN QUERY SELECT 'REPORT_NOT_FOUND'::TEXT, 'Report not found.'::TEXT;
        RETURN;
    END IF;

    UPDATE wonks_ru.Reports
    SET status = _new_status
    WHERE id = _report_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, format('Report %s status updated to %s successfully.', _report_id, _new_status);
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to update report status, it might have been deleted concurrently.';
    END IF;

EXCEPTION
    WHEN invalid_text_representation THEN
        RAISE WARNING 'Invalid enum value during report status update: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Invalid status value provided.';
    WHEN OTHERS THEN
        RAISE WARNING 'Error processing report % by user %: %', _report_id, _processor_id, SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred while processing the report: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.set_user_status(
    _target_user_id INTEGER,
    _actor_user_id INTEGER,
    _new_status wonks_ru.user_status
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _actor_role_name TEXT;
    _target_role_name TEXT;
    _allowed_roles TEXT[] := ARRAY['Administrator', 'Moderator'];
    _row_count INTEGER;
BEGIN
    SELECT r.name INTO _actor_role_name
    FROM wonks_ru.Users u
             JOIN wonks_ru.Roles r ON u.role_id = r.id
    WHERE u.id = _actor_user_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 'ACTOR_NOT_FOUND'::TEXT, 'Actor user not found or missing role.'::TEXT;
        RETURN;
    END IF;

    IF NOT (_actor_role_name = ANY(_allowed_roles)) THEN
        RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'User does not have permission to change user status.'::TEXT;
        RETURN;
    END IF;

    IF _actor_user_id = _target_user_id THEN
        RETURN QUERY SELECT 'CANNOT_BAN_SELF'::TEXT, 'Cannot change your own status.'::TEXT;
        RETURN;
    END IF;

    SELECT r.name INTO _target_role_name
    FROM wonks_ru.Users u
             JOIN wonks_ru.Roles r ON u.role_id = r.id
    WHERE u.id = _target_user_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 'TARGET_NOT_FOUND'::TEXT, 'Target user not found.'::TEXT;
        RETURN;
    END IF;

    IF _target_role_name = 'Administrator' AND _new_status = 'banned' THEN
        RETURN QUERY SELECT 'CANNOT_BAN_ADMIN'::TEXT, 'Cannot ban another Administrator.'::TEXT;
        RETURN;
    END IF;

    UPDATE wonks_ru.Users
    SET status = _new_status
    WHERE id = _target_user_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, format('User %s status updated to %s successfully.', _target_user_id, _new_status);
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to update user status, user might have been deleted concurrently.';
    END IF;

EXCEPTION
    WHEN invalid_text_representation THEN
        RAISE WARNING 'Invalid enum value during user status update: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Invalid status value provided.';
    WHEN OTHERS THEN
        RAISE WARNING 'Error setting user % status by user %: %', _target_user_id, _actor_user_id, SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred while setting user status: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.create_category(
    _actor_user_id INTEGER,
    _category_name VARCHAR(255)
)
    RETURNS TABLE (
                      new_category_id INTEGER,
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _actor_role_name TEXT;
    _allowed_roles TEXT[] := ARRAY['Administrator', 'Editor'];
    _trimmed_name VARCHAR(255);
    _inserted_id INTEGER := NULL;
BEGIN
    SELECT r.name INTO _actor_role_name FROM wonks_ru.Users u JOIN wonks_ru.Roles r ON u.role_id = r.id WHERE u.id = _actor_user_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT NULL::INTEGER, 'FORBIDDEN'::TEXT, 'Actor user not found or missing role.'::TEXT; RETURN;
    END IF;
    IF NOT (_actor_role_name = ANY(_allowed_roles)) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'FORBIDDEN'::TEXT, 'User does not have permission to create categories.'::TEXT; RETURN;
    END IF;

    _trimmed_name := TRIM(_category_name);
    IF _trimmed_name IS NULL OR _trimmed_name = '' THEN
        RETURN QUERY SELECT NULL::INTEGER, 'INVALID_INPUT'::TEXT, 'Category name cannot be empty.'::TEXT; RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM wonks_ru.Categories WHERE lower(name) = lower(_trimmed_name)) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'NAME_EXISTS'::TEXT, 'Category name already exists.'::TEXT; RETURN;
    END IF;

    INSERT INTO wonks_ru.Categories (name)
    VALUES (_trimmed_name)
    RETURNING id INTO _inserted_id;

    IF _inserted_id IS NOT NULL THEN
        RETURN QUERY SELECT _inserted_id, 'OK'::TEXT, 'Category created successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Failed to insert category record.'::TEXT;
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RETURN QUERY SELECT NULL::INTEGER, 'NAME_EXISTS'::TEXT, 'Category name already exists (concurrent creation).';
    WHEN OTHERS THEN
        RAISE WARNING 'Error creating category by user %: %', _actor_user_id, SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'An unexpected error occurred: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.update_category(
    _actor_user_id INTEGER,
    _category_id INTEGER,
    _new_category_name VARCHAR(255)
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _actor_role_name TEXT;
    _allowed_roles TEXT[] := ARRAY['Administrator', 'Editor'];
    _current_name VARCHAR(255);
    _trimmed_new_name VARCHAR(255);
    _row_count INTEGER;
BEGIN
    SELECT r.name INTO _actor_role_name FROM wonks_ru.Users u JOIN wonks_ru.Roles r ON u.role_id = r.id WHERE u.id = _actor_user_id;
    IF NOT FOUND THEN RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'Actor user not found or missing role.'::TEXT; RETURN; END IF;
    IF NOT (_actor_role_name = ANY(_allowed_roles)) THEN RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'User does not have permission to update categories.'::TEXT; RETURN; END IF;

    _trimmed_new_name := TRIM(_new_category_name);
    IF _trimmed_new_name IS NULL OR _trimmed_new_name = '' THEN RETURN QUERY SELECT 'INVALID_INPUT'::TEXT, 'New category name cannot be empty.'::TEXT; RETURN; END IF;

    SELECT name INTO _current_name FROM wonks_ru.Categories WHERE id = _category_id;
    IF NOT FOUND THEN RETURN QUERY SELECT 'NOT_FOUND'::TEXT, 'Category not found.'::TEXT; RETURN; END IF;

    IF lower(_current_name) = lower(_trimmed_new_name) THEN RETURN QUERY SELECT 'NO_CHANGES'::TEXT, 'New name is the same as the current name.'::TEXT; RETURN; END IF;

    IF EXISTS (SELECT 1 FROM wonks_ru.Categories WHERE lower(name) = lower(_trimmed_new_name) AND id <> _category_id) THEN
        RETURN QUERY SELECT 'NAME_EXISTS'::TEXT, 'New category name already exists.'::TEXT; RETURN;
    END IF;

    UPDATE wonks_ru.Categories SET name = _trimmed_new_name WHERE id = _category_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, 'Category updated successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to update category, possibly deleted concurrently.';
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RETURN QUERY SELECT 'NAME_EXISTS'::TEXT, 'New category name already exists (concurrent update).';
    WHEN OTHERS THEN
        RAISE WARNING 'Error updating category % by user %: %', _category_id, _actor_user_id, SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.delete_category(
    _actor_user_id INTEGER,
    _category_id INTEGER
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _actor_role_name TEXT;
    _allowed_roles TEXT[] := ARRAY['Administrator', 'Editor'];
    _row_count INTEGER;
BEGIN
    SELECT r.name INTO _actor_role_name FROM wonks_ru.Users u JOIN wonks_ru.Roles r ON u.role_id = r.id WHERE u.id = _actor_user_id;
    IF NOT FOUND THEN RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'Actor user not found or missing role.'::TEXT; RETURN; END IF;
    IF NOT (_actor_role_name = ANY(_allowed_roles)) THEN RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'User does not have permission to delete categories.'::TEXT; RETURN; END IF;

    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Categories WHERE id = _category_id) THEN
        RETURN QUERY SELECT 'NOT_FOUND'::TEXT, 'Category not found.'::TEXT; RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM wonks_ru.Articles WHERE category_id = _category_id) THEN
        RETURN QUERY SELECT 'HAS_ARTICLES'::TEXT, 'Cannot delete category because it is currently assigned to one or more articles.'::TEXT;
        RETURN;
    END IF;

    DELETE FROM wonks_ru.Categories WHERE id = _category_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, 'Category deleted successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to delete category, possibly already deleted.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error deleting category % by user %: %', _category_id, _actor_user_id, SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.create_tag(
    _actor_user_id INTEGER,
    _tag_name VARCHAR(255)
)
    RETURNS TABLE (
                      new_tag_id INTEGER,
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _actor_role_name TEXT;
    _allowed_roles TEXT[] := ARRAY['Administrator', 'Editor'];
    _trimmed_name VARCHAR(255);
    _inserted_id INTEGER := NULL;
BEGIN
    SELECT r.name INTO _actor_role_name FROM wonks_ru.Users u JOIN wonks_ru.Roles r ON u.role_id = r.id WHERE u.id = _actor_user_id;
    IF NOT FOUND THEN RETURN QUERY SELECT NULL::INTEGER, 'FORBIDDEN'::TEXT, 'Actor user not found or missing role.'::TEXT; RETURN; END IF;
    IF NOT (_actor_role_name = ANY(_allowed_roles)) THEN RETURN QUERY SELECT NULL::INTEGER, 'FORBIDDEN'::TEXT, 'User does not have permission to create tags.'::TEXT; RETURN; END IF;

    _trimmed_name := TRIM(_tag_name);
    IF _trimmed_name IS NULL OR _trimmed_name = '' THEN RETURN QUERY SELECT NULL::INTEGER, 'INVALID_INPUT'::TEXT, 'Tag name cannot be empty.'::TEXT; RETURN; END IF;

    IF EXISTS (SELECT 1 FROM wonks_ru.Tags WHERE lower(name) = lower(_trimmed_name)) THEN
        RETURN QUERY SELECT NULL::INTEGER, 'NAME_EXISTS'::TEXT, 'Tag name already exists.'::TEXT; RETURN;
    END IF;

    INSERT INTO wonks_ru.Tags (name)
    VALUES (_trimmed_name)
    RETURNING id INTO _inserted_id;

    IF _inserted_id IS NOT NULL THEN
        RETURN QUERY SELECT _inserted_id, 'OK'::TEXT, 'Tag created successfully.'::TEXT;
    ELSE
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'Failed to insert tag record.'::TEXT;
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RETURN QUERY SELECT NULL::INTEGER, 'NAME_EXISTS'::TEXT, 'Tag name already exists (concurrent creation).';
    WHEN OTHERS THEN
        RAISE WARNING 'Error creating tag by user %: %', _actor_user_id, SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 'ERROR'::TEXT, 'An unexpected error occurred: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.update_tag(
    _actor_user_id INTEGER,
    _tag_id INTEGER,
    _new_tag_name VARCHAR(255)
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _actor_role_name TEXT;
    _allowed_roles TEXT[] := ARRAY['Administrator', 'Editor'];
    _current_name VARCHAR(255);
    _trimmed_new_name VARCHAR(255);
    _row_count INTEGER;
BEGIN
    SELECT r.name INTO _actor_role_name FROM wonks_ru.Users u JOIN wonks_ru.Roles r ON u.role_id = r.id WHERE u.id = _actor_user_id;
    IF NOT FOUND THEN RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'Actor user not found or missing role.'::TEXT; RETURN; END IF;
    IF NOT (_actor_role_name = ANY(_allowed_roles)) THEN RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'User does not have permission to update tags.'::TEXT; RETURN; END IF;

    _trimmed_new_name := TRIM(_new_tag_name);
    IF _trimmed_new_name IS NULL OR _trimmed_new_name = '' THEN RETURN QUERY SELECT 'INVALID_INPUT'::TEXT, 'New tag name cannot be empty.'::TEXT; RETURN; END IF;

    SELECT name INTO _current_name FROM wonks_ru.Tags WHERE id = _tag_id;
    IF NOT FOUND THEN RETURN QUERY SELECT 'NOT_FOUND'::TEXT, 'Tag not found.'::TEXT; RETURN; END IF;

    IF lower(_current_name) = lower(_trimmed_new_name) THEN RETURN QUERY SELECT 'NO_CHANGES'::TEXT, 'New name is the same as the current name.'::TEXT; RETURN; END IF;

    IF EXISTS (SELECT 1 FROM wonks_ru.Tags WHERE lower(name) = lower(_trimmed_new_name) AND id <> _tag_id) THEN
        RETURN QUERY SELECT 'NAME_EXISTS'::TEXT, 'New tag name already exists.'::TEXT; RETURN;
    END IF;

    UPDATE wonks_ru.Tags SET name = _trimmed_new_name WHERE id = _tag_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, 'Tag updated successfully.';
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to update tag, possibly deleted concurrently.';
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RETURN QUERY SELECT 'NAME_EXISTS'::TEXT, 'New tag name already exists (concurrent update).';
    WHEN OTHERS THEN
        RAISE WARNING 'Error updating tag % by user %: %', _tag_id, _actor_user_id, SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.delete_tag(
    _actor_user_id INTEGER,
    _tag_id INTEGER
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _actor_role_name TEXT;
    _allowed_roles TEXT[] := ARRAY['Administrator', 'Editor'];
    _row_count INTEGER;
BEGIN
    SELECT r.name INTO _actor_role_name FROM wonks_ru.Users u JOIN wonks_ru.Roles r ON u.role_id = r.id WHERE u.id = _actor_user_id;
    IF NOT FOUND THEN RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'Actor user not found or missing role.'::TEXT; RETURN; END IF;
    IF NOT (_actor_role_name = ANY(_allowed_roles)) THEN RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'User does not have permission to delete tags.'::TEXT; RETURN; END IF;

    IF NOT EXISTS (SELECT 1 FROM wonks_ru.Tags WHERE id = _tag_id) THEN
        RETURN QUERY SELECT 'NOT_FOUND'::TEXT, 'Tag not found.'::TEXT; RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM wonks_ru.Article_tags WHERE tag_id = _tag_id) THEN
        RETURN QUERY SELECT 'HAS_ARTICLES'::TEXT, 'Cannot delete tag because it is currently assigned to one or more articles.'::TEXT;
        RETURN;
    END IF;

    DELETE FROM wonks_ru.Tags WHERE id = _tag_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, 'Tag deleted successfully.';
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to delete tag, possibly already deleted.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error deleting tag % by user %: %', _tag_id, _actor_user_id, SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.set_user_role(
    _target_user_id INTEGER,
    _actor_user_id INTEGER,
    _new_role_name VARCHAR(255)
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _actor_role_name TEXT;
    _target_current_role_id INTEGER;
    _target_current_role_name TEXT;
    _new_role_id INTEGER;
    _allowed_actor_roles TEXT[] := ARRAY['Administrator'];
    _protected_target_roles TEXT[] := ARRAY['Administrator'];
    _row_count INTEGER;
BEGIN
    SELECT r.name INTO _actor_role_name
    FROM wonks_ru.Users u JOIN wonks_ru.Roles r ON u.role_id = r.id
    WHERE u.id = _actor_user_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 'ACTOR_NOT_FOUND'::TEXT, 'Actor user not found or missing role.'::TEXT; RETURN;
    END IF;
    IF NOT (_actor_role_name = ANY(_allowed_actor_roles)) THEN
        RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'User does not have permission to change user roles.'::TEXT; RETURN;
    END IF;

    IF _actor_user_id = _target_user_id THEN
        RETURN QUERY SELECT 'CANNOT_CHANGE_SELF'::TEXT, 'Cannot change your own role using this function.'::TEXT; RETURN;
    END IF;

    SELECT u.role_id, r.name INTO _target_current_role_id, _target_current_role_name
    FROM wonks_ru.Users u JOIN wonks_ru.Roles r ON u.role_id = r.id
    WHERE u.id = _target_user_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 'TARGET_NOT_FOUND'::TEXT, 'Target user not found.'::TEXT; RETURN;
    END IF;

    IF (_target_current_role_name = ANY(_protected_target_roles)) THEN
        RETURN QUERY SELECT 'TARGET_ROLE_PROTECTED'::TEXT, format('Cannot change the role of a user with the protected role: %s.', _target_current_role_name); RETURN;
    END IF;

    SELECT id INTO _new_role_id FROM wonks_ru.Roles WHERE name = _new_role_name;
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'NEW_ROLE_NOT_FOUND'::TEXT, format('Role "%s" not found.', _new_role_name); RETURN;
    END IF;

    IF _target_current_role_id = _new_role_id THEN
        RETURN QUERY SELECT 'NO_CHANGES'::TEXT, format('User already has the role "%s".', _new_role_name); RETURN;
    END IF;

    UPDATE wonks_ru.Users
    SET role_id = _new_role_id
    WHERE id = _target_user_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, format('User %s role successfully changed to "%s".', _target_user_id, _new_role_name);
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to update user role, user might have been deleted concurrently.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error setting role for user % by user %: %', _target_user_id, _actor_user_id, SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred while setting user role: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.export_schema_to_jsonb(
    _schema_name TEXT DEFAULT 'wonks_ru'
)
    RETURNS JSONB
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = pg_catalog
AS $$
DECLARE
    _table_record RECORD;
    _table_jsonb JSONB;
    _result_jsonb JSONB := '{}'::jsonb;
    _query TEXT;
BEGIN
    FOR _table_record IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = _schema_name AND table_type = 'BASE TABLE'
        ORDER BY table_name
        LOOP
            _query := format(
                    'SELECT COALESCE(jsonb_agg(row_to_json(t)), ''[]''::jsonb) FROM %I.%I t',
                    _schema_name,
                    _table_record.table_name
                      );

            RAISE NOTICE 'Exporting table: %.%', _schema_name, _table_record.table_name;
            EXECUTE _query INTO _table_jsonb;

            _result_jsonb := _result_jsonb || jsonb_build_object(_table_record.table_name, _table_jsonb);
        END LOOP;

    RETURN _result_jsonb;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error during schema export: %', SQLERRM;
        RETURN jsonb_build_object('error', SQLERRM);
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.import_schema_from_jsonb(
    _data JSONB,
    _schema_name TEXT DEFAULT 'wonks_ru',
    _mode TEXT DEFAULT 'TRUNCATE'
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = pg_catalog
AS $$
DECLARE
    _import_order TEXT[] := ARRAY[
        'roles', 'categories', 'tags', 'users',
        'articles',
        'article_tags',
        'comments',
        'favourites',
        'ratings',
        'subscriptions',
        'notifications',
        'reports'
        ];
    _table_name TEXT;
    _json_array JSONB;
    _query TEXT;
    _pk_column TEXT := 'id';
    _cols TEXT;
    _val TEXT;
    _rec RECORD;
BEGIN
    RAISE WARNING 'Starting JSON import for schema %. Mode: %. THIS CAN BE DESTRUCTIVE!', _schema_name, _mode;

    IF upper(_mode) = 'TRUNCATE' THEN
        RAISE WARNING 'TRUNCATE MODE: Deleting all data from tables in schema % in reverse order.', _schema_name;
        FOREACH _table_name IN ARRAY reverse(_import_order) LOOP
                _query := format('TRUNCATE TABLE %I.%I RESTART IDENTITY CASCADE;', _schema_name, _table_name);
                RAISE NOTICE 'Executing: %', _query;
                EXECUTE _query;
            END LOOP;
        RAISE WARNING 'TRUNCATE MODE: Data deletion complete.';
    ELSIF upper(_mode) <> 'UPSERT' THEN
        RETURN QUERY SELECT 'INVALID_MODE'::TEXT, 'Invalid import mode specified. Use TRUNCATE or UPSERT.'::TEXT;
        RETURN;
    END IF;

    FOREACH _table_name IN ARRAY _import_order LOOP
            IF _data ? _table_name THEN
                _json_array := _data -> _table_name;

                IF jsonb_array_length(_json_array) = 0 THEN
                    RAISE NOTICE 'Skipping empty table: %.%', _schema_name, _table_name;
                    CONTINUE;
                END IF;

                RAISE NOTICE 'Importing data for table: %.%', _schema_name, _table_name;

                SELECT string_agg(quote_ident(key), ', ')
                INTO _cols
                FROM jsonb_object_keys(_json_array -> 0);

                _query := format(
                        'INSERT INTO %I.%I (%s) SELECT %s FROM jsonb_populate_recordset(NULL::%I.%I, %L::jsonb)',
                        _schema_name, _table_name, _cols, _cols, _schema_name, _table_name, _json_array
                          );

                IF upper(_mode) = 'UPSERT' THEN
                    SELECT string_agg(format('%I = EXCLUDED.%I', key, key), ', ')
                    INTO _val
                    FROM jsonb_object_keys(_json_array -> 0)
                    WHERE key <> _pk_column;

                    _query := _query || format(' ON CONFLICT (%I) DO UPDATE SET %s', _pk_column, _val);
                ELSIF upper(_mode) = 'TRUNCATE' THEN
                    _query := _query || format(' ON CONFLICT (%I) DO NOTHING', _pk_column);
                END IF;

                RAISE NOTICE 'Executing INSERT for %: %', _table_name, left(_query, 500) || '...';
                EXECUTE _query;
                RAISE NOTICE 'Finished INSERT for %.', _table_name;

            ELSE
                RAISE WARNING 'No data found in JSON for table: %.%', _schema_name, _table_name;
            END IF;
        END LOOP;

    RAISE NOTICE 'Resetting sequences...';
    FOR _rec IN
        SELECT
            seq.sequence_name,
            seq.table_name,
            seq.column_name
        FROM information_schema.sequences seq
                 JOIN information_schema.columns col ON seq.sequence_name = pg_get_serial_sequence(quote_ident(col.table_schema) || '.' || quote_ident(col.table_name), col.column_name)
        WHERE seq.sequence_schema = _schema_name
          AND col.table_schema = _schema_name
        LOOP
            _query := format(
                    'SELECT setval(%L, COALESCE(max(%I), 1)) FROM %I.%I',
                    _schema_name || '.' || _rec.sequence_name,
                    _rec.column_name,
                    _schema_name,
                    _rec.table_name
                      );
            RAISE NOTICE 'Resetting sequence for %.% column %', _schema_name, _rec.table_name, _rec.column_name;
            EXECUTE _query;
        END LOOP;
    RAISE NOTICE 'Sequence reset complete.';


    RETURN QUERY SELECT 'OK'::TEXT, 'JSON data imported successfully.'::TEXT;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error during JSON import for schema %: %', _schema_name, SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An error occurred during import: ' || SQLERRM::TEXT;
END;
$$;
