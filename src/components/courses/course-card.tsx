'use client';

import Link from 'next/link';
import { Clock, Users, Star, BookOpen, Play } from 'lucide-react';
import { Card, CardContent, CardFooter } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import type { Course } from '@/lib/supabase/client';

interface CourseCardProps {
  course: Course & {
    categories?: {
      id: string;
      name: string;
      slug: string;
      color: string;
    };
    profiles?: {
      id: string;
      full_name: string;
      avatar_url: string | null;
    };
  };
  showInstructor?: boolean;
  showEnrollButton?: boolean;
  onEnroll?: (courseId: string) => void;
  isEnrolled?: boolean;
}

export function CourseCard({ 
  course, 
  showInstructor = true, 
  showEnrollButton = true,
  onEnroll,
  isEnrolled = false
}: CourseCardProps) {
  const formatDuration = (minutes: number) => {
    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return `${hours}h ${remainingMinutes}min`;
    }
    return `${minutes}min`;
  };

  const getLevelColor = (level: string | null) => {
    switch (level) {
      case 'beginner':
        return 'bg-green-100 text-green-800';
      case 'intermediate':
        return 'bg-yellow-100 text-yellow-800';
      case 'advanced':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getLevelText = (level: string | null) => {
    switch (level) {
      case 'beginner':
        return 'Iniciante';
      case 'intermediate':
        return 'Intermediário';
      case 'advanced':
        return 'Avançado';
      default:
        return 'Todos os níveis';
    }
  };

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .substring(0, 2)
      .toUpperCase();
  };

  return (
    <Card className="group hover:shadow-lg transition-shadow duration-300 overflow-hidden">
      <div className="aspect-video relative overflow-hidden">
        {course.thumbnail_url ? (
          <img
            src={course.thumbnail_url}
            alt={course.title}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full bg-gradient-to-br from-platform/20 to-platform/10 flex items-center justify-center">
            <BookOpen className="w-12 h-12 text-platform/50" />
          </div>
        )}
        
        {course.is_featured && (
          <div className="absolute top-3 left-3">
            <Badge className="bg-yellow-500 text-white">
              <Star className="w-3 h-3 mr-1" />
              Destaque
            </Badge>
          </div>
        )}
        
        {isEnrolled && (
          <div className="absolute top-3 right-3">
            <Badge variant="outline" className="bg-white/90 text-green-700 border-green-300">
              Inscrito
            </Badge>
          </div>
        )}
      </div>

      <CardContent className="p-4">
        <div className="space-y-3">
          {/* Category and Level */}
          <div className="flex items-center justify-between">
            {course.categories && (
              <Badge 
                variant="outline" 
                style={{ 
                  borderColor: course.categories.color,
                  color: course.categories.color
                }}
              >
                {course.categories.name}
              </Badge>
            )}
            
            <Badge 
              variant="outline" 
              className={getLevelColor(course.level)}
            >
              {getLevelText(course.level)}
            </Badge>
          </div>

          {/* Title */}
          <div>
            <Link 
              href={`/courses/${course.slug}`}
              className="group-hover:text-platform transition-colors"
            >
              <h3 className="font-semibold text-lg line-clamp-2 leading-tight">
                {course.title}
              </h3>
            </Link>
          </div>

          {/* Description */}
          {course.short_description && (
            <p className="text-gray-600 text-sm line-clamp-2">
              {course.short_description}
            </p>
          )}

          {/* Instructor */}
          {showInstructor && course.profiles && (
            <div className="flex items-center space-x-2">
              <Avatar className="w-6 h-6">
                {course.profiles.avatar_url ? (
                  <AvatarImage src={course.profiles.avatar_url} alt={course.profiles.full_name} />
                ) : (
                  <AvatarFallback className="text-xs">
                    {getInitials(course.profiles.full_name)}
                  </AvatarFallback>
                )}
              </Avatar>
              <span className="text-sm text-gray-600">
                {course.profiles.full_name}
              </span>
            </div>
          )}

          {/* Course Stats */}
          <div className="flex items-center space-x-4 text-sm text-gray-500">
            <div className="flex items-center space-x-1">
              <Clock className="w-4 h-4" />
              <span>{formatDuration(course.duration_minutes)}</span>
            </div>
            
            {course.level && (
              <div className="flex items-center space-x-1">
                <BookOpen className="w-4 h-4" />
                <span>Curso {getLevelText(course.level)}</span>
              </div>
            )}
          </div>

          {/* Tags */}
          {course.tags && course.tags.length > 0 && (
            <div className="flex flex-wrap gap-1">
              {course.tags.slice(0, 3).map((tag, index) => (
                <Badge key={index} variant="outline" className="text-xs">
                  {tag}
                </Badge>
              ))}
              {course.tags.length > 3 && (
                <Badge variant="outline" className="text-xs">
                  +{course.tags.length - 3}
                </Badge>
              )}
            </div>
          )}
        </div>
      </CardContent>

      <CardFooter className="p-4 pt-0">
        <div className="flex items-center justify-between w-full">
          {/* Price */}
          <div className="flex items-center space-x-2">
            {course.is_free ? (
              <span className="text-lg font-bold text-green-600">Gratuito</span>
            ) : (
              <div className="flex items-center space-x-1">
                <span className="text-lg font-bold text-gray-900">
                  R$ {course.price.toFixed(2)}
                </span>
              </div>
            )}
          </div>

          {/* Action Button */}
          {showEnrollButton && (
            <div className="flex space-x-2">
              {isEnrolled ? (
                <Link href={`/courses/${course.slug}`}>
                  <Button variant="outline" size="sm">
                    <Play className="w-4 h-4 mr-1" />
                    Continuar
                  </Button>
                </Link>
              ) : (
                <Button 
                  size="sm"
                  onClick={() => onEnroll?.(course.id)}
                  disabled={!onEnroll}
                >
                  {course.is_free ? 'Inscrever-se' : 'Comprar'}
                </Button>
              )}
            </div>
          )}
        </div>
      </CardFooter>
    </Card>
  );
}