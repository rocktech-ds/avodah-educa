'use client';

import { useState, useRef, useCallback } from 'react';
import { Camera, Upload, X, Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { useToast } from '@/hooks/use-toast';
import { profileClient } from '@/lib/profile/utils';

interface AvatarUploadProps {
  currentAvatarUrl?: string;
  userFullName: string;
  onAvatarChange: (newAvatarUrl: string) => void;
  disabled?: boolean;
}

export function AvatarUpload({ 
  currentAvatarUrl, 
  userFullName, 
  onAvatarChange,
  disabled = false 
}: AvatarUploadProps) {
  const { toast } = useToast();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

  const handleFileSelect = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // Validate file type
    if (!file.type.startsWith('image/')) {
      toast({
        title: 'Erro',
        description: 'Por favor, selecione apenas arquivos de imagem.',
        variant: 'destructive',
      });
      return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      toast({
        title: 'Erro',
        description: 'O arquivo deve ter no máximo 5MB.',
        variant: 'destructive',
      });
      return;
    }

    // Create preview
    const reader = new FileReader();
    reader.onload = (e) => {
      setPreviewUrl(e.target?.result as string);
    };
    reader.readAsDataURL(file);

    // Upload file
    handleUpload(file);
  }, [toast]);

  const handleUpload = async (file: File) => {
    setIsUploading(true);
    try {
      // Delete old avatar if exists
      if (currentAvatarUrl) {
        await profileClient.deleteAvatar(currentAvatarUrl);
      }

      // Upload new avatar
      const newAvatarUrl = await profileClient.uploadAvatar(file);
      
      onAvatarChange(newAvatarUrl);
      setPreviewUrl(null);

      toast({
        title: 'Sucesso!',
        description: 'Avatar atualizado com sucesso.',
        variant: 'default',
      });
    } catch (error) {
      console.error('Upload error:', error);
      toast({
        title: 'Erro no upload',
        description: 'Não foi possível fazer upload da imagem. Tente novamente.',
        variant: 'destructive',
      });
      setPreviewUrl(null);
    } finally {
      setIsUploading(false);
      // Reset input
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const handleRemoveAvatar = async () => {
    if (!currentAvatarUrl) return;
    
    setIsUploading(true);
    try {
      await profileClient.deleteAvatar(currentAvatarUrl);
      onAvatarChange('');
      
      toast({
        title: 'Avatar removido',
        description: 'Seu avatar foi removido com sucesso.',
        variant: 'default',
      });
    } catch (error) {
      console.error('Remove avatar error:', error);
      toast({
        title: 'Erro',
        description: 'Não foi possível remover o avatar.',
        variant: 'destructive',
      });
    } finally {
      setIsUploading(false);
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

  const displayUrl = previewUrl || currentAvatarUrl;

  return (
    <div className="flex flex-col items-center space-y-4">
      <div className="relative">
        <Avatar className="w-32 h-32">
          {displayUrl ? (
            <AvatarImage src={displayUrl} alt={userFullName} />
          ) : (
            <AvatarFallback className="text-2xl">
              {getInitials(userFullName)}
            </AvatarFallback>
          )}
        </Avatar>
        
        {isUploading && (
          <div className="absolute inset-0 flex items-center justify-center bg-black/50 rounded-full">
            <Loader2 className="w-8 h-8 text-white animate-spin" />
          </div>
        )}
        
        {!disabled && (
          <Button
            size="sm"
            variant="outline"
            className="absolute -bottom-2 -right-2 rounded-full w-10 h-10 p-0"
            onClick={() => fileInputRef.current?.click()}
            disabled={isUploading}
          >
            <Camera className="w-4 h-4" />
          </Button>
        )}
      </div>

      {!disabled && (
        <div className="flex flex-col items-center space-y-2">
          <div className="flex space-x-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => fileInputRef.current?.click()}
              disabled={isUploading}
            >
              <Upload className="w-4 h-4 mr-2" />
              {isUploading ? 'Uploading...' : 'Alterar foto'}
            </Button>
            
            {currentAvatarUrl && (
              <Button
                variant="outline"
                size="sm"
                onClick={handleRemoveAvatar}
                disabled={isUploading}
              >
                <X className="w-4 h-4 mr-2" />
                Remover
              </Button>
            )}
          </div>
          
          <p className="text-xs text-gray-500 text-center">
            PNG, JPG até 5MB
          </p>
        </div>
      )}

      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        onChange={handleFileSelect}
        className="hidden"
        disabled={disabled || isUploading}
      />
    </div>
  );
}