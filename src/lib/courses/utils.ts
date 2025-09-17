import { createClient } from '@/lib/supabase/client';
import { createClient as createServerClient } from '@/lib/supabase/server';
import type { 
  Course, 
  Category, 
  CourseModule, 
  Lesson, 
  Enrollment,
  LessonProgress,
  TablesInsert,
  TablesUpdate 
} from '@/lib/supabase/client';

// Course data types for forms
export interface CourseCreateData {
  title: string;
  slug: string;
  description?: string;
  shortDescription?: string;
  thumbnailUrl?: string;
  coverImageUrl?: string;
  categoryId?: string;
  level?: 'beginner' | 'intermediate' | 'advanced';
  price?: number;
  isFree?: boolean;
  maxStudents?: number;
  prerequisites?: string[];
  learningObjectives?: string[];
  tags?: string[];
  language?: string;
  isFeatured?: boolean;
}

export interface LessonCreateData {
  title: string;
  slug: string;
  description?: string;
  content?: string;
  type?: 'video' | 'text' | 'quiz' | 'assignment' | 'interactive';
  videoUrl?: string;
  videoDuration?: number;
  attachments?: any[];
  quizData?: any;
  assignmentData?: any;
  isPreview?: boolean;
  isRequired?: boolean;
  estimatedMinutes?: number;
}

// Client-side course utilities
export class CourseClient {
  private supabase = createClient();

  /**
   * Get all published courses with filtering and pagination
   */
  async getCourses(options: {
    page?: number;
    limit?: number;
    category?: string;
    level?: string;
    search?: string;
    featured?: boolean;
  } = {}): Promise<{ courses: Course[], total: number }> {
    try {
      const { page = 1, limit = 12, category, level, search, featured } = options;

      let query = this.supabase
        .from('courses')
        .select(`
          *,
          categories (
            id,
            name,
            slug,
            color
          ),
          profiles!courses_instructor_id_fkey (
            id,
            full_name,
            avatar_url
          )
        `, { count: 'exact' })
        .eq('status', 'published')
        .order('created_at', { ascending: false });

      if (category) {
        query = query.eq('category_id', category);
      }

      if (level) {
        query = query.eq('level', level);
      }

      if (search) {
        query = query.or(`title.ilike.%${search}%, description.ilike.%${search}%, tags.cs.{${search}}`);
      }

      if (featured) {
        query = query.eq('is_featured', true);
      }

      const { data, error, count } = await query
        .range((page - 1) * limit, page * limit - 1);

      if (error) {
        throw new Error(error.message);
      }

      return {
        courses: data || [],
        total: count || 0
      };
    } catch (error) {
      console.error('Get courses error:', error);
      throw error;
    }
  }

  /**
   * Get course by ID with full details
   */
  async getCourseById(courseId: string): Promise<Course | null> {
    try {
      const { data, error } = await this.supabase
        .from('courses')
        .select(`
          *,
          categories (
            id,
            name,
            slug,
            color
          ),
          profiles!courses_instructor_id_fkey (
            id,
            full_name,
            avatar_url,
            bio
          ),
          course_modules (
            id,
            title,
            description,
            sort_order,
            is_required,
            lessons (
              id,
              title,
              slug,
              description,
              type,
              sort_order,
              is_preview,
              is_required,
              estimated_minutes
            )
          )
        `)
        .eq('id', courseId)
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Get course by ID error:', error);
      return null;
    }
  }

  /**
   * Get course by slug
   */
  async getCourseBySlug(slug: string): Promise<Course | null> {
    try {
      const { data, error } = await this.supabase
        .from('courses')
        .select(`
          *,
          categories (
            id,
            name,
            slug,
            color
          ),
          profiles!courses_instructor_id_fkey (
            id,
            full_name,
            avatar_url,
            bio
          )
        `)
        .eq('slug', slug)
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Get course by slug error:', error);
      return null;
    }
  }

  /**
   * Create new course (teacher/admin only)
   */
  async createCourse(courseData: CourseCreateData): Promise<Course> {
    try {
      const { data: { user } } = await this.supabase.auth.getUser();
      
      if (!user) {
        throw new Error('User not authenticated');
      }

      const courseInsert: TablesInsert<'courses'> = {
        title: courseData.title,
        slug: courseData.slug,
        description: courseData.description,
        short_description: courseData.shortDescription,
        thumbnail_url: courseData.thumbnailUrl,
        cover_image_url: courseData.coverImageUrl,
        instructor_id: user.id,
        category_id: courseData.categoryId,
        level: courseData.level,
        price: courseData.price || 0,
        is_free: courseData.isFree ?? true,
        max_students: courseData.maxStudents,
        prerequisites: courseData.prerequisites,
        learning_objectives: courseData.learningObjectives,
        tags: courseData.tags,
        language: courseData.language || 'pt',
        is_featured: courseData.isFeatured || false,
        status: 'draft'
      };

      const { data, error } = await this.supabase
        .from('courses')
        .insert(courseInsert)
        .select()
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Create course error:', error);
      throw error;
    }
  }

  /**
   * Update course (instructor/admin only)
   */
  async updateCourse(courseId: string, updates: Partial<CourseCreateData>): Promise<Course> {
    try {
      const courseUpdate: TablesUpdate<'courses'> = {};

      if (updates.title) courseUpdate.title = updates.title;
      if (updates.slug) courseUpdate.slug = updates.slug;
      if (updates.description !== undefined) courseUpdate.description = updates.description;
      if (updates.shortDescription !== undefined) courseUpdate.short_description = updates.shortDescription;
      if (updates.thumbnailUrl !== undefined) courseUpdate.thumbnail_url = updates.thumbnailUrl;
      if (updates.coverImageUrl !== undefined) courseUpdate.cover_image_url = updates.coverImageUrl;
      if (updates.categoryId !== undefined) courseUpdate.category_id = updates.categoryId;
      if (updates.level !== undefined) courseUpdate.level = updates.level;
      if (updates.price !== undefined) courseUpdate.price = updates.price;
      if (updates.isFree !== undefined) courseUpdate.is_free = updates.isFree;
      if (updates.maxStudents !== undefined) courseUpdate.max_students = updates.maxStudents;
      if (updates.prerequisites !== undefined) courseUpdate.prerequisites = updates.prerequisites;
      if (updates.learningObjectives !== undefined) courseUpdate.learning_objectives = updates.learningObjectives;
      if (updates.tags !== undefined) courseUpdate.tags = updates.tags;
      if (updates.language !== undefined) courseUpdate.language = updates.language;
      if (updates.isFeatured !== undefined) courseUpdate.is_featured = updates.isFeatured;

      const { data, error } = await this.supabase
        .from('courses')
        .update(courseUpdate)
        .eq('id', courseId)
        .select()
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Update course error:', error);
      throw error;
    }
  }

  /**
   * Publish course
   */
  async publishCourse(courseId: string): Promise<Course> {
    try {
      const { data, error } = await this.supabase
        .from('courses')
        .update({
          status: 'published',
          published_at: new Date().toISOString()
        })
        .eq('id', courseId)
        .select()
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Publish course error:', error);
      throw error;
    }
  }

  /**
   * Delete course
   */
  async deleteCourse(courseId: string): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('courses')
        .delete()
        .eq('id', courseId);

      if (error) {
        throw new Error(error.message);
      }
    } catch (error) {
      console.error('Delete course error:', error);
      throw error;
    }
  }

  /**
   * Enroll in course
   */
  async enrollInCourse(courseId: string): Promise<Enrollment> {
    try {
      const { data: { user } } = await this.supabase.auth.getUser();
      
      if (!user) {
        throw new Error('User not authenticated');
      }

      const { data, error } = await this.supabase
        .from('enrollments')
        .insert({
          student_id: user.id,
          course_id: courseId,
          status: 'active'
        })
        .select()
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Enroll in course error:', error);
      throw error;
    }
  }

  /**
   * Get user enrollments
   */
  async getUserEnrollments(): Promise<Enrollment[]> {
    try {
      const { data: { user } } = await this.supabase.auth.getUser();
      
      if (!user) {
        throw new Error('User not authenticated');
      }

      const { data, error } = await this.supabase
        .from('enrollments')
        .select(`
          *,
          courses (
            id,
            title,
            slug,
            thumbnail_url,
            level,
            duration_minutes
          )
        `)
        .eq('student_id', user.id)
        .order('created_at', { ascending: false });

      if (error) {
        throw new Error(error.message);
      }

      return data || [];
    } catch (error) {
      console.error('Get user enrollments error:', error);
      throw error;
    }
  }

  /**
   * Get all categories
   */
  async getCategories(): Promise<Category[]> {
    try {
      const { data, error } = await this.supabase
        .from('categories')
        .select('*')
        .eq('is_active', true)
        .order('sort_order', { ascending: true });

      if (error) {
        throw new Error(error.message);
      }

      return data || [];
    } catch (error) {
      console.error('Get categories error:', error);
      throw error;
    }
  }

  /**
   * Create lesson in course
   */
  async createLesson(courseId: string, moduleId: string | null, lessonData: LessonCreateData): Promise<Lesson> {
    try {
      const lessonInsert: TablesInsert<'lessons'> = {
        course_id: courseId,
        module_id: moduleId,
        title: lessonData.title,
        slug: lessonData.slug,
        description: lessonData.description,
        content: lessonData.content,
        type: lessonData.type || 'text',
        video_url: lessonData.videoUrl,
        video_duration: lessonData.videoDuration,
        attachments: lessonData.attachments || [],
        quiz_data: lessonData.quizData,
        assignment_data: lessonData.assignmentData,
        is_preview: lessonData.isPreview || false,
        is_required: lessonData.isRequired ?? true,
        estimated_minutes: lessonData.estimatedMinutes || 15,
        sort_order: 0
      };

      const { data, error } = await this.supabase
        .from('lessons')
        .insert(lessonInsert)
        .select()
        .single();

      if (error) {
        throw new Error(error.message);
      }

      return data;
    } catch (error) {
      console.error('Create lesson error:', error);
      throw error;
    }
  }
}

// Server-side course utilities
export class CourseServer {
  /**
   * Get instructor courses (server-side)
   */
  static async getInstructorCourses(instructorId: string): Promise<Course[]> {
    try {
      const supabase = await createServerClient();
      
      const { data, error } = await supabase
        .from('courses')
        .select(`
          *,
          categories (
            id,
            name,
            slug
          )
        `)
        .eq('instructor_id', instructorId)
        .order('created_at', { ascending: false });

      if (error) {
        throw new Error(error.message);
      }

      return data || [];
    } catch (error) {
      console.error('Get instructor courses error:', error);
      throw error;
    }
  }

  /**
   * Get course statistics
   */
  static async getCourseStats(courseId: string): Promise<{
    totalStudents: number;
    completionRate: number;
    averageRating: number;
  }> {
    try {
      const supabase = await createServerClient();
      
      const { data: enrollments, error } = await supabase
        .from('enrollments')
        .select('status, rating')
        .eq('course_id', courseId);

      if (error) {
        throw new Error(error.message);
      }

      const totalStudents = enrollments?.length || 0;
      const completed = enrollments?.filter(e => e.status === 'completed').length || 0;
      const ratings = enrollments?.filter(e => e.rating).map(e => e.rating) || [];
      
      const completionRate = totalStudents > 0 ? (completed / totalStudents) * 100 : 0;
      const averageRating = ratings.length > 0 
        ? ratings.reduce((sum, rating) => sum + (rating || 0), 0) / ratings.length 
        : 0;

      return {
        totalStudents,
        completionRate,
        averageRating
      };
    } catch (error) {
      console.error('Get course stats error:', error);
      throw error;
    }
  }
}

// Export instances for convenience
export const courseClient = new CourseClient();
export const courseServer = CourseServer;