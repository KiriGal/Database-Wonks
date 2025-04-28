SET search_path = "wonks_ru";

-- === Таблица Users ====
CREATE INDEX IF NOT EXISTS idx_users_role_id ON wonks_ru.Users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_status ON wonks_ru.Users(status);
CREATE INDEX IF NOT EXISTS idx_users_username ON wonks_ru.Users(username);

-- === Таблица Comments ===
CREATE INDEX IF NOT EXISTS idx_comments_article_id ON wonks_ru.Comments(article_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON wonks_ru.Comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON wonks_ru.Comments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_article_created ON wonks_ru.Comments(article_id, created_at DESC);


-- === Таблица Articles ===
CREATE INDEX IF NOT EXISTS idx_articles_user_id ON wonks_ru.Articles(user_id);
CREATE INDEX IF NOT EXISTS idx_articles_category_id ON wonks_ru.Articles(category_id);
CREATE INDEX IF NOT EXISTS idx_articles_status ON wonks_ru.Articles(status);
CREATE INDEX IF NOT EXISTS idx_articles_created_at ON wonks_ru.Articles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_articles_updated_at ON wonks_ru.Articles(updated_at DESC);


-- === Таблица Article_tags ===
CREATE INDEX IF NOT EXISTS idx_article_tags_tag_id ON wonks_ru.Article_tags(tag_id);


-- === Таблица Favourites ===
CREATE INDEX IF NOT EXISTS idx_favourites_article_id ON wonks_ru.Favourites(article_id);


-- === Таблица Ratings ===
CREATE INDEX IF NOT EXISTS idx_ratings_article_id ON wonks_ru.Ratings(article_id);


-- === Таблица Notifications ===
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON wonks_ru.Notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON wonks_ru.Notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON wonks_ru.Notifications(user_id, created_at DESC);


-- === Таблица Subscriptions ===
CREATE INDEX IF NOT EXISTS idx_subscriptions_followed_id ON wonks_ru.Subscriptions(followed_id);


-- === Таблица Reports ===
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON wonks_ru.Reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_target_id ON wonks_ru.Reports(target_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON wonks_ru.Reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_date ON wonks_ru.Reports(date DESC);
CREATE INDEX IF NOT EXISTS idx_reports_status_date ON wonks_ru.Reports(status, date DESC);
