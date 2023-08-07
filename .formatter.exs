spark_locals_without_parens = [
  auto_compact?: 1,
  auto_file_sync?: 1,
  directory: 1,
  name: 1,
  otp_app: 1
]

[
  import_deps: [:ash, :spark],
  inputs: [
    "*.{ex,exs}",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  plugins: [Spark.Formatter],
  locals_without_parens: spark_locals_without_parens,
  export: [
    locals_without_parens: spark_locals_without_parens
  ]
]
