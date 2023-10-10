import { useMemo } from 'react'
import { useParams } from 'react-router-dom'

import { useIdentityQuery } from '@/lib/providers/auth/authProvider'

export function useHasPermissions (check: {hasOneOf?: string[], hasAllOf?: string[]}): boolean {
  const { orgId } = useParams()
  const { data: identity } = useIdentityQuery()

  return useMemo(() => {
    if (orgId === undefined || identity === undefined) {
      console.warn('Tried to derive permissions but orgId or identity was undefined.')
      return false
    }

    const currentOrg = identity.organizations.find(org => org.id === orgId)

    if (currentOrg === undefined) {
      console.warn('Tried to derive permissions but current org is set to an organization the user is not a member of')
      return false
    }

    const { permissions } = currentOrg

    const permissionsSet = new Set<string>(permissions)

    if (!check.hasOneOf && !check.hasAllOf) {
      console.warn('Used useHasPermissions hook without any check parameters. Defaulting to false.')
      return false
    }

    for (const permission of check.hasAllOf ?? []) {
      if (!permissionsSet.has(permission)) {
        return false
      }
    }

    if (check.hasOneOf) {
      for (const permission of check.hasOneOf ?? []) {
        if (permissionsSet.has(permission)) {
          return true
        }
      }
      return false
    } else {
      return true
    }
  }, [identity, orgId, check])
}