'use client';

import useSWR from 'swr';
import pb from '@/lib/pocketbase';

export interface TeamMember {
  id: string;
  name: string;
  role: string;
  bio: string;
  photo: string;
  email: string;
  phone: string;
  order: number;
  active: boolean;
  created: string;
  updated: string;
}

// Custom hook for team members
export function useTeamMembers() {
  const { data, error, isLoading } = useSWR('team-members', async () => {
    return await pb.collection('team_members').getFullList({
      sort: 'order,name',
      filter: 'active = true',
    });
  });

  return {
    teamMembers: (data as unknown as TeamMember[]) || [],
    isLoading,
    error,
  };
}

// Helper to get team member photo URL
export function getTeamMemberPhotoUrl(member: TeamMember): string {
  if (member.photo) {
    return pb.files.getUrl(member, member.photo);
  }
  return 'https://placehold.co/300x300.png';
}
