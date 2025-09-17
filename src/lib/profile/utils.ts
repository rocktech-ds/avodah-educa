import { createClient } from '@/lib/supabase/client';
import { createClient as createServerClient } from '@/lib/supabase/server';
import type { Profile, TablesUpdate } from '@/lib/supabase/client';

export interface ProfileUpdateData {
  fullName?: string;
  bio?: string;
  phone?: string;
  dateOfBirth?: string;
  avatarUrl?: string;
  preferences?: {
    language?: string;
    timezone?: string;
    emailNotifications?: boolean;
    pushNotifications?: boolean;
    marketingEmails?: boolean;
    theme?: 'light' | 'dark' | 'system';
  };
  address?: {
    street?: string;
    city?: string;
    state?: string;
    country?: string;
    zipCode?: string;
  };
}

// Client-side profile utilities
export class ProfileClient {
  private supabase = createClient();

  /**
   * Get current user's profile
   */
  async getProfile(): Promise<Profile | null> {
    try {
      const { data: { user } } = await this.supabase.auth.getUser();
      
      if (!user) {
        throw new Error('User not authenticated');
      }

      const { data, error } = await this.supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Get profile error:', error);
      throw error;
    }
  }

  /**
   * Update current user's profile
   */
  async updateProfile(updates: ProfileUpdateData): Promise<Profile> {
    try {
      const { data: { user } } = await this.supabase.auth.getUser();
      
      if (!user) {
        throw new Error('User not authenticated');
      }

      const profileUpdates: TablesUpdate<'profiles'> = {};

      if (updates.fullName) profileUpdates.full_name = updates.fullName;
      if (updates.bio !== undefined) profileUpdates.bio = updates.bio;
      if (updates.phone !== undefined) profileUpdates.phone = updates.phone;
      if (updates.dateOfBirth !== undefined) profileUpdates.date_of_birth = updates.dateOfBirth;
      if (updates.avatarUrl !== undefined) profileUpdates.avatar_url = updates.avatarUrl;
      if (updates.preferences) profileUpdates.preferences = updates.preferences;
      if (updates.address) profileUpdates.address = updates.address;

      const { data, error } = await this.supabase
        .from('profiles')
        .update(profileUpdates)
        .eq('id', user.id)
        .select()
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Update profile error:', error);
      throw error;
    }
  }

  /**
   * Upload avatar image
   */
  async uploadAvatar(file: File): Promise<string> {
    try {
      const { data: { user } } = await this.supabase.auth.getUser();
      
      if (!user) {
        throw new Error('User not authenticated');
      }

      // Create unique filename
      const fileExt = file.name.split('.').pop();
      const fileName = `${user.id}-${Date.now()}.${fileExt}`;
      const filePath = `avatars/${fileName}`;

      const { error: uploadError } = await this.supabase.storage
        .from('profiles')
        .upload(filePath, file, {
          cacheControl: '3600',
          upsert: false
        });

      if (uploadError) {
        throw new Error(uploadError.message);
      }

      // Get public URL
      const { data } = this.supabase.storage
        .from('profiles')
        .getPublicUrl(filePath);

      return data.publicUrl;
    } catch (error) {
      console.error('Upload avatar error:', error);
      throw error;
    }
  }

  /**
   * Delete old avatar
   */
  async deleteAvatar(avatarUrl: string): Promise<void> {
    try {
      if (!avatarUrl) return;

      // Extract file path from URL
      const urlParts = avatarUrl.split('/');
      const filePath = `avatars/${urlParts[urlParts.length - 1]}`;

      const { error } = await this.supabase.storage
        .from('profiles')
        .remove([filePath]);

      if (error) {
        console.warn('Delete avatar error:', error.message);
        // Don't throw error as this is cleanup
      }
    } catch (error) {
      console.warn('Delete avatar error:', error);
    }
  }

  /**
   * Get profile by ID (for public profiles)
   */
  async getProfileById(profileId: string): Promise<Profile | null> {
    try {
      const { data, error } = await this.supabase
        .from('profiles')
        .select('id, email, full_name, avatar_url, bio, role, created_at')
        .eq('id', profileId)
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data as Profile;
    } catch (error) {
      console.error('Get profile by ID error:', error);
      return null;
    }
  }

  /**
   * Search profiles (for admin/teacher use)
   */
  async searchProfiles(query: string, role?: string): Promise<Profile[]> {
    try {
      let queryBuilder = this.supabase
        .from('profiles')
        .select('id, email, full_name, avatar_url, role, created_at')
        .or(`full_name.ilike.%${query}%, email.ilike.%${query}%`)
        .limit(20);

      if (role) {
        queryBuilder = queryBuilder.eq('role', role);
      }

      const { data, error } = await queryBuilder;

      if (error) {
        throw new Error(error.message);
      }

      return data as Profile[];
    } catch (error) {
      console.error('Search profiles error:', error);
      throw error;
    }
  }
}

// Server-side profile utilities
export class ProfileServer {
  /**
   * Get profile by ID (server-side)
   */
  static async getProfileById(profileId: string): Promise<Profile | null> {
    try {
      const supabase = await createServerClient();
      
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', profileId)
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Server get profile error:', error);
      return null;
    }
  }

  /**
   * Get current user's profile (server-side)
   */
  static async getCurrentProfile(): Promise<Profile | null> {
    try {
      const supabase = await createServerClient();
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return null;
      }

      return await this.getProfileById(user.id);
    } catch (error) {
      console.error('Server get current profile error:', error);
      return null;
    }
  }

  /**
   * Update profile (admin only)
   */
  static async updateProfileAsAdmin(profileId: string, updates: ProfileUpdateData): Promise<Profile> {
    try {
      const supabase = await createServerClient();
      
      const profileUpdates: TablesUpdate<'profiles'> = {};

      if (updates.fullName) profileUpdates.full_name = updates.fullName;
      if (updates.bio !== undefined) profileUpdates.bio = updates.bio;
      if (updates.phone !== undefined) profileUpdates.phone = updates.phone;
      if (updates.dateOfBirth !== undefined) profileUpdates.date_of_birth = updates.dateOfBirth;
      if (updates.avatarUrl !== undefined) profileUpdates.avatar_url = updates.avatarUrl;
      if (updates.preferences) profileUpdates.preferences = updates.preferences;
      if (updates.address) profileUpdates.address = updates.address;

      const { data, error } = await supabase
        .from('profiles')
        .update(profileUpdates)
        .eq('id', profileId)
        .select()
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Admin update profile error:', error);
      throw error;
    }
  }

  /**
   * Get all profiles (admin only, with pagination)
   */
  static async getAllProfiles(page = 1, limit = 20, role?: string): Promise<{profiles: Profile[], total: number}> {
    try {
      const supabase = await createServerClient();
      
      let query = supabase
        .from('profiles')
        .select('*', { count: 'exact' })
        .order('created_at', { ascending: false });

      if (role) {
        query = query.eq('role', role);
      }

      const { data, error, count } = await query
        .range((page - 1) * limit, page * limit - 1);

      if (error) {
        throw new Error(error.message);
      }

      return {
        profiles: data || [],
        total: count || 0
      };
    } catch (error) {
      console.error('Get all profiles error:', error);
      throw error;
    }
  }
}

// Export instances for convenience
export const profileClient = new ProfileClient();
export const profileServer = ProfileServer;