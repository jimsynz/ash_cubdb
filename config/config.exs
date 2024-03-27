import Config

config :git_ops,
  mix_project: Mix.Project.get!(),
  changelog_file: "CHANGELOG.md",
  repository_url: "https://harton.dev/james/ash_cubdb",
  manage_mix_version?: true,
  version_tag_prefix: "v",
  manage_readme_version: "README.md"

if Mix.env() in ~w[dev test]a do
  config :ash_cubdb, ash_domains: [Support.Domain]
  config :ash_cubdb, debug_data_layer_capabilities?: true

  config :spark, :formatter, remove_parens?: true
end
