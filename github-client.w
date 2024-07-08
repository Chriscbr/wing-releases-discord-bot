pub struct GitCommit {
  message: str;
  author: str;
  username: str;
}

pub class GithubClient {
  pub extern "./github-client.js" static inflight getCommits(owner: str, name: str, since: str?, until: str?, token: str?): Array<GitCommit>;
}
