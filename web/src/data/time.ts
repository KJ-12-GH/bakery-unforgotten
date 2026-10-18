/** Shared time anchors so all seed data is internally consistent. */
export const SEED_NOW = Date.now()

export const minutesAgo = (minutes: number): string =>
  new Date(SEED_NOW - minutes * 60_000).toISOString()

export const hoursAgo = (hours: number): string => minutesAgo(hours * 60)

export const daysAgo = (days: number): string => hoursAgo(days * 24)
