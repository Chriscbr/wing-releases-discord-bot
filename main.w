bring cloud;
bring http;
bring util;

// -------------------------------
// Discord

struct DiscordProps {
  token: cloud.Secret;
}

struct PostMessageOptions {
  channel: str;
  text: str;
}

class DiscordClient {
  token: cloud.Secret;

  new(props: DiscordProps) {
    this.token = props.token;
  }

  pub inflight sendMessage(args: PostMessageOptions) {
    let token = this.token.value();

    let endpoint = "https://discord.com/api/v10/channels/{args.channel}/messages";
    let res = http.fetch(endpoint, {
      method: http.HttpMethod.POST,
      headers: {
        Authorization: "Bot {token}",
        "Content-Type": "application/json; charset=UTF-8",
        "User-Agent": "DiscordBot (https://github.com/Chriscbr/wing-releases-discord-bot, 0.0.1)",
      },
      body: Json.stringify({
        content: args.text,
        // suppress embeds
        flags: 4, // 1 << 2
      }),
    });

    log(Json.stringify(res));
  }  
}

// -------------------------------
// Github

struct GithubRelease {
  title: str;
  author: str;
  tag: str;
  body: str;
  url: str;
}

interface IOnGitHubRelease {
  inflight handle(release: GithubRelease): void;
}

struct DiscordPublisherProps {
  discord: DiscordClient;
  allReleasesChannel: str?;
  breakingChangesChannel: str?;
}

let breakingChangeRegex = regex.compile("^(.*-)?v[0-9]+\\.0\\.0$|^(.*-)?v0\\.[0-9]+\\.0$");

let isBreakingChange = inflight (tag: str): bool => {
  // version should match vx.0.0 or v0.x.0
  return breakingChangeRegex.test(tag);
};

class DiscordPublisher impl IOnGitHubRelease {
  discord: DiscordClient;
  allReleasesChannel: str?;
  breakingChangesChannel: str?;

  new(props: DiscordPublisherProps) {
    this.discord = props.discord;
    this.allReleasesChannel = props.allReleasesChannel;
    this.breakingChangesChannel = props.breakingChangesChannel;
  }

  pub inflight handle(release: GithubRelease) {
    log("Handling release: {Json.stringify(release)}");

    let var text = "{release.title} has been released! :rocket:";
    if release.body?.trim() != "" {
      text += "\n\n{release.body}";
    }
    text += "\n\nLearn more: {release.url}";

    let breakingChange = isBreakingChange(release.tag);

    log("Is {release.tag} a breaking change?: {breakingChange}");

    if breakingChange && this.breakingChangesChannel != nil {
      log("Posting discord message: {text}");
      this.discord.sendMessage(channel: this.breakingChangesChannel!, text: text);
    }
  }
}

struct GithubScannerProps {
  owner: str;
  repo: str;
}

class GithubScanner {
  api: cloud.Api;
  pub url: str;
  releases: cloud.Topic;

  new(props: GithubScannerProps) {
    this.api = new cloud.Api();
    this.releases = new cloud.Topic();
    this.url = this.api.url;

    this.api.post("/payload", inflight (req: cloud.ApiRequest): cloud.ApiResponse => {
      if req.headers?.tryGet("x-github-event") == "ping" {
        return cloud.ApiResponse {
          status: 200,
          body: "Received ping event from GitHub."
        };
      }

      let body = Json.parse(req.body ?? "\{\}");

      log("received event: {Json.stringify(body)}");

      let eventAction = str.fromJson(body.get("action"));
      if eventAction != "released" {
        let message = "Skipping event type with type '{eventAction}' (only looking for \"released\")";
        log(message);
        return cloud.ApiResponse {
          status: 200,
          body: message, 
        };
      }

      let repo = str.fromJson(body.get("repository").get("full_name"));
      if repo != "{props.owner}/{props.repo}" {
        let message = "skipping release for repo '{repo}'";
        log(message);
        return cloud.ApiResponse {
          status: 200,
          body: message,
        };
      }

      this.releases.publish(Json.stringify(body));
      let releaseTag = str.fromJson(body.get("release").get("tag_name"));
      log("published release {releaseTag} to topic");

      return cloud.ApiResponse {
        status: 200,
        body: "published release event",
      };
    });
  }

  pub onRelease(handler: IOnGitHubRelease): cloud.Function {
    return this.releases.onMessage(inflight (message: str) => {
      let event = Json.parse(message);
      let release = GithubRelease {
        title: str.fromJson(event.get("release").get("name")),
        author: str.fromJson(event.get("release").get("author").get("login")),
        tag: str.fromJson(event.get("release").get("tag_name")),
        body: str.fromJson(event.get("release").get("body")),
        url: str.fromJson(event.get("release").get("html_url")),
      };
      handler.handle(release);
    });
  }
}

// --------------------------------
// Main

let discordToken = new cloud.Secret(name: "DISCORD_TOKEN") as "DiscordToken";
let discord = new DiscordClient(token: discordToken) as "DiscordClient";

let wingScanner = new GithubScanner(owner: "winglang", repo: "wing") as "WingScanner";
let winglibsScanner = new GithubScanner(owner: "winglang", repo: "winglibs") as "WinglibsScanner";

let discordPublisher = new DiscordPublisher(
  discord: discord,
  allReleasesChannel: nil,
  breakingChangesChannel: "breaking-changes",
) as "DiscordPublisher";

wingScanner.onRelease(discordPublisher);
winglibsScanner.onRelease(discordPublisher);

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
