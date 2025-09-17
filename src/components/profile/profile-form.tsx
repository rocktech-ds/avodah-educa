'use client';

import { useState, useEffect } from 'react';
import { Loader2, Save, User, Mail, Phone, Calendar, MapPin, Settings } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Separator } from '@/components/ui/separator';
import { useToast } from '@/hooks/use-toast';
import { AvatarUpload } from './avatar-upload';
import { profileClient } from '@/lib/profile/utils';
import type { Profile } from '@/lib/supabase/client';
import type { ProfileUpdateData } from '@/lib/profile/utils';

interface ProfileFormProps {
  profile: Profile;
  onProfileUpdate: (updatedProfile: Profile) => void;
}

interface FormData {
  fullName: string;
  email: string;
  phone: string;
  bio: string;
  dateOfBirth: string;
  avatarUrl: string;
  preferences: {
    language: string;
    timezone: string;
    emailNotifications: boolean;
    pushNotifications: boolean;
    marketingEmails: boolean;
    theme: 'light' | 'dark' | 'system';
  };
  address: {
    street: string;
    city: string;
    state: string;
    country: string;
    zipCode: string;
  };
}

const TIMEZONES = [
  'America/Sao_Paulo',
  'America/New_York',
  'Europe/London',
  'Europe/Berlin',
  'Asia/Tokyo',
  'Asia/Shanghai',
  'Australia/Sydney',
];

const COUNTRIES = [
  'Brasil',
  'Estados Unidos',
  'Canadá',
  'Reino Unido',
  'Alemanha',
  'França',
  'Espanha',
  'Portugal',
  'Argentina',
  'México',
];

export function ProfileForm({ profile, onProfileUpdate }: ProfileFormProps) {
  const { toast } = useToast();
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState<FormData>({
    fullName: profile.full_name || '',
    email: profile.email || '',
    phone: profile.phone || '',
    bio: profile.bio || '',
    dateOfBirth: profile.date_of_birth || '',
    avatarUrl: profile.avatar_url || '',
    preferences: {
      language: (profile.preferences as any)?.language || 'pt',
      timezone: (profile.preferences as any)?.timezone || 'America/Sao_Paulo',
      emailNotifications: (profile.preferences as any)?.emailNotifications ?? true,
      pushNotifications: (profile.preferences as any)?.pushNotifications ?? true,
      marketingEmails: (profile.preferences as any)?.marketingEmails ?? false,
      theme: (profile.preferences as any)?.theme || 'system',
    },
    address: {
      street: (profile.address as any)?.street || '',
      city: (profile.address as any)?.city || '',
      state: (profile.address as any)?.state || '',
      country: (profile.address as any)?.country || 'Brasil',
      zipCode: (profile.address as any)?.zipCode || '',
    }
  });

  const handleInputChange = (field: string, value: any) => {
    if (field.includes('.')) {
      const [parent, child] = field.split('.');
      setFormData(prev => ({
        ...prev,
        [parent]: {
          ...(prev[parent as keyof FormData] as any),
          [child]: value
        }
      }));
    } else {
      setFormData(prev => ({
        ...prev,
        [field]: value
      }));
    }
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setIsLoading(true);

    try {
      const updates: ProfileUpdateData = {
        fullName: formData.fullName,
        bio: formData.bio,
        phone: formData.phone,
        dateOfBirth: formData.dateOfBirth || undefined,
        avatarUrl: formData.avatarUrl,
        preferences: formData.preferences,
        address: formData.address,
      };

      const updatedProfile = await profileClient.updateProfile(updates);
      onProfileUpdate(updatedProfile);

      toast({
        title: 'Perfil atualizado!',
        description: 'Suas informações foram salvas com sucesso.',
        variant: 'default',
      });
    } catch (error) {
      console.error('Profile update error:', error);
      toast({
        title: 'Erro ao atualizar',
        description: 'Não foi possível salvar as alterações. Tente novamente.',
        variant: 'destructive',
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-8">
      {/* Avatar Section */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <User className="w-5 h-5 mr-2" />
            Foto do Perfil
          </CardTitle>
          <CardDescription>
            Atualize sua foto de perfil para personalizar sua conta
          </CardDescription>
        </CardHeader>
        <CardContent>
          <AvatarUpload
            currentAvatarUrl={formData.avatarUrl}
            userFullName={formData.fullName}
            onAvatarChange={(newAvatarUrl) => handleInputChange('avatarUrl', newAvatarUrl)}
            disabled={isLoading}
          />
        </CardContent>
      </Card>

      {/* Personal Information */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <User className="w-5 h-5 mr-2" />
            Informações Pessoais
          </CardTitle>
          <CardDescription>
            Mantenha suas informações pessoais atualizadas
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="fullName">Nome Completo</Label>
              <Input
                id="fullName"
                value={formData.fullName}
                onChange={(e) => handleInputChange('fullName', e.target.value)}
                disabled={isLoading}
                required
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                value={formData.email}
                disabled={true}
                className="bg-gray-50"
              />
              <p className="text-xs text-gray-500">
                Email não pode ser alterado
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="phone">Telefone</Label>
              <Input
                id="phone"
                type="tel"
                value={formData.phone}
                onChange={(e) => handleInputChange('phone', e.target.value)}
                disabled={isLoading}
                placeholder="(00) 00000-0000"
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="dateOfBirth">Data de Nascimento</Label>
              <Input
                id="dateOfBirth"
                type="date"
                value={formData.dateOfBirth}
                onChange={(e) => handleInputChange('dateOfBirth', e.target.value)}
                disabled={isLoading}
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="bio">Biografia</Label>
            <Textarea
              id="bio"
              value={formData.bio}
              onChange={(e) => handleInputChange('bio', e.target.value)}
              disabled={isLoading}
              placeholder="Conte um pouco sobre você..."
              rows={4}
            />
          </div>
        </CardContent>
      </Card>

      {/* Address Information */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <MapPin className="w-5 h-5 mr-2" />
            Endereço
          </CardTitle>
          <CardDescription>
            Informações de localização (opcional)
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="street">Rua/Endereço</Label>
            <Input
              id="street"
              value={formData.address.street}
              onChange={(e) => handleInputChange('address.street', e.target.value)}
              disabled={isLoading}
              placeholder="Rua, número, bairro"
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-2">
              <Label htmlFor="city">Cidade</Label>
              <Input
                id="city"
                value={formData.address.city}
                onChange={(e) => handleInputChange('address.city', e.target.value)}
                disabled={isLoading}
                placeholder="Cidade"
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="state">Estado</Label>
              <Input
                id="state"
                value={formData.address.state}
                onChange={(e) => handleInputChange('address.state', e.target.value)}
                disabled={isLoading}
                placeholder="Estado/Província"
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="zipCode">CEP</Label>
              <Input
                id="zipCode"
                value={formData.address.zipCode}
                onChange={(e) => handleInputChange('address.zipCode', e.target.value)}
                disabled={isLoading}
                placeholder="00000-000"
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="country">País</Label>
            <Select 
              value={formData.address.country} 
              onValueChange={(value) => handleInputChange('address.country', value)}
              disabled={isLoading}
            >
              <SelectTrigger>
                <SelectValue placeholder="Selecione o país" />
              </SelectTrigger>
              <SelectContent>
                {COUNTRIES.map((country) => (
                  <SelectItem key={country} value={country}>
                    {country}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Preferences */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Settings className="w-5 h-5 mr-2" />
            Preferências
          </CardTitle>
          <CardDescription>
            Configure suas preferências de conta e notificações
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="language">Idioma</Label>
              <Select 
                value={formData.preferences.language} 
                onValueChange={(value) => handleInputChange('preferences.language', value)}
                disabled={isLoading}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Selecione o idioma" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pt">Português</SelectItem>
                  <SelectItem value="en">English</SelectItem>
                  <SelectItem value="es">Español</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="timezone">Fuso Horário</Label>
              <Select 
                value={formData.preferences.timezone} 
                onValueChange={(value) => handleInputChange('preferences.timezone', value)}
                disabled={isLoading}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Selecione o fuso horário" />
                </SelectTrigger>
                <SelectContent>
                  {TIMEZONES.map((tz) => (
                    <SelectItem key={tz} value={tz}>
                      {tz.replace('_', ' ')}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="theme">Tema</Label>
            <Select 
              value={formData.preferences.theme} 
              onValueChange={(value) => handleInputChange('preferences.theme', value)}
              disabled={isLoading}
            >
              <SelectTrigger>
                <SelectValue placeholder="Selecione o tema" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="system">Sistema</SelectItem>
                <SelectItem value="light">Claro</SelectItem>
                <SelectItem value="dark">Escuro</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <Separator />

          <div className="space-y-4">
            <h4 className="text-sm font-medium">Notificações</h4>
            
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label htmlFor="emailNotifications">Notificações por Email</Label>
                  <p className="text-xs text-gray-500">
                    Receba atualizações importantes por email
                  </p>
                </div>
                <Switch
                  id="emailNotifications"
                  checked={formData.preferences.emailNotifications}
                  onCheckedChange={(checked) => handleInputChange('preferences.emailNotifications', checked)}
                  disabled={isLoading}
                />
              </div>
              
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label htmlFor="pushNotifications">Notificações Push</Label>
                  <p className="text-xs text-gray-500">
                    Receba notificações em tempo real
                  </p>
                </div>
                <Switch
                  id="pushNotifications"
                  checked={formData.preferences.pushNotifications}
                  onCheckedChange={(checked) => handleInputChange('preferences.pushNotifications', checked)}
                  disabled={isLoading}
                />
              </div>
              
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label htmlFor="marketingEmails">Emails de Marketing</Label>
                  <p className="text-xs text-gray-500">
                    Receba dicas e promoções exclusivas
                  </p>
                </div>
                <Switch
                  id="marketingEmails"
                  checked={formData.preferences.marketingEmails}
                  onCheckedChange={(checked) => handleInputChange('preferences.marketingEmails', checked)}
                  disabled={isLoading}
                />
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Save Button */}
      <div className="flex justify-end">
        <Button type="submit" disabled={isLoading}>
          {isLoading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Salvando...
            </>
          ) : (
            <>
              <Save className="mr-2 h-4 w-4" />
              Salvar Alterações
            </>
          )}
        </Button>
      </div>
    </form>
  );
}