bring "./util.w" as myutil;

test "isBreakingChange" {
  assert(myutil.isBreakingChange("v1.0.0"));
  assert(myutil.isBreakingChange("v11.0.0"));
  assert(myutil.isBreakingChange("v0.1.0"));
  assert(myutil.isBreakingChange("v0.11.0"));
  assert(!myutil.isBreakingChange("v0.0.1"));
  assert(!myutil.isBreakingChange("v0.1.1"));
  assert(!myutil.isBreakingChange("v1.1.0"));
  assert(!myutil.isBreakingChange("v1.1.1"));
  assert(myutil.isBreakingChange("lib-v1.0.0"));
  assert(myutil.isBreakingChange("lib-v11.0.0"));
  assert(myutil.isBreakingChange("lib-v0.1.0"));
  assert(myutil.isBreakingChange("lib-v0.11.0"));
  assert(!myutil.isBreakingChange("lib-v0.0.1"));
  assert(!myutil.isBreakingChange("lib-v0.1.1"));
  assert(!myutil.isBreakingChange("lib-v1.1.0"));
  assert(!myutil.isBreakingChange("lib-v1.1.1"));
}
