set search_path = "wonks_ru";
---------------------- Вставка 100000 строк ----------------------
CREATE OR REPLACE FUNCTION insert_articles() RETURNS VOID AS $$
DECLARE
    i INTEGER;
    s article_status_t;
BEGIN
    FOR i IN 30..100000 LOOP
            s := (ARRAY[
                'moderated'::article_status_t,
                'published'::article_status_t,
                'rejected'::article_status_t
                ])[floor(random() * 3 + 1)];

            INSERT INTO Articles (slug, user_id, content, image, category_id, status, ratings, title)
            VALUES (
                       'slug_' || i,
                       1,
                       'content_' || i,
                       DEFAULT,
                       1,
                       s,
                       floor(random() * 5 + 1),
                       'title_' || i
                   );
        END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Вставка 100000 строк
SELECT insert_articles();

-- Проверка вставки
SELECT COUNT(*) FROM Articles;
SELECT * FROM Articles LIMIT 100;

-- Анализ производительности
EXPLAIN ANALYZE SELECT title FROM Articles WHERE content = 'content_1024';
CREATE INDEX idx_articles_content ON Articles (content);
SELECT * FROM pg_indexes WHERE tablename = 'articles';

DROP INDEX IF EXISTS idx_articles_content;
DROP FUNCTION IF EXISTS insert_articles();
