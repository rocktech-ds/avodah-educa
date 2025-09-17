"use client";

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { 
  Home, 
  VideoIcon as Video, 
  Calendar, 
  MessageCircle, 
  Settings,
  Users,
  BookOpen,
  BarChart,
  FolderOpen
} from 'lucide-react';

interface SidebarProps {
  user?: {
    name: string;
    role: string;
    avatar?: string;
  };
  variant?: 'student' | 'teacher' | 'admin';
  className?: string;
}

const navigationItems = {
  student: [
    { icon: Home, label: 'Início', href: '/dashboard/student' },
    { icon: Video, label: 'Meus Cursos', href: '/dashboard/student/courses' },
    { icon: Calendar, label: 'Calendário', href: '/dashboard/student/calendar' },
    { icon: MessageCircle, label: 'Mensagens', href: '/dashboard/student/messages' },
  ],
  teacher: [
    { icon: Home, label: 'Início', href: '/dashboard/teacher' },
    { icon: BookOpen, label: 'Meus Cursos', href: '/dashboard/teacher/courses' },
    { icon: Users, label: 'Alunos', href: '/dashboard/teacher/students' },
    { icon: Calendar, label: 'Calendário', href: '/dashboard/teacher/calendar' },
    { icon: MessageCircle, label: 'Mensagens', href: '/dashboard/teacher/messages' },
  ],
  admin: [
    { icon: Home, label: 'Início', href: '/dashboard/admin' },
    { icon: Users, label: 'Usuários', href: '/dashboard/admin/users' },
    { icon: BookOpen, label: 'Cursos', href: '/dashboard/admin/courses' },
    { icon: BarChart, label: 'Relatórios', href: '/dashboard/admin/reports' },
    { icon: FolderOpen, label: 'Categorias', href: '/dashboard/admin/categories' },
  ],
};

export function Sidebar({ user, variant = 'student', className }: SidebarProps) {
  const pathname = usePathname();
  const items = navigationItems[variant];

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map(word => word[0])
      .join('')
      .substring(0, 2)
      .toUpperCase();
  };

  return (
    <aside className={cn(
      "w-80 flex-shrink-0 bg-white shadow-sm p-6 border-r border-gray-100",
      className
    )}>
      <div className="flex flex-col h-full">
        {/* User Profile Section */}
        {user && (
          <div className="flex items-center gap-3 mb-8">
            <Avatar className="h-12 w-12">
              <AvatarImage src={user.avatar} alt={user.name} />
              <AvatarFallback className="bg-platform-100 text-platform-600 font-semibold">
                {getInitials(user.name)}
              </AvatarFallback>
            </Avatar>
            <div>
              <h1 className="text-gray-900 text-base font-bold leading-normal">
                {user.name}
              </h1>
              <p className="text-sm text-gray-500 capitalize">{user.role}</p>
            </div>
          </div>
        )}

        {/* Navigation */}
        <nav className="flex flex-col gap-2">
          {items.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href || 
              (item.href !== '/dashboard' && pathname.startsWith(item.href));

            return (
              <Button
                key={item.href}
                asChild
                variant="ghost"
                className={cn(
                  "flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 justify-start h-auto",
                  isActive && "bg-platform-500 text-white hover:bg-platform-600"
                )}
              >
                <Link href={item.href}>
                  <Icon className="h-5 w-5" />
                  <span className="text-sm font-medium">{item.label}</span>
                </Link>
              </Button>
            );
          })}
        </nav>

        {/* Settings at bottom */}
        <div className="mt-auto">
          <Button
            asChild
            variant="ghost"
            className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 justify-start h-auto w-full"
          >
            <Link href={`/dashboard/${variant}/settings`}>
              <Settings className="h-5 w-5" />
              <span className="text-sm font-medium">Configurações</span>
            </Link>
          </Button>
        </div>
      </div>
    </aside>
  );
}
