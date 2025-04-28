set search_path = wonks_ru;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO Roles (id, name)
VALUES (1, 'Administrator'),
       (2, 'Moderator'),
       (3, 'User'),
       (4, 'Guest')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Categories (id, name)
VALUES (1, 'Technology'),
       (2, 'Science'),
       (3, 'Lifestyle'),
       (4, 'Programming'),
       (5, 'Databases')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Tags (id, name)
VALUES (1, 'PostgreSQL'),
       (2, 'SQL'),
       (3, 'Web Development'),
       (4, 'AI'),
       (5, 'Machine Learning'),
       (6, 'Health'),
       (7, 'Travel'),
       (8, 'Views'),
       (9, 'Functions')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Users (id, avatar_url, username, email, password_hash, role_id, status, last_login)
VALUES (1, 'avatars/admin.png', 'AdminUser', 'admin@wonks.ru', 'hashed_password_placeholder', 1, 'activated',
        NOW() - INTERVAL '1 hour'),
       (2, 'avatars/editor.png', 'EditorUser', 'editor@wonks.ru', 'hashed_password_placeholder', 2, 'activated',
        NOW() - INTERVAL '2 hour'),
       (3, 'avatars/jane.png', 'JaneDoe', 'jane.doe@wonks.ru', 'hashed_password_placeholder', 3, 'activated',
        NOW() - INTERVAL '30 minutes'),
       (4, 'avatars/john.png', 'JohnSmith', 'john.smith@wonks.ru', 'hashed_password_placeholder', 3, 'activated',
        NOW() - INTERVAL '5 minutes'),
       (5, 'avatars/bob.png', 'BobCoder', 'bob.coder@wonks.ru', 'hashed_password_placeholder', 3, 'activated',
        NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Articles (id, slug, user_id, content, short_description, image, category_id, status, title, created_at,
                      updated_at)
VALUES (1, 'intro-to-sql-views', 2, 'Views are virtual tables based on the result-set of an SQL statement...',
        'A beginner guide to understanding SQL views.', 'images/sql-views.jpg', 5, 'published',
        'Introduction to SQL Views', NOW() - INTERVAL '3 day', NOW() - INTERVAL '2 day'),
       (2, 'postgresql-functions-explained', 5,
        'PostgreSQL functions, also known as stored procedures, allow you to extend the database functionality...',
        'Deep dive into creating and using PostgreSQL functions.', 'images/pg-functions.png', 4, 'published',
        'PostgreSQL Functions Explained', NOW() - INTERVAL '2 day', NOW() - INTERVAL '1 day'),
       (3, 'ai-in-everyday-life', 3,
        'Artificial intelligence is becoming increasingly integrated into our daily lives...',
        'Exploring the impact of AI on modern living.', 'images/ai-daily.webp', 1, 'published', 'AI in Everyday Life',
        NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
       (4, 'healthy-eating-tips', 4, 'Maintaining a healthy diet is crucial for well-being...',
        'Simple tips for a healthier diet.', 'images/healthy-food.jpg', 3, 'moderated', 'Healthy Eating Tips for Beginners',
        NOW() - INTERVAL '5 hours', NOW() - INTERVAL '1 hour'),
       (5, 'getting-started-with-wonks-ru', 1, 'Welcome to Wonks.ru! This platform allows you to share knowledge...',
        'A quick guide on how to use the Wonks.ru platform.', 'noimage.png', 1, 'published',
        'Getting Started with Wonks.ru', NOW() - INTERVAL '5 day', NOW() - INTERVAL '5 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Article_tags (article_id, tag_id)
VALUES (1, 1),
       (1, 2),
       (1, 8),
       (2, 1),
       (2, 2),
       (2, 9),
       (2, 4),
       (3, 4),
       (3, 5),
       (4, 6)
ON CONFLICT (article_id, tag_id) DO NOTHING;


INSERT INTO Comments (article_id, user_id, content, created_at)
VALUES (1, 3, 'Great explanation of SQL views, thanks!', NOW() - INTERVAL '1 day'),
       (1, 4, 'Very helpful for beginners.', NOW() - INTERVAL '23 hours'),
       (2, 1, 'Excellent article on functions. Consider adding examples with different languages like PL/Python.',
        NOW() - INTERVAL '10 hours'),
       (3, 5, 'Fascinating read about AI integration.', NOW() - INTERVAL '5 hours'),
       (2, 3, 'I always wondered how functions worked in PG. Clear explanation!', NOW() - INTERVAL '1 hour')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Favourites (user_id, article_id)
VALUES (3, 1),
       (4, 1),
       (1, 2),
       (3, 2),
       (5, 3)
ON CONFLICT (user_id, article_id) DO NOTHING;

INSERT INTO Ratings (user_id, article_id, value)
VALUES (3, 1, 5),
       (4, 1, 4),
       (1, 2, 5),
       (5, 2, 4),
       (3, 3, 5)
ON CONFLICT (user_id, article_id) DO NOTHING;


INSERT INTO Notifications (user_id, text, created_at)
VALUES (3, 'Your article AI in Everyday Life received a new comment.', NOW() - INTERVAL '5 hours'),
       (2, 'Your article Introduction to SQL Views received a new rating.', NOW() - INTERVAL '1 day'),
       (1, 'New report submitted regarding user JohnSmith.', NOW() - INTERVAL '1 hour'),
       (4, 'JaneDoe started following you.', NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO Subscriptions (follower_id, followed_id, notices)
VALUES (3, 2, true),
       (4, 3, false),
       (5, 1, true),
       (3, 5, true),
       (1, 3, false)
ON CONFLICT (follower_id, followed_id) DO NOTHING;


INSERT INTO Reports (reporter_id, target_id, content, status, date)
VALUES (3, 4, 'User JohnSmith posted inappropriate comments on article ID 1.', 'dispatched',
        NOW() - INTERVAL '2 hours'),
       (5, 3, 'User JaneDoe seems to be spamming ratings.', 'dispatched', NOW() - INTERVAL '1 hour')
ON CONFLICT (id) DO NOTHING;


SELECT setval(pg_get_serial_sequence('Roles', 'id'), COALESCE(max(id), 1)) FROM Roles;
SELECT setval(pg_get_serial_sequence('Categories', 'id'), COALESCE(max(id), 1)) FROM Categories;
SELECT setval(pg_get_serial_sequence('Tags', 'id'), COALESCE(max(id), 1)) FROM Tags;
SELECT setval(pg_get_serial_sequence('Users', 'id'), COALESCE(max(id), 1)) FROM Users;
SELECT setval(pg_get_serial_sequence('Articles', 'id'), COALESCE(max(id), 1)) FROM Articles;
SELECT setval(pg_get_serial_sequence('Comments', 'id'), COALESCE(max(id), 1)) FROM Comments;
SELECT setval(pg_get_serial_sequence('Article_tags', 'id'), COALESCE(max(id), 1)) FROM Article_tags;
SELECT setval(pg_get_serial_sequence('Favourites', 'id'), COALESCE(max(id), 1)) FROM Favourites;
SELECT setval(pg_get_serial_sequence('Ratings', 'id'), COALESCE(max(id), 1)) FROM Ratings;
SELECT setval(pg_get_serial_sequence('Notifications', 'id'), COALESCE(max(id), 1)) FROM Notifications;
SELECT setval(pg_get_serial_sequence('Subscriptions', 'id'), COALESCE(max(id), 1)) FROM Subscriptions;
SELECT setval(pg_get_serial_sequence('Reports', 'id'), COALESCE(max(id), 1)) FROM Reports;