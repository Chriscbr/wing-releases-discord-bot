bring cloud;
bring "./github-types.w" as gh;

pub interface IOnGitHubRelease {
  inflight handle(release: gh.GithubRelease): void;
}

pub struct GithubScannerProps {
  repo: str;
}

pub class GithubScanner {
  api: cloud.Api;
  pub url: str;
  releases: cloud.Topic;

  new(props: GithubScannerProps) {
    this.api = new cloud.Api();
    this.releases = new cloud.Topic();
    this.url = this.api.url;

    if props.repo.split("/").length != 2 {
      throw "invalid repo name: {props.repo} (expected format: owner/repo)";
    }

    this.api.post("/payload", inflight (req: cloud.ApiRequest): cloud.ApiResponse => {
      if req.headers?.tryGet("x-github-event") == "ping" || req.headers?.tryGet("X-Github-Event") == "ping" {
        return cloud.ApiResponse {
          status: 200,
          body: "Received ping event from GitHub."
        };
      }

      let body = Json.parse(req.body ?? "\{\}");

      log("received event: {Json.stringify(body, indent: 2)} with headers: {Json.stringify(req.headers, indent: 2)}");

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
      if repo != props.repo {
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
      let release = gh.GithubRelease {
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
