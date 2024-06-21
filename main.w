bring cloud;
bring http;
bring util;
bring "./github-types.w" as gh;
bring "./github-scanner.w" as ghscanner;
bring "./discord.w" as discord;
bring "./discord-publisher.w" as discordpublisher;

let discordToken = new cloud.Secret(name: "DISCORD_TOKEN") as "DiscordToken";
let discordClient = new discord.DiscordClient(token: discordToken) as "DiscordClient";

let wingScanner = new ghscanner.GithubScanner(repo: "winglang/wing") as "WingScanner";
let winglibsScanner = new ghscanner.GithubScanner(repo: "winglang/winglibs") as "WinglibsScanner";

// To get the ID of a discord channel, you can right click on the channel and click "Copy Link".
// The ID is the part of the URL after the very last "/".

let discordPublisher = new discordpublisher.DiscordPublisher(
  discordClient: discordClient,
  releasesChannel: "1241131862819340349", // #releases
) as "DiscordPublisher";

wingScanner.onRelease(discordPublisher);
winglibsScanner.onRelease(discordPublisher);

let weeklySummaryFn = new cloud.Function(inflight () => {
  log("TODO");
});

let schedule = new cloud.Schedule(
  // Every Sunday at 12:15 UTC
  cron: "15 12 * * 0",
);

schedule.onTick(inflight () => {
  weeklySummaryFn.invoke();
});
