import type { FastifyPluginAsync, FastifyRequest } from 'fastify'
import { Static, Type } from '@sinclair/typebox'
import { DEFAULT_SCHEMA_CODES } from '../constants'
import { getLoginInfo } from '../../util/getLoginInfo'
import { getDB } from '../../db/db'

/**********************************************************************
 * Typings
 **********************************************************************/

export const UserOrganizationsReply = Type.Array(Type.Object({
  id: Type.String(),
  name: Type.String(),
  isUnitary: Type.Boolean()
}))
export type UserOrganizationsReplyType = Static<typeof UserOrganizationsReply>

/**********************************************************************
 * Route Logic
 **********************************************************************/

export const UserOrganizationsRoute:FastifyPluginAsync = async (fastify) => {
  void fastify.get<{Reply: UserOrganizationsReplyType}>(
    '/organizations',
    {
      schema: {
        response: {
          200: UserOrganizationsReply,
          ...DEFAULT_SCHEMA_CODES
        }
      }
    },
    async (req: FastifyRequest) => {
      const { userId } = getLoginInfo(req)
      const db = await getDB()
      return await db
        .selectFrom('user_organization')
        .innerJoin('organization', 'organization.id', 'user_organization.organization_id')
        .select([
          'organization.id as id',
          'organization.name as name',
          'organization.is_unitary as isUnitary'
        ])
        .where('user_organization.user_id', '=', userId)
        .where('user_organization.active', '=', true)
        .execute()
    }
  )
}