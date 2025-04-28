set search_path = "wonks_ru";
-- USERS
CREATE INDEX IF NOT EXISTS idx_users_role_id
    ON Users(role_id);

-- ARTICLES
CREATE INDEX IF NOT EXISTS idx_articles_user_id
    ON Articles(user_id);
CREATE INDEX IF NOT EXISTS idx_articles_category_id
    ON Articles(category_id);
CREATE INDEX IF NOT EXISTS idx_articles_status
    ON Articles(status);

-- COMMENTS
CREATE INDEX IF NOT EXISTS idx_comments_article_id
    ON Comments(article_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id
    ON Comments(user_id);

-- ARTICLE_TAGS
CREATE INDEX IF NOT EXISTS idx_article_tags_tag_id
    ON Article_tags(tag_id);

-- FAVOURITES
CREATE INDEX IF NOT EXISTS idx_favourites_user_id
    ON Favourites(user_id);
CREATE INDEX IF NOT EXISTS idx_favourites_article_id
    ON Favourites(article_id);

-- RATINGS
CREATE INDEX IF NOT EXISTS idx_ratings_user_id
    ON Ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_article_id
    ON Ratings(article_id);

-- NOTIFICATIONS
CREATE INDEX IF NOT EXISTS idx_notifications_user_id
    ON Notifications(user_id);

-- SUBSCRIPTIONS
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id
    ON Subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_follow_id
    ON Subscriptions(follow_id);

-- REPORTS
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id
    ON Reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_target_id
    ON Reports(target_id);
CREATE INDEX IF NOT EXISTS idx_reports_status
    ON Reports(status);
