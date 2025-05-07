SET search_path = "wonks_ru";

-- === Таблица Users ====
CREATE INDEX IF NOT EXISTS idx_users_role_id ON Users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_status ON Users(status);
CREATE INDEX IF NOT EXISTS idx_users_username ON Users(username);

-- === Таблица Comments ===
CREATE INDEX IF NOT EXISTS idx_comments_article_id ON Comments(article_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON Comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON Comments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_article_created ON Comments(article_id, created_at DESC);

-- === Таблица Articles ===
CREATE INDEX IF NOT EXISTS idx_articles_user_id ON Articles(user_id);
CREATE INDEX IF NOT EXISTS idx_articles_category_id ON Articles(category_id);
CREATE INDEX IF NOT EXISTS idx_articles_status ON Articles(status);
CREATE INDEX IF NOT EXISTS idx_articles_created_at ON Articles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_articles_updated_at ON Articles(updated_at DESC);

-- === Таблица Article_tags ===
CREATE INDEX IF NOT EXISTS idx_article_tags_tag_id ON Article_tags(tag_id);

-- === Таблица Favourites ===
CREATE INDEX IF NOT EXISTS idx_favourites_article_id ON Favourites(article_id);

-- === Таблица Ratings ===
CREATE INDEX IF NOT EXISTS idx_ratings_article_id ON Ratings(article_id);

-- === Таблица Notifications ===
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON Notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON Notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON Notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_is_read ON Notifications (user_id, is_read);

-- === Таблица Subscriptions ===
CREATE INDEX IF NOT EXISTS idx_subscriptions_followed_id ON Subscriptions(followed_id);

-- === Таблица Reports ===
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON Reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_target_id ON Reports(target_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON Reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_date ON Reports(date DESC);
CREATE INDEX IF NOT EXISTS idx_reports_status_date ON Reports(status, date DESC);
