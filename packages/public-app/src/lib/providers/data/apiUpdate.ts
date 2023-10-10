import type { RaRecord } from 'react-admin'

import { apiPut } from '@/lib/clients/api/apiFetch'

/**********************************************
 * Data Provider Specific API Clients
 *
 * These take the standard API client and enhance them
 * with data provider-specific logic
 * ********************************************/

export async function apiUpdate (path: string, ids: string[], delta: {[prop: string]: unknown}): Promise<RaRecord[]> {
  return apiPut(path, {
    ids,
    delta
  })
}