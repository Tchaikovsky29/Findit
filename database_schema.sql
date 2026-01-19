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