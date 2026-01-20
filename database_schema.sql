-- =============================================================================
-- Database Schema for Find-It App
-- =============================================================================
-- This script creates all necessary tables, policies, and storage buckets
-- for the Find-It campus lost and found application.
--
-- Run this in your Supabase project SQL Editor to set up the database.
--
-- Tables created:
-- - users: User accounts and profiles
-- - found_items: Reported found items with metadata
-- - contact_requests: Secure contact request system
--
-- Security:
-- - Row Level Security (RLS) enabled on all tables
-- - Public policies (adjust for production as needed)
-- - Storage bucket for images with public access

-- =============================================================================
-- Users Table
-- =============================================================================
-- Stores user account information and authentication data.
-- PRN serves as the primary key for unique identification.
CREATE TABLE users (
    prn VARCHAR PRIMARY KEY,                    -- Unique Personal Registration Number
    password_hash VARCHAR NOT NULL,             -- SHA-256 hashed password (client-side hashing)
    full_name VARCHAR NOT NULL,                 -- User's complete name
    year INTEGER NOT NULL,                      -- Academic year (1-4)
    branch VARCHAR NOT NULL,                    -- Academic branch (e.g., "Computer Science")
    department VARCHAR NOT NULL,                -- Academic department (e.g., "Engineering")
    phone_number VARCHAR NOT NULL,              -- Contact phone number
    email VARCHAR NOT NULL UNIQUE,              -- Email address (unique constraint)
    theme_preference VARCHAR DEFAULT 'light',   -- UI theme preference ('light' or 'dark')
    is_admin BOOLEAN DEFAULT false,             -- Administrative privileges flag
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- Account creation timestamp
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()  -- Last update timestamp
);

-- =============================================================================
-- Found Items Table
-- =============================================================================
-- Stores information about items that have been found and reported.
-- Includes AI-generated metadata for enhanced search capabilities.
CREATE TABLE found_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY, -- Unique item identifier
    title VARCHAR NOT NULL,                       -- Item title/name
    description TEXT NOT NULL,                    -- Detailed item description
    location VARCHAR NOT NULL,                    -- Location where item was found
    user_tags TEXT[] DEFAULT '{}',                -- User-defined tags for search
    ai_object VARCHAR,                            -- AI-detected primary object
    ai_adjectives TEXT[],                         -- AI-detected descriptive adjectives
    ai_description TEXT,                          -- AI-generated item description
    image_url VARCHAR,                            -- URL of uploaded item image
    added_by VARCHAR REFERENCES users(prn) ON DELETE CASCADE, -- Reporter's PRN
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- Item creation timestamp
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()  -- Last update timestamp
);

-- =============================================================================
-- Contact Requests Table
-- =============================================================================
-- Implements secure contact request system between finders and item reporters.
-- Protects user privacy by requiring approval before sharing contact info.
CREATE TABLE contact_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY, -- Unique request identifier
    item_id UUID REFERENCES found_items(id) ON DELETE CASCADE, -- Referenced item
    requester_prn VARCHAR NOT NULL,               -- PRN of user making request
    status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')), -- Request status
    message TEXT,                                 -- Optional message from requester
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- Request creation timestamp
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()  -- Last update timestamp
);

-- =============================================================================
-- Row Level Security (RLS) Configuration
-- =============================================================================
-- Enable RLS on all tables for fine-grained access control
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE found_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_requests ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- Security Policies
-- =============================================================================
-- Note: These policies allow all operations for development.
-- For production, implement proper authentication-based restrictions.

-- Users table policies
CREATE POLICY "Allow all operations on users" ON users FOR ALL USING (true);

-- Found items table policies
CREATE POLICY "Allow all operations on found_items" ON found_items FOR ALL USING (true);

-- Contact requests table policies
CREATE POLICY "Allow all operations on contact_requests" ON contact_requests FOR ALL USING (true);

-- =============================================================================
-- Storage Configuration
-- =============================================================================
-- Create public storage bucket for item images
INSERT INTO storage.buckets (id, name, public) VALUES ('found-items-images', 'found-items-images', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public access to images
CREATE POLICY "Public access to found-items-images" ON storage.objects FOR SELECT USING (bucket_id = 'found-items-images');

-- Full-text search function
-- Searches across title, description, AI description, and AI adjectives
-- Returns results ranked by relevance
CREATE OR REPLACE FUNCTION search_found_items(search_query text)
RETURNS TABLE (
  id uuid,
  title varchar,
  description text,
  location varchar,
  ai_description text,
  ai_adjectives text[],
  ai_object varchar,
  user_tags text[],
  created_at timestamp with time zone,
  image_url varchar,
  added_by varchar,
  updated_at timestamp with time zone
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    found_items.id,
    found_items.title,
    found_items.description,
    found_items.location,
    found_items.ai_description,
    found_items.ai_adjectives,
    found_items.ai_object,
    found_items.user_tags,
    found_items.created_at,
    found_items.image_url,
    found_items.added_by,
    found_items.updated_at
  FROM found_items
  WHERE 
    to_tsvector('english', 
      COALESCE(found_items.title, '') || ' ' || 
      COALESCE(found_items.description, '') || ' ' || 
      COALESCE(found_items.ai_description, '') || ' ' ||
      COALESCE(array_to_string(found_items.ai_adjectives, ' '), '')
    ) @@ plainto_tsquery('english', search_query)
  ORDER BY 
    ts_rank(
      to_tsvector('english', 
        COALESCE(found_items.title, '') || ' ' || 
        COALESCE(found_items.description, '') || ' ' || 
        COALESCE(found_items.ai_description, '') || ' ' ||
        COALESCE(array_to_string(found_items.ai_adjectives, ' '), '')),
      plainto_tsquery('english', search_query)
    ) DESC,
    found_items.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION search_found_items(text) TO anon;
GRANT EXECUTE ON FUNCTION search_found_items(text) TO authenticated;

-- =============================================================================
-- Additional Notes
-- =============================================================================
-- - Passwords are hashed client-side using SHA-256 for security
-- - Image URLs point to Supabase Storage public bucket
-- - Foreign key constraints ensure data integrity
-- - CASCADE deletes maintain referential integrity
-- - Timestamps are automatically managed by PostgreSQL