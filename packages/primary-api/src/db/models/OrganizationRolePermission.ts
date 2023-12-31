import type { Generated } from 'kysely'

type ReadAndWrite = 'read' | 'write'
export type PermissionResources = 'storefront' |
  'package' |
  'repository' |
  'storefront_billing' |
  'membership' |
  'organization' |
  'subscription' |
  'subscription_billing'

export interface OrganizationRolePermissionTable {
    id: Generated<string>;
    organizationRoleId: string;
    permission: `${ReadAndWrite}:${PermissionResources}` | 'admin';
}

export type Permission = OrganizationRolePermissionTable['permission']
