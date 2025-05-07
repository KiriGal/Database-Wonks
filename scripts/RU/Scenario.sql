SET search_path = wonks_ru;
SET ROLE postgres;

SET SESSION AUTHORIZATION guest_user;
SELECT * FROM wonks_ru.register_user('user_to_delete', 'delete@example.com', 'password123');

RESET SESSION AUTHORIZATION;
SET ROLE postgres;

SET SESSION AUTHORIZATION guest_user;
SELECT * FROM wonks_ru.get_articles_paginated_filtered(_limit := 3, _offset := 0);
SELECT * FROM wonks_ru.get_article_details('funktsii-postgresql-obyasneny');
SELECT * FROM wonks_ru.get_article_comments_paginated_filtered(filter_article_slug := 'vvedenie-v-sql-predstavleniya', _limit := 2);
SELECT * FROM wonks_ru.get_user_profile(5);
SELECT * FROM wonks_ru.get_category_list();
SELECT * FROM wonks_ru.get_tag_list();
SELECT * FROM wonks_ru.get_articles_by_category(4, 2);
SELECT * FROM wonks_ru.get_articles_by_tag(1, 2);
SELECT * FROM wonks_ru.get_articles_by_author(3, 2);
SELECT id, slug, title, trend_score FROM wonks_ru.get_trending_articles(_limit := 2);
SELECT * FROM wonks_ru.get_user_subscriptions(3, 5);
SELECT follower_id, username FROM wonks_ru.get_user_followers(3, 5);
SELECT * FROM wonks_ru.get_user_comments(3);
SELECT * FROM wonks_ru.authenticate_user('AdminUser', 'wrongpassword');
SELECT * FROM wonks_ru.authenticate_user('user_to_delete', 'password123');
SELECT * FROM wonks_ru.register_user('GuestRegUser', 'guestreg@example.com', 'guestpass');
RESET SESSION AUTHORIZATION;

-- === Демонстрация Роли: Пользователь ===
SET SESSION AUTHORIZATION standard_user;
SELECT * FROM wonks_ru.get_articles_by_author(7);
SELECT * FROM wonks_ru.create_article(
        _user_id := 7, _title := 'Статья Пользователя 3 Новая', _slug := 'statya-polzovatelya-3-novaya',
        _content := 'Содержимое тестовой статьи от пользователя 3.', _short_description := 'Краткое описание.',
        _category_id := 3, _status := 'moderated'::wonks_ru.article_status,
        _tags := ARRAY['Веб-разработка', 'Машинное обучение']
              );
SELECT * FROM wonks_ru.update_article(
        _article_id := 6, _user_id := 7,
        _new_content := 'Обновленное содержимое.'
              );
SELECT * FROM wonks_ru.update_article(
        _article_id := 6, _user_id := 4,
        _new_content := 'Обновленное содержимое.'
              );
SELECT * FROM wonks_ru.add_comment(_user_id := 7, _article_id := 2, _content := 'Еще один комментарий от standard_user к статье 2');
SELECT * FROM wonks_ru.edit_comment(_comment_id := 9, _user_id := 7, _new_content := 'Отредактированный комментарий standard_user (ID=5)');
SELECT * FROM wonks_ru.set_article_rating(_user_id := 7, _article_id := 1, _rating_value := 5);
SELECT * FROM wonks_ru.check_user_rating(_user_id := 7, _article_id := 1);
SELECT * FROM wonks_ru.add_to_favourites(_user_id := 7, _article_id := 2);
SELECT * FROM wonks_ru.check_user_favourite(_user_id := 7, _article_id := 2);
SELECT * FROM wonks_ru.subscribe_to_user(_follower_id := 7, _followed_id := 5, _receive_notices := true);
SELECT * FROM wonks_ru.check_user_subscription(_follower_id := 3, _followed_id := 5);
SELECT * FROM wonks_ru.set_subscription_notices(_follower_id := 3, _followed_id := 5, _enable_notices := true);
SELECT * FROM wonks_ru.change_user_password(_user_id := 7, _old_plain_password := 'guestpass', _new_plain_password := 'newpassword123');
SELECT notification_id, text, is_read FROM wonks_ru.get_user_notifications_paginated_filtered(filter_recipient_id := 3, _limit := 5);
SELECT * FROM wonks_ru.mark_notification_read(_notification_id := 4, _user_id := 3);
SELECT * FROM wonks_ru.get_unread_notification_count(_user_id := 3);
SELECT * FROM wonks_ru.mark_all_notifications_read(_user_id := 3);
SELECT * FROM wonks_ru.report_user(_reporter_id := 3, _target_id := 4, _content := 'Жалоба от user 3.');
SELECT * FROM wonks_ru.update_user_profile(_user_id := 3, _new_avatar_url := 'avatars/jane_updated.png');
SELECT * FROM wonks_ru.get_user_feed(_user_id := 3, _limit := 5);
SELECT * FROM wonks_ru.get_user_favourite_articles_paginated_filtered(filter_user_id := 3, _limit := 5);
SELECT * FROM wonks_ru.delete_comment(_comment_id := 5, _user_id := 3);
SELECT * FROM wonks_ru.remove_from_favourites(_user_id := 3, _article_id := 2);
SELECT * FROM wonks_ru.remove_article_rating(_user_id := 3, _article_id := 1);
SELECT * FROM wonks_ru.unsubscribe_from_user(_follower_id := 3, _followed_id := 5);
SELECT * FROM wonks_ru.delete_notification(_notification_id := 1, _user_id := 3);
SELECT * FROM wonks_ru.delete_article(_article_id := 3, _user_id := 3);
RESET SESSION AUTHORIZATION;

-- === Демонстрация Роли: Модератор ===
SET SESSION AUTHORIZATION moderator_user;
SELECT * FROM wonks_ru.update_article_status(_article_id := 6, _moderator_id := 2, _new_status := 'published'::wonks_ru.article_status);
SELECT * FROM wonks_ru.update_article_status(_article_id := 1, _moderator_id := 2, _new_status := 'rejected'::wonks_ru.article_status);
SELECT * FROM wonks_ru.process_report(_report_id := 1, _processor_id := 2, _new_status := 'pending'::wonks_ru.complaint_status);
SELECT * FROM wonks_ru.process_report(_report_id := 1, _processor_id := 2, _new_status := 'processed'::wonks_ru.complaint_status);
SELECT * FROM wonks_ru.set_user_status(_target_user_id := 4, _actor_user_id := 2, _new_status := 'banned'::wonks_ru.user_status);
SELECT id, username, status FROM wonks_ru.get_user_profile(4);
SELECT * FROM wonks_ru.set_user_status(_target_user_id := 4, _actor_user_id := 2, _new_status := 'activated'::wonks_ru.user_status);
SELECT report_id, reporter_username, target_username, status FROM wonks_ru.get_reports_paginated_filtered(_limit := 5);
SELECT * FROM wonks_ru.get_articles_by_status(_status := 'rejected'::wonks_ru.article_status, _limit := 5);
SELECT * FROM wonks_ru.create_category(_actor_user_id := 2, _category_name := 'Модерация');
SELECT * FROM wonks_ru.update_category(_actor_user_id := 2, _category_id := 6, _new_category_name := 'Модерация Обновлено');
SELECT * FROM wonks_ru.create_tag(_actor_user_id := 2, _tag_name := 'Моды');
SELECT * FROM wonks_ru.update_tag(_actor_user_id := 2, _tag_id := 12, _new_tag_name := 'Моды обновление');
SELECT * FROM wonks_ru.delete_category(_actor_user_id := 2, _category_id := 6);
SELECT * FROM wonks_ru.delete_tag(_actor_user_id := 2, _tag_id := 12);
RESET SESSION AUTHORIZATION;

-- === Демонстрация Роли: Админ ===
SET SESSION AUTHORIZATION admin_user;
SELECT * FROM wonks_ru.set_user_role(_target_user_id := 2, _actor_user_id := 1, _new_role_name := 'User');
SELECT id, username, role_name FROM wonks_ru.get_user_profile(2);
SELECT * FROM wonks_ru.set_user_role(_target_user_id := 2, _actor_user_id := 1, _new_role_name := 'Moderator');
SELECT jsonb_pretty(wonks_ru.get_dashboard_stats());
SELECT * FROM wonks_ru.delete_user_account(_target_user_id := 6, _actor_user_id := 1);
SELECT * FROM wonks_ru.delete_user_account(_target_user_id := 1, _actor_user_id := 1);
SELECT * FROM wonks_ru.set_user_status(_target_user_id := 4, _actor_user_id := 1, _new_status := 'banned'::wonks_ru.user_status);

SELECT * FROM wonks_ru.export_schema_to_json_file('backup.json');
SELECT * FROM wonks_ru.import_schema_from_json_file('backup.json', 'wonks_ru', 'TRUNCATE');

RESET SESSION AUTHORIZATION;
SET ROLE postgres;