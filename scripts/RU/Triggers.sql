--Triggers--
set search_path = "wonks_ru";

CREATE TRIGGER trg_article_updated_at
    BEFORE UPDATE ON Articles
    FOR EACH ROW
EXECUTE PROCEDURE update_article_timestamp();

CREATE TRIGGER trg_prevent_self_subscription
    BEFORE INSERT OR UPDATE ON Subscriptions
    FOR EACH ROW
EXECUTE PROCEDURE prevent_self_subscription();

CREATE TRIGGER trg_notify_comment
    AFTER INSERT ON Comments
    FOR EACH ROW
EXECUTE PROCEDURE notify_article_author_on_comment();

CREATE TRIGGER trg_notify_followers_on_publish
    AFTER UPDATE ON Articles
    FOR EACH ROW
EXECUTE PROCEDURE notify_followers_on_article_published();
