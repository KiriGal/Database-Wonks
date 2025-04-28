set search_path = wonks_ru;
--Создание ролей--
CREATE ROLE Админ;
CREATE ROLE Модератор;
CREATE ROLE Пользователь;
CREATE ROLE Гость;

REVOKE EXECUTE ON FUNCTION wonks_ru.get_article_comments_paginated_filtered(_limit integer, _offset integer, filter_article_slug text, filter_username text, filter_content text, filter_created_at_start timestamp with time zone, filter_created_at_end timestamp with time zone) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.get_user_subscriptions_paginated_filtered(_limit integer, _offset integer, filter_followed_id integer, filter_follower_id integer, filter_followed_username text, filter_follower_username text, filter_notices boolean) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.get_reports_paginated_filtered(_limit integer, _offset integer, filter_reporter_username text, filter_target_username text, filter_status text, filter_date_start timestamp with time zone, filter_date_end timestamp with time zone) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.register_user(_username character varying, _email character varying, _plain_password text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.update_article_status(_article_id integer, _moderator_id integer, _new_status wonks_ru.article_status) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.process_report(_report_id integer, _processor_id integer, _new_status wonks_ru.complaint_status) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.get_user_notifications_paginated_filtered(_limit integer, _offset integer, filter_recipient_id integer, filter_recipient_username text, filter_text text, filter_created_at_start timestamp with time zone, filter_created_at_end timestamp with time zone) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.unsubscribe_from_user(_follower_id integer, _followed_id integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.set_subscription_notices(_follower_id integer, _followed_id integer, _enable_notices boolean) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.delete_comment(_comment_id integer, _user_id integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.remove_from_favourites(_user_id integer, _article_id integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.edit_comment(_comment_id integer, _user_id integer, _new_content text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.remove_article_rating(_user_id integer, _article_id integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.create_article(_user_id integer, _title character varying, _slug text, _content text, _short_description text, _category_id integer, _status wonks_ru.article_status, _image character varying, _tags text[]) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.update_article(_article_id integer, _user_id integer, _new_title character varying, _new_slug text, _new_content text, _new_short_description text, _new_image character varying, _new_category_id integer, _new_status wonks_ru.article_status, _new_tags text[]) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.report_user(_reporter_id integer, _target_id integer, _content text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.get_articles_paginated_filtered(_limit integer, _offset integer, filter_id integer, filter_slug text, filter_title text, filter_category_name text, filter_tags text[], filter_created_at_start timestamp with time zone, filter_created_at_end timestamp with time zone) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.get_user_favourite_articles_paginated_filtered(_limit integer, _offset integer, filter_user_id integer, filter_username text, filter_article_slug text, filter_article_title text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.authenticate_user(_identifier text, _plain_password text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.subscribe_to_user(_follower_id integer, _followed_id integer, _receive_notices boolean) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.add_comment(_user_id integer, _article_id integer, _content text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.add_to_favourites(_user_id integer, _article_id integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.set_article_rating(_user_id integer, _article_id integer, _rating_value integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.delete_article(_article_id integer, _user_id integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.delete_notification(_notification_id integer, _user_id integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.update_user_profile(_user_id integer, _new_username character varying, _new_email character varying, _new_avatar_url character varying) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.delete_all_user_notifications(_user_id integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.set_user_status(_target_user_id integer, _actor_user_id integer, _new_status wonks_ru.user_status) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.create_category(_actor_user_id integer, _category_name character varying) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.update_category(_actor_user_id integer, _category_id integer, _new_category_name character varying) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.delete_category(_actor_user_id integer, _category_id integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.create_tag(_actor_user_id integer, _tag_name character varying) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.update_tag(_actor_user_id integer, _tag_id integer, _new_tag_name character varying) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.delete_tag(_actor_user_id integer, _tag_id integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION wonks_ru.set_user_role(_target_user_id integer, _actor_user_id integer, _new_role_name character varying) FROM PUBLIC;

-- === Отзыв прав у Гость ===
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA wonks_ru FROM Гость;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA wonks_ru FROM Гость;

-- === Отзыв прав у Пользователь ===
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA wonks_ru FROM Пользователь;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA wonks_ru FROM Пользователь;

-- === Отзыв прав у Модератор ===
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA wonks_ru FROM Модератор;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA wonks_ru FROM Модератор;


-- === 1. Роль: Гость (Guest) ===
GRANT EXECUTE ON FUNCTION wonks_ru.register_user(VARCHAR, VARCHAR, TEXT) TO Гость;
GRANT EXECUTE ON FUNCTION wonks_ru.authenticate_user(TEXT, TEXT) TO Гость;
-- Функции для просмотра общедоступных данных
GRANT EXECUTE ON FUNCTION wonks_ru.get_articles_paginated_filtered(INTEGER, INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT[], TIMESTAMPTZ, TIMESTAMPTZ) TO Гость;
GRANT EXECUTE ON FUNCTION wonks_ru.get_article_comments_paginated_filtered(INTEGER, INTEGER, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO Гость;
GRANT EXECUTE ON FUNCTION wonks_ru.get_user_subscriptions_paginated_filtered(INTEGER, INTEGER, INTEGER, INTEGER, TEXT, TEXT, BOOLEAN) TO Гость; -- Если подписки публичны


-- === 2. Роль: Пользователь (User) ===
GRANT EXECUTE ON FUNCTION wonks_ru.get_articles_paginated_filtered(INTEGER, INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT[], TIMESTAMPTZ, TIMESTAMPTZ) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.get_article_comments_paginated_filtered(INTEGER, INTEGER, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.get_user_subscriptions_paginated_filtered(INTEGER, INTEGER, INTEGER, INTEGER, TEXT, TEXT, BOOLEAN) TO Пользователь;
-- Управление своим профилем
GRANT EXECUTE ON FUNCTION wonks_ru.update_user_profile(INTEGER, VARCHAR, VARCHAR, VARCHAR) TO Пользователь;
-- Управление своими статьями
GRANT EXECUTE ON FUNCTION wonks_ru.create_article(INTEGER, VARCHAR, TEXT, TEXT, TEXT, INTEGER, wonks_ru.article_status, VARCHAR, TEXT[]) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.update_article(INTEGER, INTEGER, VARCHAR, TEXT, TEXT, TEXT, VARCHAR, INTEGER, wonks_ru.article_status, TEXT[]) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_article(INTEGER, INTEGER) TO Пользователь;
-- Управление своими комментариями
GRANT EXECUTE ON FUNCTION wonks_ru.add_comment(INTEGER, INTEGER, TEXT) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.edit_comment(INTEGER, INTEGER, TEXT) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_comment(INTEGER, INTEGER) TO Пользователь;
-- Управление своим избранным
GRANT EXECUTE ON FUNCTION wonks_ru.add_to_favourites(INTEGER, INTEGER) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.remove_from_favourites(INTEGER, INTEGER) TO Пользователь;
-- Управление своими оценками
GRANT EXECUTE ON FUNCTION wonks_ru.set_article_rating(INTEGER, INTEGER, INTEGER) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.remove_article_rating(INTEGER, INTEGER) TO Пользователь;
-- Управление своими подписками
GRANT EXECUTE ON FUNCTION wonks_ru.subscribe_to_user(INTEGER, INTEGER, BOOLEAN) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.unsubscribe_from_user(INTEGER, INTEGER) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.set_subscription_notices(INTEGER, INTEGER, BOOLEAN) TO Пользователь;
-- Подача жалоб
GRANT EXECUTE ON FUNCTION wonks_ru.report_user(INTEGER, INTEGER, TEXT) TO Пользователь;
-- Управление своими уведомлениями
GRANT EXECUTE ON FUNCTION wonks_ru.delete_notification(INTEGER, INTEGER) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_all_user_notifications(INTEGER) TO Пользователь;
-- Просмотр своих данных (требует фильтрации внутри)
GRANT EXECUTE ON FUNCTION wonks_ru.get_user_favourite_articles_paginated_filtered(INTEGER, INTEGER, INTEGER, TEXT, TEXT, TEXT) TO Пользователь;
GRANT EXECUTE ON FUNCTION wonks_ru.get_user_notifications_paginated_filtered(INTEGER, INTEGER, INTEGER, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO Пользователь;


-- === 3. Роль: Модератор (Moderator) ===
GRANT EXECUTE ON FUNCTION wonks_ru.get_articles_paginated_filtered(INTEGER, INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT[], TIMESTAMPTZ, TIMESTAMPTZ) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.get_article_comments_paginated_filtered(INTEGER, INTEGER, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.get_user_subscriptions_paginated_filtered(INTEGER, INTEGER, INTEGER, INTEGER, TEXT, TEXT, BOOLEAN) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.update_user_profile(INTEGER, VARCHAR, VARCHAR, VARCHAR) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.create_article(INTEGER, VARCHAR, TEXT, TEXT, TEXT, INTEGER, wonks_ru.article_status, VARCHAR, TEXT[]) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.update_article(INTEGER, INTEGER, VARCHAR, TEXT, TEXT, TEXT, VARCHAR, INTEGER, wonks_ru.article_status, TEXT[]) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_article(INTEGER, INTEGER) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.add_comment(INTEGER, INTEGER, TEXT) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.edit_comment(INTEGER, INTEGER, TEXT) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_comment(INTEGER, INTEGER) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.add_to_favourites(INTEGER, INTEGER) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.remove_from_favourites(INTEGER, INTEGER) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.set_article_rating(INTEGER, INTEGER, INTEGER) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.remove_article_rating(INTEGER, INTEGER) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.subscribe_to_user(INTEGER, INTEGER, BOOLEAN) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.unsubscribe_from_user(INTEGER, INTEGER) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.set_subscription_notices(INTEGER, INTEGER, BOOLEAN) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.report_user(INTEGER, INTEGER, TEXT) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_notification(INTEGER, INTEGER) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_all_user_notifications(INTEGER) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.get_user_favourite_articles_paginated_filtered(INTEGER, INTEGER, INTEGER, TEXT, TEXT, TEXT) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.get_user_notifications_paginated_filtered(INTEGER, INTEGER, INTEGER, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO Модератор;
-- Дополнительные права Модератора:
GRANT EXECUTE ON FUNCTION wonks_ru.update_article_status(INTEGER, INTEGER, wonks_ru.article_status) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.create_tag(INTEGER, VARCHAR) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.update_tag(INTEGER, INTEGER, VARCHAR) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_tag(INTEGER, INTEGER) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.create_category(INTEGER, VARCHAR) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.update_category(INTEGER, INTEGER, VARCHAR) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_category(INTEGER, INTEGER) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.process_report(INTEGER, INTEGER, wonks_ru.complaint_status) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.get_reports_paginated_filtered(INTEGER, INTEGER, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO Модератор;
GRANT EXECUTE ON FUNCTION wonks_ru.set_user_status(INTEGER, INTEGER, wonks_ru.user_status) TO Модератор;


-- === 4. Роль: Админ (Admin) ===
GRANT EXECUTE ON FUNCTION wonks_ru.get_articles_paginated_filtered(INTEGER, INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT[], TIMESTAMPTZ, TIMESTAMPTZ) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.get_article_comments_paginated_filtered(INTEGER, INTEGER, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.get_user_subscriptions_paginated_filtered(INTEGER, INTEGER, INTEGER, INTEGER, TEXT, TEXT, BOOLEAN) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.update_user_profile(INTEGER, VARCHAR, VARCHAR, VARCHAR) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.create_article(INTEGER, VARCHAR, TEXT, TEXT, TEXT, INTEGER, wonks_ru.article_status, VARCHAR, TEXT[]) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.update_article(INTEGER, INTEGER, VARCHAR, TEXT, TEXT, TEXT, VARCHAR, INTEGER, wonks_ru.article_status, TEXT[]) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_article(INTEGER, INTEGER) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.add_comment(INTEGER, INTEGER, TEXT) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.edit_comment(INTEGER, INTEGER, TEXT) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_comment(INTEGER, INTEGER) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.add_to_favourites(INTEGER, INTEGER) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.remove_from_favourites(INTEGER, INTEGER) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.set_article_rating(INTEGER, INTEGER, INTEGER) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.remove_article_rating(INTEGER, INTEGER) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.subscribe_to_user(INTEGER, INTEGER, BOOLEAN) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.unsubscribe_from_user(INTEGER, INTEGER) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.set_subscription_notices(INTEGER, INTEGER, BOOLEAN) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.report_user(INTEGER, INTEGER, TEXT) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_notification(INTEGER, INTEGER) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_all_user_notifications(INTEGER) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.get_user_favourite_articles_paginated_filtered(INTEGER, INTEGER, INTEGER, TEXT, TEXT, TEXT) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.get_user_notifications_paginated_filtered(INTEGER, INTEGER, INTEGER, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.update_article_status(INTEGER, INTEGER, wonks_ru.article_status) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.create_tag(INTEGER, VARCHAR) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.update_tag(INTEGER, INTEGER, VARCHAR) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_tag(INTEGER, INTEGER) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.create_category(INTEGER, VARCHAR) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.update_category(INTEGER, INTEGER, VARCHAR) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.delete_category(INTEGER, INTEGER) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.process_report(INTEGER, INTEGER, wonks_ru.complaint_status) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.get_reports_paginated_filtered(INTEGER, INTEGER, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO Админ;
-- Высшие права Администратора:
GRANT EXECUTE ON FUNCTION wonks_ru.set_user_role(INTEGER, INTEGER, VARCHAR) TO Админ;
GRANT EXECUTE ON FUNCTION wonks_ru.set_user_status(INTEGER, INTEGER, wonks_ru.user_status) TO Админ;


--== Демо пользователи ==--
CREATE USER admin_user WITH PASSWORD 'admin';
GRANT Админ TO admin_user;

CREATE USER moderator_user WITH PASSWORD 'moderator';
GRANT Модератор TO moderator_user;

CREATE USER standard_user WITH PASSWORD 'user';
GRANT Пользователь TO standard_user;

CREATE USER guest_user WITH PASSWORD 'guest';
GRANT Гость TO guest_user;

ALTER USER admin_user     SET search_path = wonks_ru, public;
ALTER USER moderator_user SET search_path = wonks_ru, public;
ALTER USER standard_user  SET search_path = wonks_ru, public;
ALTER USER guest_user     SET search_path = wonks_ru, public;

GRANT CONNECT ON DATABASE "UsefulLinks" TO admin_user, moderator_user, standard_user, guest_user;
GRANT USAGE ON SCHEMA wonks_ru TO admin_user, moderator_user, standard_user, guest_user;

