import { Suspense } from 'react';
import { redirect } from 'next/navigation';
import { ProfilePage as ProfilePageComponent } from '@/components/profile/profile-page';
import { profileServer } from '@/lib/profile/utils';
import { authServer } from '@/lib/auth/utils';

export default async function ProfilePage() {
  // Ensure user is authenticated
  const user = await authServer.getUser();
  if (!user) {
    redirect('/auth/login');
  }

  // Get user profile
  const profile = await profileServer.getCurrentProfile();
  if (!profile) {
    redirect('/auth/login');
  }

  return (
    <div className="container mx-auto py-8 px-4">
      <div className="max-w-4xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Meu Perfil</h1>
          <p className="text-gray-600 mt-2">
            Gerencie suas informações pessoais e preferências de conta
          </p>
        </div>

        <Suspense fallback={
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-platform"></div>
          </div>
        }>
          <ProfilePageComponent initialProfile={profile} />
        </Suspense>
      </div>
    </div>
  );
}