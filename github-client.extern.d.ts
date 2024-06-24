export default interface extern {
  getCommitsSinceLastSunday: (owner: string, name: string, token?: (string) | undefined) => Promise<(readonly (GitCommit)[])>,
}
export interface GitCommit {
  readonly author: string;
  readonly message: string;
  readonly username: string;
}