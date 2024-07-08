const { DateTime } = require("luxon");

export function nSundaysAgo(count) {
    return DateTime.utc().startOf('week').minus({ weeks: count }).plus({ hours: 12 }).toISO();
}
