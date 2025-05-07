set search_path = wonks_ru;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO Roles (id, name)
VALUES (1, 'Administrator'),
       (2, 'Moderator'),
       (3, 'User'),
       (4, 'Guest')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Categories (id, name)
VALUES (1, 'Технологии'),
       (2, 'Наука'),
       (3, 'Образ жизни'),
       (4, 'Программирование'),
       (5, 'Базы данных')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Tags (id, name)
VALUES (1, 'PostgreSQL'),
       (2, 'SQL'),
       (3, 'Веб-разработка'),
       (4, 'ИИ'),
       (5, 'Машинное обучение'),
       (6, 'Здоровье'),
       (7, 'Путешествия'),
       (8, 'Представления'),
       (9, 'Функции')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Users (id, avatar_url, username, email, password_hash, role_id, status, last_login)
VALUES (1, 'avatars/admin.png',  'AdminUser',  'admin@wonks.ru',  'hashed_password_placeholder', 1, 'activated', NOW() - INTERVAL '1 hour'),
       (2, 'avatars/Moderator.png', 'ModeratorUser', 'moderator@wonks.ru', 'hashed_password_placeholder', 2, 'activated', NOW() - INTERVAL '2 hour'),
       (3, 'avatars/jane.png',   'JaneDoe',    'jane.doe@wonks.ru','hashed_password_placeholder',3, 'activated', NOW() - INTERVAL '30 minutes'),
       (4, 'avatars/john.png',   'JohnSmith',  'john.smith@wonks.ru','hashed_password_placeholder',3, 'activated', NOW() - INTERVAL '5 minutes'),
       (5, 'avatars/bob.png',    'BobCoder',   'bob.coder@wonks.ru','hashed_password_placeholder',3, 'activated', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Articles (id, slug, user_id, content, short_description, image, category_id, status, title, created_at, updated_at)
VALUES
    (1,'vvedenie-v-sql-predstavleniya',2,'Представления — это виртуальные таблицы, основанные на результирующем наборе SQL-запроса...','Руководство для начинающих по пониманию представлений SQL.','images/sql-views.jpg',5,'published','Введение в представления SQL',NOW() - INTERVAL '3 day',NOW() - INTERVAL '2 day'),
    (2,'funktsii-postgresql-obyasneny',5,'Функции PostgreSQL, также известные как хранимые процедуры, позволяют расширять функциональность базы данных...','Глубокое погружение в создание и использование функций PostgreSQL.','images/pg-functions.png',4,'published','Функции PostgreSQL: подробное объяснение',NOW() - INTERVAL '2 day',NOW() - INTERVAL '1 day'),
    (3,'ii-v-povsednevnoi-zhizni',3,'Искусственный интеллект всё глубже интегрируется в нашу повседневную жизнь...','Исследуем влияние ИИ на современную жизнь.','images/ai-daily.webp',1,'published','ИИ в повседневной жизни',NOW() - INTERVAL '1 day',NOW() - INTERVAL '1 day'),
    (4,'sovety-po-zdorovomu-pitaniyu',4,'Поддержание здорового рациона крайне важно для благополучия...','Простые советы для более здорового питания.','images/healthy-food.jpg',3,'moderated','Советы по здоровому питанию для начинающих',NOW() - INTERVAL '5 hours',NOW() - INTERVAL '1 hour'),
    (5,'znakomstvo-s-wonks-ru',1,'Добро пожаловать на Wonks.ru! Эта платформа позволяет делиться знаниями...','Краткое руководство по использованию платформы Wonks.ru.','noimage.png',1,'published','Знакомство с Wonks.ru',NOW() - INTERVAL '5 day',NOW() - INTERVAL '5 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Article_tags (article_id, tag_id)
VALUES (1,1),(1,2),(1,8),(2,1),(2,2),(2,9),(2,4),(3,4),(3,5),(4,6)
ON CONFLICT (article_id, tag_id) DO NOTHING;

INSERT INTO Comments (article_id, user_id, content, created_at)
VALUES (1,3,'Отличное объяснение представлений SQL, спасибо!',NOW() - INTERVAL '1 day'),
       (1,4,'Очень полезно для новичков.',NOW() - INTERVAL '23 hours'),
       (2,1,'Превосходная статья о функциях. Добавьте, пожалуйста, примеры на PL/Python.',NOW() - INTERVAL '10 hours'),
       (3,5,'Увлекательный материал про интеграцию ИИ.',NOW() - INTERVAL '5 hours'),
       (2,3,'Всегда хотел понять, как работают функции в PG. Всё ясно!',NOW() - INTERVAL '1 hour')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Favourites (user_id, article_id)
VALUES (3,1),(4,1),(1,2),(3,2),(5,3)
ON CONFLICT (user_id, article_id) DO NOTHING;

INSERT INTO Ratings (user_id, article_id, value)
VALUES (3,1,5),(4,1,4),(1,2,5),(5,2,4),(3,3,5)
ON CONFLICT (user_id, article_id) DO NOTHING;

INSERT INTO Notifications (user_id, text, created_at)
VALUES (3,'Вашу статью «ИИ в повседневной жизни» прокомментировали.',NOW() - INTERVAL '5 hours'),
       (2,'Ваша статья «Введение в представления SQL» получила новую оценку.',NOW() - INTERVAL '1 day'),
       (1,'Поступила жалоба на пользователя JohnSmith.',NOW() - INTERVAL '1 hour'),
       (4,'JaneDoe подписалась на вас.',NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO Subscriptions (follower_id, followed_id, notices)
VALUES (3,2,true),(4,3,false),(5,1,true),(3,5,true),(1,3,false)
ON CONFLICT (follower_id, followed_id) DO NOTHING;

INSERT INTO Reports (reporter_id, target_id, content, status, date)
VALUES (3,4,'Пользователь JohnSmith оставил неприемлемые комментарии к статье 1.','dispatched',NOW() - INTERVAL '2 hours'),
       (5,3,'Пользователь JaneDoe, похоже, спамит оценками.','dispatched',NOW() - INTERVAL '1 hour')
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