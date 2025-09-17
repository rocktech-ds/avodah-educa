import { createClient } from '@/lib/supabase/client';
import { createClient as createServerClient } from '@/lib/supabase/server';
import type { UserRole, AuthUser, LoginCredentials, SignupCredentials } from '@/types/auth';

// Client-side auth utilities
export class AuthClient {
  private supabase = createClient();

  /**
   * Sign up a new user
   */
  async signUp({ email, password, fullName, role = 'student' }: SignupCredentials) {
    try {
      const { data, error } = await this.supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName,
            role: role,
          },
        },
      });

      if (error) {
        throw new Error(error.message);
      }

      return { user: data.user, session: data.session };
    } catch (error) {
      console.error('Sign up error:', error);
      throw error;
    }
  }

  /**
   * Sign in with email and password
   */
  async signIn({ email, password }: LoginCredentials) {
    try {
      const { data, error } = await this.supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        throw new Error(error.message);
      }

      return { user: data.user, session: data.session };
    } catch (error) {
      console.error('Sign in error:', error);
      throw error;
    }
  }

  /**
   * Sign out the current user
   */
  async signOut() {
    try {
      const { error } = await this.supabase.auth.signOut();
      if (error) {
        throw new Error(error.message);
      }
    } catch (error) {
      console.error('Sign out error:', error);
      throw error;
    }
  }

  /**
   * Reset password - sends reset email
   */
  async resetPassword(email: string) {
    try {
      const { error } = await this.supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/auth/reset-password`,
      });

      if (error) {
        throw new Error(error.message);
      }
    } catch (error) {
      console.error('Password reset error:', error);
      throw error;
    }
  }

  /**
   * Update password
   */
  async updatePassword(newPassword: string) {
    try {
      const { error } = await this.supabase.auth.updateUser({
        password: newPassword,
      });

      if (error) {
        throw new Error(error.message);
      }
    } catch (error) {
      console.error('Password update error:', error);
      throw error;
    }
  }

  /**
   * Get current user
   */
  async getUser(): Promise<AuthUser | null> {
    try {
      const { data: { user }, error } = await this.supabase.auth.getUser();
      
      if (error || !user) {
        return null;
      }

      // Get user profile data
      const { data: profile, error: profileError } = await this.supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();

      if (profileError) {
        console.error('Profile fetch error:', profileError);
        return null;
      }

      return {
        id: user.id,
        email: user.email!,
        fullName: profile.full_name,
        role: profile.role,
        avatarUrl: profile.avatar_url,
        isVerified: profile.is_verified,
        createdAt: user.created_at,
      };
    } catch (error) {
      console.error('Get user error:', error);
      return null;
    }
  }

  /**
   * Update user profile
   */
  async updateProfile(updates: Partial<{
    fullName: string;
    avatarUrl: string;
    bio: string;
    phone: string;
    dateOfBirth: string;
    preferences: Record<string, any>;
  }>) {
    try {
      const { data: { user } } = await this.supabase.auth.getUser();
      
      if (!user) {
        throw new Error('No authenticated user');
      }

      const profileUpdates: any = {};
      
      if (updates.fullName) profileUpdates.full_name = updates.fullName;
      if (updates.avatarUrl) profileUpdates.avatar_url = updates.avatarUrl;
      if (updates.bio) profileUpdates.bio = updates.bio;
      if (updates.phone) profileUpdates.phone = updates.phone;
      if (updates.dateOfBirth) profileUpdates.date_of_birth = updates.dateOfBirth;
      if (updates.preferences) profileUpdates.preferences = updates.preferences;

      const { data, error } = await this.supabase
        .from('profiles')
        .update({
          ...profileUpdates,
          updated_at: new Date().toISOString(),
        })
        .eq('id', user.id)
        .select()
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Profile update error:', error);
      throw error;
    }
  }

  /**
   * Check if user has required role
   */
  async hasRole(requiredRole: UserRole | UserRole[]): Promise<boolean> {
    try {
      const user = await this.getUser();
      if (!user) return false;

      if (Array.isArray(requiredRole)) {
        return requiredRole.includes(user.role);
      }

      return user.role === requiredRole;
    } catch (error) {
      console.error('Role check error:', error);
      return false;
    }
  }

  /**
   * Subscribe to auth state changes
   */
  onAuthStateChange(callback: (user: AuthUser | null) => void) {
    return this.supabase.auth.onAuthStateChange(async (event, session) => {
      if (session?.user) {
        const authUser = await this.getUser();
        callback(authUser);
      } else {
        callback(null);
      }
    });
  }
}

// Server-side auth utilities
export class AuthServer {
  /**
   * Get current user on server-side
   */
  static async getUser(): Promise<AuthUser | null> {
    try {
      const supabase = await createServerClient();
      const { data: { user }, error } = await supabase.auth.getUser();
      
      if (error || !user) {
        return null;
      }

      // Get user profile data
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();

      if (profileError) {
        console.error('Profile fetch error:', profileError);
        return null;
      }

      return {
        id: user.id,
        email: user.email!,
        fullName: profile.full_name,
        role: profile.role,
        avatarUrl: profile.avatar_url,
        isVerified: profile.is_verified,
        createdAt: user.created_at,
      };
    } catch (error) {
      console.error('Server get user error:', error);
      return null;
    }
  }

  /**
   * Check if user has required role (server-side)
   */
  static async hasRole(requiredRole: UserRole | UserRole[]): Promise<boolean> {
    try {
      const user = await this.getUser();
      if (!user) return false;

      if (Array.isArray(requiredRole)) {
        return requiredRole.includes(user.role);
      }

      return user.role === requiredRole;
    } catch (error) {
      console.error('Server role check error:', error);
      return false;
    }
  }

  /**
   * Require authentication (throws if not authenticated)
   */
  static async requireAuth(): Promise<AuthUser> {
    const user = await this.getUser();
    if (!user) {
      throw new Error('Authentication required');
    }
    return user;
  }

  /**
   * Require specific role (throws if not authorized)
   */
  static async requireRole(requiredRole: UserRole | UserRole[]): Promise<AuthUser> {
    const user = await this.requireAuth();
    const hasRequiredRole = Array.isArray(requiredRole) 
      ? requiredRole.includes(user.role)
      : user.role === requiredRole;

    if (!hasRequiredRole) {
      throw new Error(`Access denied. Required role: ${Array.isArray(requiredRole) ? requiredRole.join(' or ') : requiredRole}`);
    }

    return user;
  }
}

// Export instances for convenience
export const authClient = new AuthClient();
export const authServer = AuthServer;