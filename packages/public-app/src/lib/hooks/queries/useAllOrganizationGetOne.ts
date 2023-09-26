import { useGetOne } from 'react-admin'
import type { AllOrganizationResultType } from '@panfactum/primary-api'

export function useAllOrganizationGetOne (orgId: string) {
  return useGetOne<AllOrganizationResultType>('allOrgs', { id: orgId })
}
