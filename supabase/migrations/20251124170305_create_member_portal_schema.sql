/*
  # E-Cell VIT Bhopal Member Portal Schema

  1. New Tables
    - `profiles`
      - `id` (uuid, primary key, references auth.users)
      - `full_name` (text, required)
      - `email` (text, unique, required)
      - `phone` (text)
      - `department` (text)
      - `year` (text)
      - `bio` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `events`
      - `id` (uuid, primary key)
      - `title` (text, required)
      - `description` (text)
      - `event_date` (timestamptz, required)
      - `location` (text)
      - `max_participants` (integer)
      - `status` (text, active/cancelled/completed)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `event_registrations`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references profiles)
      - `event_id` (uuid, references events)
      - `registered_at` (timestamptz)
      - `status` (text, registered/cancelled/attended)

  2. Security
    - Enable RLS on all tables
    - Users can read and update their own profile
    - All authenticated users can view events
    - Users can view and manage their own event registrations
    - Only authenticated users can register for events
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  email text UNIQUE NOT NULL,
  phone text,
  department text,
  year text,
  bio text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Create events table
CREATE TABLE IF NOT EXISTS events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  event_date timestamptz NOT NULL,
  location text,
  max_participants integer DEFAULT 0,
  status text DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'completed')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view events"
  ON events FOR SELECT
  TO authenticated
  USING (true);

-- Create event_registrations table
CREATE TABLE IF NOT EXISTS event_registrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  registered_at timestamptz DEFAULT now(),
  status text DEFAULT 'registered' CHECK (status IN ('registered', 'cancelled', 'attended')),
  UNIQUE(user_id, event_id)
);

ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own registrations"
  ON event_registrations FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own registrations"
  ON event_registrations FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own registrations"
  ON event_registrations FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Insert sample events
INSERT INTO events (title, description, event_date, location, max_participants, status)
VALUES 
  ('Startup Pitch Competition', 'Present your startup ideas to industry experts and investors', '2025-12-15 14:00:00+00', 'VIT Bhopal Auditorium', 50, 'active'),
  ('Entrepreneurship Workshop', 'Learn the fundamentals of starting and running a business', '2025-12-01 10:00:00+00', 'Seminar Hall A', 100, 'active'),
  ('Industry Expert Talk', 'Meet successful entrepreneurs and learn from their journey', '2025-12-08 16:00:00+00', 'Conference Room', 75, 'active'),
  ('Hackathon 2025', '24-hour coding marathon to build innovative solutions', '2025-12-20 09:00:00+00', 'Computer Lab', 150, 'active');
