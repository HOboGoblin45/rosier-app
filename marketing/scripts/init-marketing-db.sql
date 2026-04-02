-- Initialize marketing stack databases
-- This script creates all required databases for Listmonk, n8n, Mixpost, and Plausible

-- Create Listmonk database and user
CREATE USER listmonk WITH PASSWORD :'LISTMONK_DB_PASSWORD';
CREATE DATABASE listmonk OWNER listmonk;
GRANT ALL PRIVILEGES ON DATABASE listmonk TO listmonk;

-- Create n8n database and user
CREATE USER n8n WITH PASSWORD :'N8N_DB_PASSWORD';
CREATE DATABASE n8n OWNER n8n;
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;

-- Create Mixpost database and user
CREATE USER mixpost WITH PASSWORD :'MIXPOST_DB_PASSWORD';
CREATE DATABASE mixpost OWNER mixpost;
GRANT ALL PRIVILEGES ON DATABASE mixpost TO mixpost;

-- Create Plausible database and user
CREATE USER plausible WITH PASSWORD :'PLAUSIBLE_DB_PASSWORD';
CREATE DATABASE plausible OWNER plausible;
GRANT ALL PRIVILEGES ON DATABASE plausible TO plausible;

-- Note: In production, you should run Listmonk, n8n, and Mixpost migrations
-- after the containers start. Each tool will automatically create required tables.
--
-- For Listmonk: Migrations run automatically on first startup
-- For n8n: Migrations run automatically on first startup
-- For Mixpost: Run migrations with: docker-compose exec mixpost php artisan migrate
-- For Plausible: Migrations run automatically on first startup
