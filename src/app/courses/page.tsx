import { Suspense } from 'react';
import { CoursesPage as CoursesPageComponent } from '@/components/courses/courses-page';

export default function CoursesPage() {
  return (
    <div className="container mx-auto py-8 px-4">
      <div className="space-y-8">
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold text-gray-900">
            Explore Nossos Cursos
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Descubra uma ampla variedade de cursos para desenvolver suas habilidades 
            e alcançar seus objetivos profissionais.
          </p>
        </div>

        <Suspense fallback={
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="animate-pulse">
                <div className="bg-gray-200 aspect-video rounded-lg mb-4"></div>
                <div className="space-y-2">
                  <div className="h-4 bg-gray-200 rounded w-3/4"></div>
                  <div className="h-4 bg-gray-200 rounded w-1/2"></div>
                </div>
              </div>
            ))}
          </div>
        }>
          <CoursesPageComponent />
        </Suspense>
      </div>
    </div>
  );
}