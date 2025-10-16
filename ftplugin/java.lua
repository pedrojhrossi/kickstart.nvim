local config = {
  cmd = { vim.fn.expand '~/.local/share/nvim/mason/bin/jdtls' },
  root_dir = vim.fs.root(0, { 'gradlew', '.git', 'mvnw' }),
}
require('jdtls').start_or_attach(config)
