-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create custom types
CREATE TYPE subscription_status AS ENUM ('active', 'inactive', 'canceled', 'past_due', 'trialing');
CREATE TYPE broadcast_status AS ENUM ('draft', 'scheduled', 'sending', 'paused', 'completed', 'canceled', 'failed');
CREATE TYPE message_type AS ENUM ('text', 'image', 'video', 'audio', 'document', 'button', 'quick_reply', 'carousel', 'template');
CREATE TYPE flow_node_type AS ENUM ('start', 'text', 'image', 'video', 'audio', 'document', 'buttons', 'quick_replies', 'carousel', 'gallery', 'delay', 'condition', 'random_split', 'keyword', 'tag_condition', 'api_request', 'webhook', 'openai', 'http_request', 'json_parser', 'variables', 'set_variable', 'if_else', 'goal', 'end');
CREATE TYPE automation_action_type AS ENUM ('reply_text', 'reply_image', 'like_comment', 'hide_comment', 'delete_comment', 'send_messenger', 'assign_tag', 'assign_custom_field', 'trigger_workflow', 'add_note');
CREATE TYPE conversation_status AS ENUM ('active', 'waiting', 'closed', 'archived');
CREATE TYPE notification_type AS ENUM ('broadcast_complete', 'broadcast_failed', 'subscriber_gained', 'subscriber_lost', 'automation_triggered', 'system_alert', 'team_invite', 'subscription_expiring', 'payment_failed');

-- Create function for updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create function to generate unique slugs
CREATE OR REPLACE FUNCTION generate_unique_slug(
    table_name text,
    column_name text,
    base_string text
) RETURNS text AS $$
DECLARE
    slug text;
    counter integer := 1;
    exists_check boolean;
BEGIN
    slug := lower(regexp_replace(regexp_replace(base_string, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
    LOOP
        EXECUTE format('SELECT EXISTS(SELECT 1 FROM %I WHERE %I = %L)', table_name, column_name, slug)
        INTO exists_check;
        IF NOT exists_check THEN
            RETURN slug;
        END IF;
        slug := slug || '-' || counter::text;
        counter := counter + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
