set search_path = "wonks_ru";

select * from get_article_comments_paginated_filtered();
select * from get_articles_paginated_filtered();
select * from get_user_favourite_articles_paginated_filtered();
select * from get_user_notifications_paginated_filtered();
select * from get_user_subscriptions_paginated_filtered();
select * from get_reports_paginated_filtered();


SELECT * FROM wonks_ru.register_user('NewUser', 'new@example.com', 'secretpassword123');
SELECT * FROM wonks_ru.authenticate_user('new@example.com', 'secretpassword123');
SELECT * FROM wonks_ru.authenticate_user('NewUser', 'wrongpassword');

SELECT * FROM wonks_ru.subscribe_to_user(_follower_id := 3, _followed_id := 2, _receive_notices := true);
SELECT * FROM wonks_ru.subscribe_to_user(_follower_id := 3, _followed_id := 2);
SELECT * FROM wonks_ru.subscribe_to_user(_follower_id := 4, _followed_id := 99);
SELECT * FROM wonks_ru.unsubscribe_from_user(_follower_id := 3, _followed_id := 2);
SELECT * FROM wonks_ru.unsubscribe_from_user(_follower_id := 3, _followed_id := 2);

SELECT * FROM wonks_ru.set_subscription_notices(_follower_id := 4, _followed_id := 3, _enable_notices := true);
SELECT * FROM wonks_ru.set_subscription_notices(_follower_id := 4, _followed_id := 3, _enable_notices := false);

SELECT * FROM wonks_ru.add_comment(_user_id := 3, _article_id := 1, _content := '   This is a great article!   ');
SELECT * FROM wonks_ru.edit_comment(_comment_id := 6, _user_id := 4, _new_content := 'I disagree!');
SELECT * FROM wonks_ru.edit_comment(_comment_id := 6, _user_id := 3, _new_content := 'This is a great article! Updated my thoughts.');
SELECT * FROM wonks_ru.edit_comment(_comment_id := 6, _user_id := 3, _new_content := '   ');
SELECT * FROM wonks_ru.delete_comment(_comment_id := 6, _user_id := 4);
SELECT * FROM wonks_ru.delete_comment(_comment_id := 6, _user_id := 3);
SELECT * FROM wonks_ru.delete_comment(_comment_id := 6, _user_id := 3);

SELECT * FROM wonks_ru.add_to_favourites(_user_id := 3, _article_id := 1);
SELECT * FROM wonks_ru.add_to_favourites(_user_id := 3, _article_id := 1);
SELECT * FROM wonks_ru.add_to_favourites(_user_id := 4, _article_id := 2);
SELECT * FROM wonks_ru.remove_from_favourites(_user_id := 3, _article_id := 1);
SELECT * FROM wonks_ru.remove_from_favourites(_user_id := 3, _article_id := 1);
SELECT * FROM wonks_ru.remove_from_favourites(_user_id := 5, _article_id := 2);

SELECT * FROM wonks_ru.set_article_rating(_user_id := 3, _article_id := 1, _rating_value := 5);
SELECT * FROM wonks_ru.set_article_rating(_user_id := 4, _article_id := 1, _rating_value := 4);
SELECT * FROM wonks_ru.set_article_rating(_user_id := 3, _article_id := 1, _rating_value := 4);
SELECT * FROM wonks_ru.set_article_rating(_user_id := 5, _article_id := 2, _rating_value := 6);
SELECT * FROM wonks_ru.remove_article_rating(_user_id := 3, _article_id := 1);
SELECT * FROM wonks_ru.remove_article_rating(_user_id := 3, _article_id := 1);

SELECT * FROM wonks_ru.create_article(
        _user_id := 5,
        _title := 'My New Awesome Article',
        _slug := 'my-new-awesome-article',
        _content := 'This is the full content.',
        _short_description := 'A short summary.',
        _category_id := 1,
        _status := 'published',
        _tags := ARRAY['awesome', 'PostgreSQL', 'new']
              );
SELECT * FROM wonks_ru.update_article(
        _article_id := 6,
        _user_id := 5,
        _new_content := 'Updated content with more details.',
        _new_tags := ARRAY['awesome', 'PostgreSQL', 'updated']
              );
SELECT * FROM wonks_ru.update_article(_article_id := 6, _user_id := 3, _new_title := 'Hack attempt');
SELECT * FROM wonks_ru.delete_article(_article_id := 6, _user_id := 3);
SELECT * FROM wonks_ru.delete_article(_article_id := 6, _user_id := 5);

SELECT * FROM wonks_ru.report_user(
        _reporter_id := 3,
        _target_id := 4,
        _content := 'User 4 left an offensive comment on article ID 1.'
              );
SELECT * FROM wonks_ru.report_user(
        _reporter_id := 3,
        _target_id := 4,
        _content := 'User 4 is also spamming ratings on article ID 2.'
              );
SELECT * FROM wonks_ru.report_user(_reporter_id := 5, _target_id := 5, _content := 'Testing');
SELECT * FROM wonks_ru.report_user(_reporter_id := 3, _target_id := 99, _content := 'Does not exist');
SELECT * FROM wonks_ru.report_user(_reporter_id := 3, _target_id := 4, _content := '   ');

SELECT * FROM wonks_ru.update_user_profile(_user_id := 3, _new_username := 'JaneDoeUpdated');
SELECT * FROM wonks_ru.update_user_profile(_user_id := 3, _new_avatar_url := 'avatars/jane_new.png');
SELECT * FROM wonks_ru.update_user_profile(
        _user_id := 3,
        _new_username := 'JaneD',
        _new_email := 'jane.d@wonks.ru'
              );
SELECT * FROM wonks_ru.update_user_profile(_user_id := 4, _new_email := 'jane.d@wonks.ru');
SELECT * FROM wonks_ru.update_user_profile(_user_id := 999, _new_username := 'Ghost');
SELECT * FROM wonks_ru.update_user_profile(_user_id := 3);

SELECT * FROM wonks_ru.delete_notification(_notification_id := 1, _user_id := 3);
SELECT * FROM wonks_ru.delete_notification(_notification_id := 5, _user_id := 4);
SELECT * FROM wonks_ru.delete_notification(_notification_id := 5, _user_id := 3);
SELECT * FROM wonks_ru.delete_notification(_notification_id := 99, _user_id := 3);
SELECT * FROM wonks_ru.delete_all_user_notifications(_user_id := 4);
SELECT * FROM wonks_ru.delete_all_user_notifications(_user_id := 3);
SELECT * FROM wonks_ru.delete_all_user_notifications(_user_id := 999);


SELECT * FROM wonks_ru.update_article_status(
        _article_id := 4,
        _moderator_id := 1,
        _new_status := 'published'::wonks_ru.article_status
              );
SELECT * FROM wonks_ru.update_article_status(
        _article_id := 5,
        _moderator_id := 2,
        _new_status := 'rejected'
              );
SELECT * FROM wonks_ru.update_article_status(
        _article_id := 4,
        _moderator_id := 3,
        _new_status := 'published'
              );
SELECT * FROM wonks_ru.update_article_status(
        _article_id := 99,
        _moderator_id := 1,
        _new_status := 'published'
              );

SELECT * FROM wonks_ru.process_report(
        _report_id := 3,
        _processor_id := 1,
        _new_status := 'pending'::wonks_ru.complaint_status
              );
SELECT * FROM wonks_ru.process_report(
        _report_id := 3,
        _processor_id := 2,
        _new_status := 'processed'::wonks_ru.complaint_status
              );
SELECT * FROM wonks_ru.process_report(
        _report_id := 4,
        _processor_id := 3,
        _new_status := 'processed'::wonks_ru.complaint_status
              );
SELECT * FROM wonks_ru.process_report(
        _report_id := 99,
        _processor_id := 1,
        _new_status := 'pending'::wonks_ru.complaint_status
              );

SELECT * FROM wonks_ru.set_user_status(
        _target_user_id := 3,
        _actor_user_id := 1,
        _new_status := 'banned'::wonks_ru.user_status
              );
SELECT * FROM wonks_ru.set_user_status(
        _target_user_id := 3,
        _actor_user_id := 1,
        _new_status := 'activated'
              );
SELECT * FROM wonks_ru.set_user_status(
        _target_user_id := 3,
        _actor_user_id := 4,
        _new_status := 'banned'
              );
SELECT * FROM wonks_ru.set_user_status(
        _target_user_id := 1,
        _actor_user_id := 1,
        _new_status := 'banned'
              );
SELECT * FROM wonks_ru.set_user_status(
        _target_user_id := 99,
        _actor_user_id := 1,
        _new_status := 'banned'
              );

SELECT * FROM wonks_ru.create_category(_actor_user_id := 1, _category_name := '  Data Science  ');
SELECT * FROM wonks_ru.create_category(_actor_user_id := 2, _category_name := 'Technology');
SELECT * FROM wonks_ru.create_category(_actor_user_id := 3, _category_name := 'My Stuff');
SELECT * FROM wonks_ru.update_category(_actor_user_id := 1, _category_id := 6, _new_category_name := 'Machine Learning');
SELECT * FROM wonks_ru.update_category(_actor_user_id := 2, _category_id := 6, _new_category_name := 'Technology');
SELECT * FROM wonks_ru.delete_category(_actor_user_id := 1, _category_id := 1);
SELECT * FROM wonks_ru.create_category(_actor_user_id := 1, _category_name := 'Temporary');
SELECT * FROM wonks_ru.delete_category(_actor_user_id := 1, _category_id := 7);

SELECT * FROM wonks_ru.create_tag(_actor_user_id := 1, _tag_name := '  Best Practices  ');
SELECT * FROM wonks_ru.create_tag(_actor_user_id := 2, _tag_name := 'SQL');
SELECT * FROM wonks_ru.update_tag(_actor_user_id := 1, _tag_id := 10, _new_tag_name := 'Coding Standards');
SELECT * FROM wonks_ru.update_tag(_actor_user_id := 2, _tag_id := 10, _new_tag_name := 'PostgreSQL');
SELECT * FROM wonks_ru.delete_tag(_actor_user_id := 1, _tag_id := 1);
SELECT * FROM wonks_ru.delete_tag(_actor_user_id := 1, _tag_id := 10);

SELECT * FROM wonks_ru.set_user_role(
        _target_user_id := 2,
        _actor_user_id := 1,
        _new_role_name := 'Administrator'
              );
SELECT * FROM wonks_ru.set_user_role(
        _target_user_id := 3,
        _actor_user_id := 1,
        _new_role_name := 'Moderator'
              );
SELECT * FROM wonks_ru.set_user_role(
        _target_user_id := 3,
        _actor_user_id := 1,
        _new_role_name := 'User'
              );
SELECT * FROM wonks_ru.set_user_role(
        _target_user_id := 4,
        _actor_user_id := 2,
        _new_role_name := 'Moderator'
              );
SELECT * FROM wonks_ru.set_user_role(
        _target_user_id := 4,
        _actor_user_id := 1,
        _new_role_name := 'SuperUser'
              );
SELECT * FROM wonks_ru.set_user_role(
        _target_user_id := 1,
        _actor_user_id := 1,
        _new_role_name := 'User'
              );
SELECT * FROM wonks_ru.set_user_role(
        _target_user_id := 2,
        _actor_user_id := 1,
        _new_role_name := 'Moderator'
              );