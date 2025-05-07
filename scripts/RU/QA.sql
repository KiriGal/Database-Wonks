set search_path = "wonks_ru";
---------------------- Вставка 100000 строк ----------------------
SELECT setval(
               pg_get_serial_sequence('wonks_ru."articles"', 'id'),
               COALESCE((SELECT MAX(id) FROM wonks_ru.articles), 1)
       );

CREATE OR REPLACE FUNCTION insert_articles() RETURNS VOID AS $$
DECLARE
    i INTEGER;
    s ARTICLE_STATUS;
BEGIN
    FOR i IN 30..100000 LOOP
            s := (ARRAY['moderated'::ARTICLE_STATUS,'published'::ARTICLE_STATUS,'rejected'::ARTICLE_STATUS])[floor(random() * 3 + 1)];
            INSERT INTO articles ( slug, user_id, content, short_description, image, category_id, status, title)
            VALUES ('slug_' || i,1, 'content_' || i, 'short_description_' || i, DEFAULT,1,s,'title_' || i);
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
