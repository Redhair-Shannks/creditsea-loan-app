const DAY_MS = 86_400_000;

/** Whole years between `dob` and `now` (UTC based, birthday aware). */
export function ageInYears(dob, now = new Date()) {
  let age = now.getUTCFullYear() - dob.getUTCFullYear();
  const monthDiff = now.getUTCMonth() - dob.getUTCMonth();
  if (monthDiff < 0 || (monthDiff === 0 && now.getUTCDate() < dob.getUTCDate())) age -= 1;
  return age;
}

export const addSeconds = (date, secs) => new Date(date.getTime() + secs * 1000);

export const addDays = (date, days) => new Date(date.getTime() + days * DAY_MS);

/** `YYYY-MM-DD` for a Date, or null. */
export const toIsoDate = (date) => (date ? date.toISOString().slice(0, 10) : null);

/** Parses a strict `YYYY-MM-DD` string into a UTC Date, or returns null if it is not a real date. */
export function parseIsoDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
  const date = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(date.getTime()) || toIsoDate(date) !== value) return null;
  return date;
}
