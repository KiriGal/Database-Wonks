set search_path = "wonks_ru";

CREATE OR REPLACE FUNCTION register_user(
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
    SELECT id INTO _existing_user_id FROM Users WHERE lower(email) = lower(_email);
    IF FOUND THEN
        RETURN QUERY SELECT NULL::INTEGER, 'EMAIL_EXISTS'::TEXT, 'Email already registered.'::TEXT;
        RETURN;
    END IF;

    SELECT id INTO _existing_user_id FROM Users WHERE lower(username) = lower(_username);
    IF FOUND THEN
        RETURN QUERY SELECT NULL::INTEGER, 'USERNAME_EXISTS'::TEXT, 'Username already taken.'::TEXT;
        RETURN;
    END IF;

    SELECT id INTO _user_role_id FROM Roles WHERE name = 'User';
    IF NOT FOUND THEN
        RAISE WARNING 'Default role "User" not found in Roles table.';
        RETURN QUERY SELECT NULL::INTEGER, 'ROLE_NOT_FOUND'::TEXT, 'Default user role configuration error.'::TEXT;
        RETURN;
    END IF;

    _hashed_password := crypt(_plain_password, gen_salt('bf'));

    INSERT INTO Users (username, email, password_hash, role_id)
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
CREATE OR REPLACE FUNCTION authenticate_user(
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
    FROM Users u
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

CREATE OR REPLACE FUNCTION change_user_password(
    _user_id INTEGER,
    _old_plain_password TEXT,
    _new_plain_password TEXT
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    _user_record RECORD;
    _new_hashed_password TEXT;
BEGIN
    SELECT id, password_hash, status INTO _user_record
    FROM Users WHERE id = _user_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 'USER_NOT_FOUND'::TEXT, 'User not found.'::TEXT; RETURN;
    END IF;

    IF _user_record.password_hash <> crypt(_old_plain_password, _user_record.password_hash) THEN
        RETURN QUERY SELECT 'INCORRECT_OLD_PASSWORD'::TEXT, 'Incorrect current password.'::TEXT; RETURN;
    END IF;

    IF _new_plain_password IS NULL OR TRIM(_new_plain_password) = '' THEN
        RETURN QUERY SELECT 'INVALID_NEW_PASSWORD'::TEXT, 'New password cannot be empty.'::TEXT; RETURN;
    END IF;

    _new_hashed_password := crypt(_new_plain_password, gen_salt('bf'));

    UPDATE Users
    SET password_hash = _new_hashed_password
    WHERE id = _user_id;

    RETURN QUERY SELECT 'OK'::TEXT, 'Password changed successfully.'::TEXT;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error changing password for user %: %', _user_id, SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred while changing password: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION delete_user_account(
    _target_user_id INTEGER,
    _actor_user_id INTEGER
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
    _allowed_roles TEXT[] := ARRAY['Administrator'];
    _protected_roles TEXT[] := ARRAY['Administrator'];
    _row_count INTEGER;
BEGIN
    SELECT r.name INTO _actor_role_name
    FROM Users u JOIN Roles r ON u.role_id = r.id
    WHERE u.id = _actor_user_id;
    IF NOT FOUND THEN RETURN QUERY SELECT 'ACTOR_NOT_FOUND'::TEXT, 'Actor user not found or missing role.'::TEXT; RETURN; END IF;
    IF NOT (_actor_role_name = ANY(_allowed_roles)) THEN RETURN QUERY SELECT 'FORBIDDEN'::TEXT, 'User does not have permission to delete user accounts.'::TEXT; RETURN; END IF;

    IF _actor_user_id = _target_user_id THEN RETURN QUERY SELECT 'CANNOT_DELETE_SELF'::TEXT, 'Cannot delete your own account using this function.'::TEXT; RETURN; END IF;

    SELECT r.name INTO _target_role_name
    FROM Users u JOIN Roles r ON u.role_id = r.id
    WHERE u.id = _target_user_id;
    IF NOT FOUND THEN RETURN QUERY SELECT 'TARGET_NOT_FOUND'::TEXT, 'Target user not found.'::TEXT; RETURN; END IF;

    IF (_target_role_name = ANY(_protected_roles)) THEN RETURN QUERY SELECT 'CANNOT_DELETE_ADMIN'::TEXT, format('Cannot delete a user with the protected role: %s.', _target_role_name); RETURN; END IF;

    DELETE FROM Users WHERE id = _target_user_id;

    GET DIAGNOSTICS _row_count = ROW_COUNT;
    IF _row_count > 0 THEN
        RETURN QUERY SELECT 'OK'::TEXT, format('User %s account and associated data deleted successfully.', _target_user_id);
    ELSE
        RETURN QUERY SELECT 'ERROR'::TEXT, 'Failed to delete user, possibly already deleted.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error deleting user % by actor %: %', _target_user_id, _actor_user_id, SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'An unexpected error occurred during user deletion: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION export_schema_to_jsonb(
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
    RAISE NOTICE 'Starting schema export to JSONB for schema: %', _schema_name;
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
            EXECUTE _query INTO _table_jsonb;
            _result_jsonb := _result_jsonb || jsonb_build_object(_table_record.table_name, _table_jsonb);
        END LOOP;
    RAISE NOTICE 'Schema export to JSONB completed.';
    RETURN _result_jsonb;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error during JSONB export: %', SQLERRM;
        RETURN jsonb_build_object('error', SQLERRM);
END;
$$;
CREATE OR REPLACE FUNCTION export_schema_to_json_file(
    _file_name TEXT,
    _schema_name TEXT DEFAULT 'wonks_ru'
)
    RETURNS TABLE ( status_code TEXT, message TEXT )
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = wonks_ru, pg_catalog
AS $$
DECLARE
    _base_export_dir TEXT := '/var/lib/postgresql/io';
    _full_path TEXT;
    _program_cmd TEXT;
    _query TEXT;
BEGIN
    IF _file_name IS NULL OR _file_name = '' OR _file_name ~ '[/\\]' OR _file_name = '.' OR _file_name = '..' THEN
        RETURN QUERY SELECT 'INVALID_FILENAME'::TEXT, 'Invalid or potentially unsafe filename provided.'::TEXT;
        RETURN;
    END IF;

    _full_path := _base_export_dir || '/' || _file_name;
    RAISE NOTICE 'Starting schema export using COPY TO PROGRAM for file: %', _full_path;

    _program_cmd := format('sh -c %L', 'cat > ' || _full_path);

    _query := format(
            'COPY (SELECT export_schema_to_jsonb(%L)) TO PROGRAM %L',
            _schema_name,
            _program_cmd
              );

    RAISE NOTICE 'Executing COPY TO PROGRAM: %', _query;
    BEGIN
        EXECUTE _query;
        RAISE NOTICE 'Schema export to file % completed.', _full_path;
        RETURN QUERY SELECT 'OK'::TEXT, format('Schema successfully exported to file %s.', _file_name);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Error during COPY TO PROGRAM export to file %: %', _full_path, SQLERRM;
            RETURN QUERY SELECT 'ERROR'::TEXT, 'Error during export: ' || SQLERRM::TEXT;
    END;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Critical error during file export setup: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'A critical setup error occurred: ' || SQLERRM::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION wonks_ru.import_schema_from_jsonb(
    _data JSONB,
    _schema_name TEXT DEFAULT 'wonks_ru',
    _mode TEXT DEFAULT 'TRUNCATE'
)
    RETURNS TABLE ( status_code TEXT, message TEXT )
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $$
DECLARE
    _import_order TEXT[] := ARRAY[
        'roles', 'categories', 'tags', 'users',
        'articles',
        'article_tags', 'comments', 'favourites', 'ratings',
        'subscriptions', 'notifications', 'reports'
        ];
    _table_name TEXT;
    _json_array JSONB;
    _query TEXT;
    _pk_column TEXT := 'id';
    _cols TEXT;
    _val_update TEXT;
    _rec RECORD;
    i INTEGER;
BEGIN
    RAISE NOTICE '[JSONB Import] Starting for schema %. Mode: %. THIS CAN BE DESTRUCTIVE!', _schema_name, _mode;

    IF upper(_mode) NOT IN ('TRUNCATE', 'UPSERT') THEN
        RETURN QUERY SELECT 'INVALID_MODE'::TEXT, 'Invalid import mode specified. Use TRUNCATE or UPSERT.'::TEXT;
        RETURN;
    END IF;

    IF upper(_mode) = 'TRUNCATE' THEN
        RAISE NOTICE '[JSONB Import] TRUNCATE MODE: Deleting data from tables in reverse order...';
        FOR i IN REVERSE array_upper(_import_order, 1) .. array_lower(_import_order, 1) LOOP
                _table_name := _import_order[i];
                BEGIN
                    _query := format('TRUNCATE TABLE %I.%I RESTART IDENTITY CASCADE;', _schema_name, _table_name);
                    RAISE NOTICE '[JSONB Import] Executing: %', _query;
                    EXECUTE _query;
                EXCEPTION
                    WHEN undefined_table THEN
                        RAISE WARNING '[JSONB Import] Skip truncate: Table %.% not found.', _schema_name, _table_name;
                    WHEN OTHERS THEN
                        RAISE WARNING '[JSONB Import] TRUNCATE ERROR for %.%: %', _schema_name, _table_name, SQLERRM;
                        RETURN QUERY SELECT 'ERROR'::TEXT, 'Truncate error for table ' || quote_ident(_table_name) || ': ' || SQLERRM::TEXT;
                        RETURN;
                END;
            END LOOP;
        RAISE NOTICE '[JSONB Import] TRUNCATE MODE: Data deletion complete.';
    END IF;

    FOREACH _table_name IN ARRAY _import_order LOOP
            IF _data ? _table_name THEN
                _json_array := _data -> _table_name;

                IF jsonb_typeof(_json_array) <> 'array' OR jsonb_array_length(_json_array) = 0 THEN
                    RAISE NOTICE '[JSONB Import] Skip: No data or not an array for table %.%', _schema_name, _table_name;
                    CONTINUE;
                END IF;
                IF jsonb_typeof(_json_array -> 0) <> 'object' THEN
                    RAISE WARNING '[JSONB Import] Skip: First element is not an object for table %.%', _schema_name, _table_name;
                    CONTINUE;
                END IF;

                RAISE NOTICE '[JSONB Import] Importing data for table: %.%', _schema_name, _table_name;

                SELECT string_agg(quote_ident(key), ', ')
                INTO _cols
                FROM jsonb_object_keys(_json_array -> 0) AS keys(key);

                IF _cols IS NULL THEN
                    RAISE WARNING '[JSONB Import] Skip: Could not determine columns from JSON for table %.%', _schema_name, _table_name;
                    CONTINUE;
                END IF;

                _query := format(
                        'INSERT INTO %I.%I (%s) SELECT %s FROM jsonb_populate_recordset(NULL::%I.%I, %L::jsonb)',
                        _schema_name, _table_name, _cols, _cols, _schema_name, _table_name, _json_array
                          );

                IF upper(_mode) = 'UPSERT' THEN
                    SELECT string_agg(format('%I = EXCLUDED.%I', key, key), ', ')
                    INTO _val_update
                    FROM jsonb_object_keys(_json_array -> 0) AS keys(key)
                    WHERE key <> _pk_column;

                    IF _val_update IS NOT NULL AND _val_update <> '' THEN
                        _query := _query || format(' ON CONFLICT (%I) DO UPDATE SET %s', _pk_column, _val_update);
                    ELSE
                        _query := _query || format(' ON CONFLICT (%I) DO NOTHING', _pk_column);
                    END IF;
                ELSE
                    _query := _query || format(' ON CONFLICT (%I) DO NOTHING', _pk_column);
                END IF;

                BEGIN
                    EXECUTE _query;
                    RAISE NOTICE '[JSONB Import] Finished INSERT/UPSERT for %.', _table_name;
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE WARNING '[JSONB Import] ERROR during INSERT/UPSERT for %.%: %', _schema_name, _table_name, SQLERRM;
                        RETURN QUERY SELECT 'ERROR'::TEXT, 'Error during import for table ' || quote_ident(_table_name) || ': ' || SQLERRM::TEXT;
                        RETURN;
                END;

            ELSE
                RAISE WARNING '[JSONB Import] No data found in JSON for table: %.%', _schema_name, _table_name;
            END IF;
        END LOOP;

    RAISE NOTICE '[JSONB Import] Resetting sequences...';
    FOR _rec IN
        SELECT
            seq.sequence_name,
            ic.table_name,
            ic.column_name
        FROM information_schema.sequences seq
                 JOIN information_schema.columns ic ON seq.sequence_schema = ic.table_schema
            AND seq.sequence_name = pg_get_serial_sequence(quote_ident(ic.table_schema) || '.' || quote_ident(ic.table_name), ic.column_name)
        WHERE seq.sequence_schema = _schema_name
          AND ic.table_schema = _schema_name
          AND ic.table_name = ANY(_import_order)
        LOOP
            BEGIN
                _query := format(
                        'SELECT setval(%L, COALESCE(max(%I), 1)) FROM %I.%I',
                        _schema_name || '.' || _rec.sequence_name,
                        _rec.column_name,
                        _schema_name,
                        _rec.table_name
                          );
                EXECUTE _query;
                RAISE NOTICE '[JSONB Import] Reset sequence for %.% column %', _schema_name, _rec.table_name, _rec.column_name;
            EXCEPTION
                WHEN undefined_table THEN
                    RAISE WARNING '[JSONB Import] Skip sequence reset: Table %.% not found.', _schema_name, _rec.table_name;
                WHEN query_canceled THEN
                    RAISE NOTICE '[JSONB Import] Sequence reset skipped for empty table %.%', _schema_name, _rec.table_name;
                    _query := format('SELECT setval(%L, 1, false)', _schema_name || '.' || _rec.sequence_name);
                    EXECUTE _query;
                WHEN OTHERS THEN
                    RAISE WARNING '[JSONB Import] Error resetting sequence for %.% column %: %', _schema_name, _rec.table_name, _rec.column_name, SQLERRM;
            END;
        END LOOP;
    RAISE NOTICE '[JSONB Import] Sequence reset complete.';

    RETURN QUERY SELECT 'OK'::TEXT, 'JSON data imported successfully.'::TEXT;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '[JSONB Import] CRITICAL ERROR during import process: %', SQLERRM;
        RETURN QUERY SELECT 'ERROR'::TEXT, 'A critical error occurred during import: ' || SQLERRM::TEXT;
END;
$$;
CREATE OR REPLACE FUNCTION wonks_ru.import_schema_from_json_file(
    _file_name TEXT,
    _schema_name TEXT DEFAULT 'wonks_ru',
    _mode TEXT DEFAULT 'TRUNCATE'
)
    RETURNS TABLE (
                      status_code TEXT,
                      message TEXT
                  )
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $$
DECLARE
    _base_import_dir TEXT := '/var/lib/postgresql/io';
    _full_path TEXT;
    _cat_argument TEXT;
    _shell_command TEXT;
    _query TEXT;
    _imported_data JSONB;
    _import_result RECORD;
BEGIN
    IF _file_name IS NULL OR _file_name = '' OR _file_name ~ '[/\\]' OR _file_name = '.' OR _file_name = '..' THEN
        RETURN QUERY SELECT 'INVALID_FILENAME'::TEXT, 'Invalid or potentially unsafe filename provided.'::TEXT;
        RETURN;
    END IF;

    IF upper(_mode) NOT IN ('TRUNCATE', 'UPSERT') THEN
        RETURN QUERY SELECT 'INVALID_MODE'::TEXT, 'Invalid import mode specified. Use TRUNCATE or UPSERT.'::TEXT;
        RETURN;
    END IF;

    _full_path := _base_import_dir || '/' || _file_name;
    RAISE NOTICE '[File Import] Starting schema import using COPY FROM PROGRAM for file: %', _full_path;

    CREATE TEMP TABLE __json_import_temp (data JSONB) ON COMMIT DROP;

    _cat_argument := quote_literal(_full_path);

    _shell_command := 'sh -c ''cat ' || _cat_argument || '''';

    _query := format('COPY __json_import_temp FROM PROGRAM %L', _shell_command);

    RAISE NOTICE '[File Import] Executing COPY FROM PROGRAM command: %', _query;
    BEGIN
        EXECUTE _query;
    EXCEPTION
        WHEN undefined_file OR program_limit_exceeded THEN
            RAISE WARNING '[File Import] File % not found or permissions error accessing it.', _full_path;
            RETURN QUERY SELECT 'FILE_NOT_FOUND'::TEXT AS status_code, 'Import file not found or cannot be accessed by the postgres user.'::TEXT AS message;
            RETURN;
        WHEN OTHERS THEN
            RAISE WARNING '[File Import] Error during COPY FROM PROGRAM for file %: %', _full_path, SQLERRM;
            RETURN QUERY SELECT 'COPY_ERROR'::TEXT AS status_code, ('Error reading import file: ' || SQLERRM::TEXT)::TEXT AS message;
            RETURN;
    END;

    SELECT data INTO _imported_data FROM __json_import_temp LIMIT 1;

    IF _imported_data IS NULL THEN
        RAISE WARNING '[File Import] Could not read JSON data from temporary table after COPY FROM %.', _full_path;
        RETURN QUERY SELECT 'JSON_READ_ERROR'::TEXT AS status_code, 'Failed to read JSON data from the import file (possibly empty or invalid JSON format).'::TEXT AS message;
        RETURN;
    END IF;

    RAISE NOTICE '[File Import] Calling internal JSONB import function.';
    SELECT r.status_code, r.message INTO _import_result
    FROM wonks_ru.import_schema_from_jsonb(_imported_data, _schema_name, _mode) r;

    RETURN QUERY SELECT
                     _import_result.status_code AS status_code,
                     _import_result.message AS message;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '[File Import] CRITICAL error during file import process: %', SQLERRM;
        RETURN QUERY SELECT
                         'ERROR'::TEXT AS status_code,
                         ('A critical error occurred during the import process: ' || SQLERRM::TEXT)::TEXT AS message;
END;
$$;

CREATE OR REPLACE FUNCTION subscribe_to_user(
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
    SELECT EXISTS (SELECT 1 FROM Users WHERE id = _follower_id) INTO _follower_exists;
    IF NOT _follower_exists THEN
        RETURN QUERY SELECT 'FOLLOWER_NOT_FOUND'::TEXT, 'Follower user not found.'::TEXT; RETURN;
    END IF;
    SELECT EXISTS (SELECT 1 FROM Users WHERE id = _followed_id) INTO _followed_exists;
    IF NOT _followed_exists THEN
        RETURN QUERY SELECT 'FOLLOWED_NOT_FOUND'::TEXT, 'User to follow not found.'::TEXT; RETURN;
    END IF;

    INSERT INTO Subscriptions (follower_id, followed_id, notices)
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
CREATE OR REPLACE FUNCTION unsubscribe_from_user(
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

    DELETE FROM Subscriptions
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

CREATE OR REPLACE FUNCTION update_article_timestamp()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION prevent_self_subscription()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.follower_id = NEW.followed_id THEN
        RAISE EXCEPTION 'Пользователь не может подписаться сам на себя.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION notify_article_author_on_comment()
    RETURNS TRIGGER AS
$$
DECLARE
    article_owner_id   INTEGER;
    commenter_username VARCHAR(255);
BEGIN
    SELECT user_id INTO article_owner_id FROM Articles WHERE id = NEW.article_id;
    SELECT username INTO commenter_username FROM Users WHERE id = NEW.user_id;

    IF article_owner_id <> NEW.user_id THEN
        INSERT INTO Notifications(user_id, text)
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
    article_author_id INTEGER;
BEGIN
    IF OLD.status IS DISTINCT FROM 'published' AND NEW.status = 'published' THEN

        article_author_id := NEW.user_id;

        FOR follower IN
            SELECT s.follower_id
            FROM wonks_ru.Subscriptions s
            WHERE s.followed_id = article_author_id
              AND s.notices = true
            LOOP
                INSERT INTO wonks_ru.Notifications(user_id, text)
                VALUES (follower.follower_id,
                        CONCAT(
                                'Пользователь, на которого вы подписаны (ID: ', article_author_id, '), опубликовал статью "',
                                NEW.title, '".'
                        ));
            END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;