import { factories } from "@strapi/strapi";

const UID = "api::habit-log.habit-log";
const HABIT_UID = "api::habit.habit";

export default factories.createCoreController(UID, ({ strapi }) => ({
  async find(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { habit, from, to } = ctx.query as {
      habit?: string;
      from?: string;
      to?: string;
    };

    const filters: any = { owner: { documentId: user.documentId } };
    if (habit) filters.habit = { documentId: habit };
    if (from || to) {
      filters.date = {
        ...(from && { $gte: from }),
        ...(to && { $lte: to }),
      };
    }

    const entities = await strapi.documents(UID).findMany({
      filters,
      sort: "date:desc",
      limit: 1000,
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

    const { habit, date } = ctx.request.body.data ?? {};
    if (!habit || !date) return ctx.badRequest("habit e date sono obbligatori");

    const ownHabit = await strapi.documents(HABIT_UID).findFirst({
      filters: { documentId: habit, owner: { documentId: user.documentId } },
    });
    if (!ownHabit) return ctx.notFound("Habit non trovato");

    const existing = await strapi.documents(UID).findFirst({
      filters: { habit: { documentId: habit }, date },
    });
    if (existing) return ctx.conflict("Già segnato per questa data");

    const entity = await strapi.documents(UID).create({
      data: { habit, date, owner: user.documentId },
    });

    const sanitized = await strapi.contentAPI.sanitize.output(
      entity,
      strapi.contentType(UID),
      { auth: ctx.state.auth },
    );
    return { data: sanitized };
  },

  async update(ctx) {
    return ctx.methodNotAllowed("Usa create o delete");
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
