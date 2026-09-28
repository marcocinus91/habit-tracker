import { factories } from "@strapi/strapi";

const UID = "api::habit.habit";

export default factories.createCoreController(UID, ({ strapi }) => ({
  async find(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const entities = await strapi.documents(UID).findMany({
      filters: { owner: { documentId: user.documentId } },
      sort: "createdAt:asc",
      limit: 200,
    });

    const sanitized = await strapi.contentAPI.sanitize.output(
      entities,
      strapi.contentType(UID),
      { auth: ctx.state.auth },
    );
    return { data: sanitized };
  },

  async findOne(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const entity = await strapi.documents(UID).findFirst({
      filters: {
        documentId: ctx.params.id,
        owner: { documentId: user.documentId },
      },
    });
    if (!entity) return ctx.notFound();

    const sanitized = await strapi.contentAPI.sanitize.output(
      entity,
      strapi.contentType(UID),
      { auth: ctx.state.auth },
    );
    return { data: sanitized };
  },

  async create(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { name, emoji, color, scheduledWeekdays, reminderTime, startDate } =
      ctx.request.body.data ?? {};

    const entity = await strapi.documents(UID).create({
      data: {
        name,
        emoji,
        color,
        scheduledWeekdays,
        reminderTime,
        startDate,
        owner: user.documentId,
      },
    });

    const sanitized = await strapi.contentAPI.sanitize.output(
      entity,
      strapi.contentType(UID),
      { auth: ctx.state.auth },
    );
    return { data: sanitized };
  },

  async update(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const entity = await strapi.documents(UID).findFirst({
      filters: {
        documentId: ctx.params.id,
        owner: { documentId: user.documentId },
      },
    });
    if (!entity) return ctx.notFound();

    delete ctx.request.body.data?.owner;
    return super.update(ctx);
  },

  async delete(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const entity = await strapi.documents(UID).findFirst({
      filters: {
        documentId: ctx.params.id,
        owner: { documentId: user.documentId },
      },
    });
    if (!entity) return ctx.notFound();

    return super.delete(ctx);
  },
}));
