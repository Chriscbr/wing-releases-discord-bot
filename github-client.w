pub struct GitCommit {
  message: str;
  author: str;
  username: str;
}

pub class GithubClient {
  pub extern "./github-client.js" static inflight getCommitsSinceLastSunday(owner: str, name: str, token: str?): Array<GitCommit>;
}
