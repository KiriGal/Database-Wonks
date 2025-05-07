set search_path = "wonks_ru";

CREATE OR REPLACE VIEW wonks_ru.view_article_comments AS
SELECT
    c.id AS comment_id,
    a.slug::TEXT AS article_slug,
    cu.username::TEXT AS username,
    c.content::TEXT AS content,
    c.created_at
FROM wonks_ru.Comments c
         JOIN wonks_ru.Users cu on cu.id = c.user_id
         JOIN wonks_ru.Articles a on a.id = c.article_id
ORDER BY c.created_at DESC;
CREATE OR REPLACE VIEW wonks_ru.view_user_favourite_articles AS
SELECT
    f.id AS favourite_id,
    u.id AS user_id,
    u.username::TEXT AS username,
    a.slug::TEXT AS slug,
    a.title::TEXT AS title,
    a.image::TEXT AS image,
    a.short_description::TEXT AS short_description
FROM wonks_ru.Favourites f
         JOIN wonks_ru.Articles    a ON f.article_id = a.id
         JOIN wonks_ru.Users       u ON f.user_id    = u.id
ORDER BY f.id DESC;
CREATE OR REPLACE VIEW wonks_ru.view_user_notification AS
SELECT
    n.id AS notification_id,
    u.id AS recipient_id,
    u.username::TEXT AS recipient_username,
    n.text::TEXT AS text,
    n.created_at,
    n.is_read
FROM wonks_ru.Notifications n
         JOIN wonks_ru.Users u ON n.user_id = u.id
ORDER BY n.created_at DESC, n.id DESC;
CREATE OR REPLACE VIEW wonks_ru.view_user_subscription AS
SELECT
    sub.id,
    sub.followed_id,
    sub.follower_id,
    followed_user.username::TEXT AS followed_username,
    follower_user.username::TEXT AS follower_username,
    sub.notices
FROM
    wonks_ru.Subscriptions sub
        JOIN wonks_ru.Users AS followed_user ON sub.followed_id = followed_user.id
        JOIN wonks_ru.Users AS follower_user ON sub.follower_id = follower_user.id
ORDER BY sub.id DESC;
CREATE OR REPLACE VIEW wonks_ru.view_reports AS
SELECT
    r.id AS report_id,
    target.id AS target_id,
    reporter.username::TEXT AS reporter_username,
    target.username::TEXT AS target_username,
    r.content::TEXT AS content,
    r.status::TEXT AS status,
    r.date
FROM wonks_ru.Reports r
         JOIN wonks_ru.Users reporter ON r.reporter_id = reporter.id
         JOIN wonks_ru.Users target   ON r.target_id   = target.id
ORDER BY r.date DESC;
CREATE OR REPLACE VIEW wonks_ru.view_articles AS
SELECT
    articles.id,
    articles.slug::TEXT AS slug,
    articles.title::TEXT AS title,
    articles.content::TEXT AS content,
    articles.short_description::TEXT AS short_description,
    articles.created_at,
    articles.updated_at,
    articles.image::TEXT AS image,
    category.name::TEXT AS category_name,
    COALESCE(array_agg(DISTINCT tag.name::TEXT) FILTER (WHERE tag.name IS NOT NULL), '{}') AS tags,
    COALESCE(ROUND(AVG(rating.value)::numeric, 2), 0.00) as rating
FROM wonks_ru.Articles articles
         LEFT JOIN wonks_ru.Ratings rating ON articles.id = rating.article_id
         LEFT JOIN wonks_ru.Categories category ON articles.category_id = category.id
         LEFT JOIN wonks_ru.Article_tags article_tag ON articles.id = article_tag.article_id
         LEFT JOIN wonks_ru.Tags tag ON article_tag.tag_id = tag.id
GROUP BY articles.id, articles.slug, articles.title, articles.content, articles.short_description, articles.created_at, articles.updated_at, articles.image, category.name
ORDER BY articles.id DESC;