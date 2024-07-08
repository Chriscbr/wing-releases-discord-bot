export default interface extern {
  getCommits: (owner: string, name: string, since?: (string) | undefined, until?: (string) | undefined, token?: (string) | undefined) => Promise<(readonly (GitCommit)[])>,
}
export interface GitCommit {
  readonly author: string;
  readonly message: string;
  readonly username: string;
}