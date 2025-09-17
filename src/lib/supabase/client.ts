import { createBrowserClient } from '@supabase/ssr';

// Database schema types
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          email: string;
          full_name: string;
          avatar_url: string | null;
          role: 'student' | 'teacher' | 'admin';
          bio: string | null;
          date_of_birth: string | null;
          phone: string | null;
          address: Json | null;
          preferences: Json;
          is_verified: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          email: string;
          full_name: string;
          avatar_url?: string | null;
          role?: 'student' | 'teacher' | 'admin';
          bio?: string | null;
          date_of_birth?: string | null;
          phone?: string | null;
          address?: Json | null;
          preferences?: Json;
          is_verified?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          email?: string;
          full_name?: string;
          avatar_url?: string | null;
          role?: 'student' | 'teacher' | 'admin';
          bio?: string | null;
          date_of_birth?: string | null;
          phone?: string | null;
          address?: Json | null;
          preferences?: Json;
          is_verified?: boolean;
          created_at?: string;
          updated_at?: string;
        };
      };
      categories: {
        Row: {
          id: string;
          name: string;
          slug: string;
          description: string | null;
          color: string;
          icon: string | null;
          parent_id: string | null;
          sort_order: number;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          slug: string;
          description?: string | null;
          color?: string;
          icon?: string | null;
          parent_id?: string | null;
          sort_order?: number;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          name?: string;
          slug?: string;
          description?: string | null;
          color?: string;
          icon?: string | null;
          parent_id?: string | null;
          sort_order?: number;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
      };
      courses: {
        Row: {
          id: string;
          title: string;
          slug: string;
          description: string | null;
          short_description: string | null;
          thumbnail_url: string | null;
          cover_image_url: string | null;
          instructor_id: string;
          category_id: string | null;
          status: 'draft' | 'published' | 'archived';
          level: 'beginner' | 'intermediate' | 'advanced' | null;
          duration_minutes: number;
          price: number;
          is_free: boolean;
          max_students: number | null;
          prerequisites: string[] | null;
          learning_objectives: string[] | null;
          tags: string[] | null;
          language: string;
          certificate_template: string | null;
          sort_order: number;
          is_featured: boolean;
          published_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          title: string;
          slug: string;
          description?: string | null;
          short_description?: string | null;
          thumbnail_url?: string | null;
          cover_image_url?: string | null;
          instructor_id: string;
          category_id?: string | null;
          status?: 'draft' | 'published' | 'archived';
          level?: 'beginner' | 'intermediate' | 'advanced' | null;
          duration_minutes?: number;
          price?: number;
          is_free?: boolean;
          max_students?: number | null;
          prerequisites?: string[] | null;
          learning_objectives?: string[] | null;
          tags?: string[] | null;
          language?: string;
          certificate_template?: string | null;
          sort_order?: number;
          is_featured?: boolean;
          published_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          title?: string;
          slug?: string;
          description?: string | null;
          short_description?: string | null;
          thumbnail_url?: string | null;
          cover_image_url?: string | null;
          instructor_id?: string;
          category_id?: string | null;
          status?: 'draft' | 'published' | 'archived';
          level?: 'beginner' | 'intermediate' | 'advanced' | null;
          duration_minutes?: number;
          price?: number;
          is_free?: boolean;
          max_students?: number | null;
          prerequisites?: string[] | null;
          learning_objectives?: string[] | null;
          tags?: string[] | null;
          language?: string;
          certificate_template?: string | null;
          sort_order?: number;
          is_featured?: boolean;
          published_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      course_modules: {
        Row: {
          id: string;
          course_id: string;
          title: string;
          description: string | null;
          sort_order: number;
          is_required: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          course_id: string;
          title: string;
          description?: string | null;
          sort_order?: number;
          is_required?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          course_id?: string;
          title?: string;
          description?: string | null;
          sort_order?: number;
          is_required?: boolean;
          created_at?: string;
          updated_at?: string;
        };
      };
      lessons: {
        Row: {
          id: string;
          course_id: string;
          module_id: string | null;
          title: string;
          slug: string;
          description: string | null;
          content: string | null;
          type: 'video' | 'text' | 'quiz' | 'assignment' | 'interactive';
          video_url: string | null;
          video_duration: number | null;
          attachments: Json;
          quiz_data: Json | null;
          assignment_data: Json | null;
          sort_order: number;
          is_preview: boolean;
          is_required: boolean;
          estimated_minutes: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          course_id: string;
          module_id?: string | null;
          title: string;
          slug: string;
          description?: string | null;
          content?: string | null;
          type?: 'video' | 'text' | 'quiz' | 'assignment' | 'interactive';
          video_url?: string | null;
          video_duration?: number | null;
          attachments?: Json;
          quiz_data?: Json | null;
          assignment_data?: Json | null;
          sort_order?: number;
          is_preview?: boolean;
          is_required?: boolean;
          estimated_minutes?: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          course_id?: string;
          module_id?: string | null;
          title?: string;
          slug?: string;
          description?: string | null;
          content?: string | null;
          type?: 'video' | 'text' | 'quiz' | 'assignment' | 'interactive';
          video_url?: string | null;
          video_duration?: number | null;
          attachments?: Json;
          quiz_data?: Json | null;
          assignment_data?: Json | null;
          sort_order?: number;
          is_preview?: boolean;
          is_required?: boolean;
          estimated_minutes?: number;
          created_at?: string;
          updated_at?: string;
        };
      };
      enrollments: {
        Row: {
          id: string;
          student_id: string;
          course_id: string;
          status: 'active' | 'completed' | 'dropped' | 'pending';
          progress_percentage: number;
          started_at: string;
          completed_at: string | null;
          certificate_url: string | null;
          notes: string | null;
          rating: number | null;
          review: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          student_id: string;
          course_id: string;
          status?: 'active' | 'completed' | 'dropped' | 'pending';
          progress_percentage?: number;
          started_at?: string;
          completed_at?: string | null;
          certificate_url?: string | null;
          notes?: string | null;
          rating?: number | null;
          review?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          student_id?: string;
          course_id?: string;
          status?: 'active' | 'completed' | 'dropped' | 'pending';
          progress_percentage?: number;
          started_at?: string;
          completed_at?: string | null;
          certificate_url?: string | null;
          notes?: string | null;
          rating?: number | null;
          review?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      lesson_progress: {
        Row: {
          id: string;
          student_id: string;
          lesson_id: string;
          enrollment_id: string;
          is_completed: boolean;
          completion_percentage: number;
          time_spent_minutes: number;
          quiz_score: number | null;
          quiz_attempts: number;
          assignment_submitted: boolean;
          assignment_score: number | null;
          notes: string | null;
          completed_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          student_id: string;
          lesson_id: string;
          enrollment_id: string;
          is_completed?: boolean;
          completion_percentage?: number;
          time_spent_minutes?: number;
          quiz_score?: number | null;
          quiz_attempts?: number;
          assignment_submitted?: boolean;
          assignment_score?: number | null;
          notes?: string | null;
          completed_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          student_id?: string;
          lesson_id?: string;
          enrollment_id?: string;
          is_completed?: boolean;
          completion_percentage?: number;
          time_spent_minutes?: number;
          quiz_score?: number | null;
          quiz_attempts?: number;
          assignment_submitted?: boolean;
          assignment_score?: number | null;
          notes?: string | null;
          completed_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      assignments: {
        Row: {
          id: string;
          lesson_id: string;
          student_id: string;
          title: string;
          description: string | null;
          submission_text: string | null;
          submission_files: Json;
          instructor_feedback: string | null;
          grade: number | null;
          is_submitted: boolean;
          is_graded: boolean;
          submitted_at: string | null;
          graded_at: string | null;
          due_date: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          lesson_id: string;
          student_id: string;
          title: string;
          description?: string | null;
          submission_text?: string | null;
          submission_files?: Json;
          instructor_feedback?: string | null;
          grade?: number | null;
          is_submitted?: boolean;
          is_graded?: boolean;
          submitted_at?: string | null;
          graded_at?: string | null;
          due_date?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          lesson_id?: string;
          student_id?: string;
          title?: string;
          description?: string | null;
          submission_text?: string | null;
          submission_files?: Json;
          instructor_feedback?: string | null;
          grade?: number | null;
          is_submitted?: boolean;
          is_graded?: boolean;
          submitted_at?: string | null;
          graded_at?: string | null;
          due_date?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      notifications: {
        Row: {
          id: string;
          user_id: string;
          title: string;
          message: string;
          type: string;
          action_url: string | null;
          is_read: boolean;
          is_email_sent: boolean;
          metadata: Json;
          created_at: string;
          read_at: string | null;
        };
        Insert: {
          id?: string;
          user_id: string;
          title: string;
          message: string;
          type?: string;
          action_url?: string | null;
          is_read?: boolean;
          is_email_sent?: boolean;
          metadata?: Json;
          created_at?: string;
          read_at?: string | null;
        };
        Update: {
          id?: string;
          user_id?: string;
          title?: string;
          message?: string;
          type?: string;
          action_url?: string | null;
          is_read?: boolean;
          is_email_sent?: boolean;
          metadata?: Json;
          created_at?: string;
          read_at?: string | null;
        };
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      [_ in never]: never;
    };
    Enums: {
      user_role: 'student' | 'teacher' | 'admin';
      enrollment_status: 'active' | 'completed' | 'dropped' | 'pending';
      course_status: 'draft' | 'published' | 'archived';
      lesson_type: 'video' | 'text' | 'quiz' | 'assignment' | 'interactive';
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
}

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const createClient = () => {
  return createBrowserClient<Database>(supabaseUrl, supabaseAnonKey);
};

// Helper types for easier usage
export type Tables<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Row'];
export type TablesInsert<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Insert'];
export type TablesUpdate<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Update'];

// Specific table types for convenience
export type Profile = Tables<'profiles'>;
export type Category = Tables<'categories'>;
export type Course = Tables<'courses'>;
export type CourseModule = Tables<'course_modules'>;
export type Lesson = Tables<'lessons'>;
export type Enrollment = Tables<'enrollments'>;
export type LessonProgress = Tables<'lesson_progress'>;
export type Assignment = Tables<'assignments'>;
export type Notification = Tables<'notifications'>;
