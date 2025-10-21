local home = os.getenv 'HOME'
local mason_path = vim.fn.stdpath 'data' .. '/mason'
-- local root_markers = { 'gradlew', '.git', 'mvnw' }
local root_markers = { 'settings.gradle', '.git', 'mvnw' }

-- Function to find the definitive project root
local function find_project_root()
  -- Prioritize finding the main build file ('gradlew')
  -- local gradle_root = vim.fs.root(0, { 'gradlew' })

  -- if gradle_root then
  -- return gradle_root
  -- end

  -- If no gradlew is found, check for a generic marker (like .git)
  --   return vim.fs.root(0, { '.git', 'mvnw' })
  return vim.fs.dirname(vim.fs.find(root_markers, { upward = true })[1])
end

-- 1. Construct the path to the jdtls executable
local jdtls_bin = mason_path .. '/bin/jdtls'
-- Note: The path to lombok.jar is typically within the jdtls package directory in mason.
local lombok_jar = mason_path .. '/packages/jdtls/lombok.jar'

-- 2. Define the command to start jdtls, including the -javaagent argument for Lombok
local cmd = {
  -- The jdtls executable
  jdtls_bin,

  -- Lombok support: Pass the lombok.jar as a Java agent
  string.format('-javaagent:%s', lombok_jar),

  -- You can optionally add other JVM arguments here if needed:
  -- "--jvm-arg=-Xbootclasspath/a:" .. lombok_jar,

  -- Other jdtls arguments:
  '-configuration',
  home .. '/.config/jdtls/config',
  '-data',
  home .. '/.config/jdtls/workspace',
}
local config = {
  cmd = cmd,
  root_dir = find_project_root(),
}
-- Check if a root was found before trying to start JDTLS
if config.root_dir then
  require('jdtls').start_or_attach(config)
end
