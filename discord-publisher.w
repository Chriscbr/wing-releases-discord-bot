bring "./discord.w" as discord;
bring "./github-scanner.w" as ghscanner;
bring "./github-types.w" as gh;
bring "./util.w" as myutil;

pub struct DiscordPublisherProps {
  discordClient: discord.DiscordClient;
  releasesChannel: str;
}

pub class DiscordPublisher impl ghscanner.IOnGitHubRelease {
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

    let breakingChange = myutil.isBreakingChange(release.tag);

    log("Is {release.tag} a breaking change?: {breakingChange}");

    if breakingChange {
      log("Posting discord message: {text}");
      this.discordClient.sendMessage(channel: this.releasesChannel, text: text);
    }
  }
}
