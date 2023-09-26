import { useGetOne } from 'react-admin'
import type { AllUserResultType } from '@panfactum/primary-api'

export function useAllUserGetOne (userId: string) {
  return useGetOne<AllUserResultType>('allUsers', { id: userId })
}
