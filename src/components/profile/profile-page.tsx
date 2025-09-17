'use client';

import { useState } from 'react';
import { ProfileForm } from './profile-form';
import type { Profile } from '@/lib/supabase/client';

interface ProfilePageProps {
  initialProfile: Profile;
}

export function ProfilePage({ initialProfile }: ProfilePageProps) {
  const [profile, setProfile] = useState<Profile>(initialProfile);

  const handleProfileUpdate = (updatedProfile: Profile) => {
    setProfile(updatedProfile);
  };

  return (
    <ProfileForm 
      profile={profile} 
      onProfileUpdate={handleProfileUpdate} 
    />
  );
}