pub class Util {
  pub static inflight isBreakingChange(tag: str): bool {
    // tag should match vx.0.0 or v0.x.0
    let r = regex.compile("^(.*-)?v[0-9]+\\.0\\.0$|^(.*-)?v0\\.[0-9]+\\.0$");
  return r.test(tag);
  }
}
