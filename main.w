bring cloud;
bring http;
bring util;
bring "./github-client.w" as ghclient;
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
  let commits = ghclient.GithubClient.getCommitsSinceLastSunday("winglang", "wing", nil);
  let lines = MutArray<str>[];
  let now = datetime.utcNow();
  lines.push("New features and improvements made to Wing this past week 🚀:");
  lines.push("");

  for commit in commits {
    if commit.message.startsWith("chore") {
      continue;
    }

    // kinda gross - use a for loop to replace each occurrence of #xxxx with a link to the PR
    let r = regex.compile("#[0-9]+");
    let var message = commit.message;
    while true {
      if let indices = r.findIndex(message) {
        let start = indices[0];
        let end = indices[1];
        let issueNumber = message.substring(start + 1, end);
        let issueLink = "https://github.com/winglang/wing/pull/" + issueNumber;
        message = message.substring(0, start) + "[!!!HASH" + issueNumber + "](" + issueLink + ")" + message.substring(end);
      } else {
        break;
      }
    }
    message = message.replaceAll("!!!HASH", "#");
    lines.push("* {message} by {commit.author} ([@{commit.username}](https://github.com/{commit.username}))");
  }

  // log(lines.join("\n"));
  discordClient.sendMessage(channel: "1241131862819340349", text: lines.join("\n"));
});

let schedule = new cloud.Schedule(
  // Every Sunday at 12:15 UTC
  cron: "15 12 * * 0",
);

schedule.onTick(inflight () => {
  weeklySummaryFn.invoke();
});
