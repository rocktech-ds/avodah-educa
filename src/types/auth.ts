export type UserRole = 'student' | 'teacher' | 'admin';

export interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  role: UserRole;
  createdAt: Date;
  updatedAt: Date;
}

export interface Student extends User {
  role: 'student';
  studentId: string;
  enrolledCourses: Course[];
  completedCourses: Course[];
  progress: CourseProgress[];
}

export interface Teacher extends User {
  role: 'teacher';
  teacherId: string;
  bio?: string;
  specializations: string[];
  coursesTeaching: Course[];
  rating: number;
}

export interface Admin extends User {
  role: 'admin';
  adminId: string;
  permissions: Permission[];
  managedInstitutions: string[];
}

export interface Course {
  id: string;
  title: string;
  description: string;
  thumbnail: string;
  category: string;
  level: 'beginner' | 'intermediate' | 'advanced';
  duration: number; // in hours
  teacherId: string;
  teacher: Teacher;
  enrolledStudents: number;
  rating: number;
  price: number;
  tags: string[];
  createdAt: Date;
  updatedAt: Date;
}

export interface CourseProgress {
  courseId: string;
  studentId: string;
  progress: number; // 0-100
  completedLessons: string[];
  startedAt: Date;
  lastAccessedAt: Date;
  completedAt?: Date;
}

export interface Permission {
  resource: string;
  actions: string[];
}

export interface AuthState {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  name: string;
  email: string;
  password: string;
  role: UserRole;
}

export interface AuthResponse {
  user: User;
  token: string;
}