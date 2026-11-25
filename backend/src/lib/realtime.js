import { Emitter } from '@socket.io/redis-emitter';
import { createRedisConnection } from './redis.js';
import { config } from '../config/env.js';

/**
 * Emits real-time events to a user's room. Inside the API process the
 * Socket.IO server is used directly; worker processes publish through the
 * Redis emitter, which the API instances' Redis adapter fans out.
 */
let io;
let emitter;

export function setIo(server) {
  io = server;
}

export function emitToUser(userId, event, payload) {
  const room = `user:${userId}`;
  if (io) return io.to(room).emit(event, payload);
  if (config.isTest) return undefined;
  emitter ??= new Emitter(createRedisConnection());
  return emitter.to(room).emit(event, payload);
}
