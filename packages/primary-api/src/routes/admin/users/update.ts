import { Static, Type } from '@sinclair/typebox'
import type { FastifyPluginAsync, FastifySchema } from 'fastify'
import { DEFAULT_SCHEMA_CODES } from '../../constants'
import { assertPanfactumRoleFromSession } from '../../../util/assertPanfactumRoleFromSession'
import { getDB } from '../../../db/db'
import { sql } from 'kysely'
import { UserDeletedAt, UserEmail, UserFirstName, UserId, UserIsDeleted, UserLastName, UserUpdatedAt } from '../../models/user'
import { dateToUnixSeconds } from '../../../util/dateToUnixSeconds'

/**********************************************************************
 * Typings
 **********************************************************************/

const Delta = Type.Object({
  id: UserId,
  firstName: Type.Optional(UserFirstName),
  lastName: Type.Optional(UserLastName),
  email: Type.Optional(UserEmail),
  isActive: Type.Optional(Type.Boolean({ description: 'Whether the user should be marked active.' }))
}, { additionalProperties: true })
export const UpdateBody = Type.Array(Delta)
export type UpdateBodyType = Static<typeof UpdateBody>

export const UpdateReply = Type.Array(Type.Composite([
  Type.Required(Delta),
  Type.Object({
    updatedAt: UserUpdatedAt,
    deletedAt: UserDeletedAt,
    isActive: UserIsDeleted
  })
]))
export type UpdateReplyType = Static<typeof UpdateReply>

/**********************************************************************
 * Route Logic
 **********************************************************************/

export const UpdateUsersRoute:FastifyPluginAsync = async (fastify) => {
  void fastify.put<{Body: UpdateBodyType, Reply: UpdateReplyType}>(
    '/users',
    {
      schema: {
        description: 'Applies a set of user patches and returns the updated user objects',
        body: UpdateBody,
        response: {
          200: UpdateReply,
          ...DEFAULT_SCHEMA_CODES
        },
        security: [{ cookie: [] }]
      } as FastifySchema
    },
    async (req) => {
      await assertPanfactumRoleFromSession(req, 'admin')

      const db = await getDB()
      const results = await Promise.all(req.body.map(userDelta => {
        return db
          .updateTable('user')
          .set({
            firstName: userDelta.firstName,
            lastName: userDelta.lastName,
            email: userDelta.email,
            updatedAt: sql`NOW()`
          })
          .where('id', '=', userDelta.id)
          .returning(eb => [
            'id',
            'firstName',
            'lastName',
            'email',
            'updatedAt',
            'deletedAt',
            eb('deletedAt', 'is', null).as('isActive')
          ])
          .executeTakeFirstOrThrow()
      }))

      return results.map(result => ({
        ...result,
        updatedAt: dateToUnixSeconds(result.updatedAt),
        deletedAt: result.deletedAt !== null ? dateToUnixSeconds(result.deletedAt) : null,
        isActive: Boolean(result.isActive)
      }))
    }
  )
}
