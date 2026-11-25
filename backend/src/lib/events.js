import { logger } from './logger.js';

/**
 * Lightweight in-process domain event bus. Handlers must be idempotent; work
 * that needs retries or must survive crashes is pushed onto a BullMQ queue by
 * the handler rather than performed inline.
 */
const handlers = new Map();

export function onDomainEvent(name, fn) {
  if (!handlers.has(name)) handlers.set(name, []);
  handlers.get(name).push(fn);
}

export async function emitDomainEvent(name, payload) {
  for (const fn of handlers.get(name) ?? []) {
    try {
      await fn(payload);
    } catch (err) {
      logger.error({ err: err.message, event: name }, 'Domain event handler failed');
    }
  }
}
