bring cloud;
bring http;
bring util;
bring "./github-types.w" as gh;
bring "./github-scanner.w" as ghscanner;
bring "./discord.w" as discord;

// -------------------------------
// Github

struct DiscordPublisherProps {
  discordClient: discord.DiscordClient;
  releasesChannel: str;
}

let breakingChangeRegex = regex.compile("^(.*-)?v[0-9]+\\.0\\.0$|^(.*-)?v0\\.[0-9]+\\.0$");

let isBreakingChange = inflight (tag: str): bool => {
  // version should match vx.0.0 or v0.x.0
  return breakingChangeRegex.test(tag);
};

class DiscordPublisher impl ghscanner.IOnGitHubRelease {
  discordClient: discord.DiscordClient;
  releasesChannel: str;

  new(props: DiscordPublisherProps) {
    this.discordClient = props.discordClient;
    this.releasesChannel = props.releasesChannel;
  }

  pub inflight handle(release: gh.GithubRelease) {
    log("Handling release: {Json.stringify(release)}");

    let var text = "{release.title} has been released! :rocket:";
    if release.body?.trim() != "" {
      text += "\n\n{release.body}";
    }
    text += "\n\nLearn more: {release.url}";

    let breakingChange = isBreakingChange(release.tag);

    log("Is {release.tag} a breaking change?: {breakingChange}");

    if breakingChange {
      log("Posting discord message: {text}");
      this.discordClient.sendMessage(channel: this.releasesChannel, text: text);
    }
  }
}

// --------------------------------
// Main

let discordToken = new cloud.Secret(name: "DISCORD_TOKEN") as "DiscordToken";
let discordClient = new discord.DiscordClient(token: discordToken) as "DiscordClient";

let wingScanner = new ghscanner.GithubScanner(repo: "winglang/wing") as "WingScanner";
let winglibsScanner = new ghscanner.GithubScanner(repo: "winglang/winglibs") as "WinglibsScanner";

// To get the ID of a discord channel, you can right click on the channel and click "Copy Link".
// The ID is the part of the URL after the very last "/".

let discordPublisher = new DiscordPublisher(
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

// --------------------------------
// Unit tests

test "isBreakingChange" {
  assert(isBreakingChange("v1.0.0"));
  assert(isBreakingChange("v11.0.0"));
  assert(isBreakingChange("v0.1.0"));
  assert(isBreakingChange("v0.11.0"));
  assert(!isBreakingChange("v0.0.1"));
  assert(!isBreakingChange("v0.1.1"));
  assert(!isBreakingChange("v1.1.0"));
  assert(!isBreakingChange("v1.1.1"));
  assert(isBreakingChange("lib-v1.0.0"));
  assert(isBreakingChange("lib-v11.0.0"));
  assert(isBreakingChange("lib-v0.1.0"));
  assert(isBreakingChange("lib-v0.11.0"));
  assert(!isBreakingChange("lib-v0.0.1"));
  assert(!isBreakingChange("lib-v0.1.1"));
  assert(!isBreakingChange("lib-v1.1.0"));
  assert(!isBreakingChange("lib-v1.1.1"));
}
