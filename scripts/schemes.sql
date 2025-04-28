DROP SCHEMA IF EXISTS public CASCADE;

CREATE SCHEMA IF NOT EXISTS wonks_ru AUTHORIZATION CURRENT_USER;
CREATE SCHEMA IF NOT EXISTS wonks_en AUTHORIZATION CURRENT_USER;

SELECT current_database();
ALTER DATABASE "UsefulLinks"
    SET search_path TO wonks_ru, wonks_en;

ALTER DATABASE "UsefulLinks"
    SET search_path TO public;
