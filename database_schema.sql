-- Database Schema for Find-It App
-- Run this in Supabase SQL Editor to create the necessary tables

-- Users table for authentication and user data
CREATE TABLE users (
    prn VARCHAR PRIMARY KEY,
    password_hash VARCHAR NOT NULL,
    full_name VARCHAR NOT NULL,
    year INTEGER NOT NULL,
    branch VARCHAR NOT NULL,
    department VARCHAR NOT NULL,
    phone_number VARCHAR NOT NULL,
    email VARCHAR NOT NULL UNIQUE,
    theme_preference VARCHAR DEFAULT 'light',
    is_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Found items table
CREATE TABLE found_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR NOT NULL,
    user_tags TEXT[] DEFAULT '{}',
    ai_object VARCHAR,
    ai_adjectives TEXT[],
    ai_description TEXT,
    image_url VARCHAR,
    added_by VARCHAR REFERENCES users(prn) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE found_items ENABLE ROW LEVEL SECURITY;

-- Policies for users table (allow public read/write for now, adjust as needed)
-- For production, restrict based on authentication
CREATE POLICY "Allow all operations on users" ON users FOR ALL USING (true);

-- Policies for found_items
CREATE POLICY "Allow all operations on found_items" ON found_items FOR ALL USING (true);

-- Contact requests table (for in-app notifications)
CREATE TABLE contact_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    item_id UUID REFERENCES found_items(id) ON DELETE CASCADE,
    requester_prn VARCHAR NOT NULL,
    status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for contact_requests
ALTER TABLE contact_requests ENABLE ROW LEVEL SECURITY;

-- Policies for contact_requests
CREATE POLICY "Allow all operations on contact_requests" ON contact_requests FOR ALL USING (true);

-- Create storage bucket for images (if not exists)
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