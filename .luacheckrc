std = "lua51+nvim"
globals = {
  "vim",
}
ignore = {
  "212", -- unused argument
  "213", -- unused loop variable
  "631", -- line is too long (we'll let stylua handle style)
}
exclude_files = {
  "tests/minimal_init.lua",
}
read_globals = {
  "describe",
  "it",
  "before_each",
  "after_each",
  "assert",
  "spy",
  "stub",
  "mock",
}
