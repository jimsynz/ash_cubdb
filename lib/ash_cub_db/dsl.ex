defmodule AshCubDB.Dsl do
  @moduledoc false
  alias Spark.Dsl.Section

  @cubdb %Section{
    name: :cubdb,
    describe: """
    CubDB data layer configuration.
    """,
    examples: [
      """
      cubdb do
        directory "/opt/storage/my_awesome_resource"
        auto_compact? true
        auto_file_sync? true
        name :my_awesome_resource
      end
      """
    ],
    schema: [
      directory: [
        type: {:or, [nil, :string]},
        required: false,
        doc: """
        The directory within which to store the CubDB data.

        If none is supplied, then one will be automatically generated in the
        `priv` directory of the parent OTP application.
        """
      ],
      otp_app: [
        type: :atom,
        required: false,
        doc: """
        The OTP application in whose `priv` directory data should be stored.

        Only used if `directory` is not supplied.  When not provided
        `Application.get_application/1` will be called for the resource.
        """
      ],
      auto_compact?: [
        type: :boolean,
        default: true,
        required: false,
        doc: """
        Whether or not to automatically compact the CubDB database.

        See [the CubDB documentation](https://hexdocs.pm/cubdb/faq.html#what-is-compaction) for more information.
        """
      ],
      auto_file_sync?: [
        type: :boolean,
        default: true,
        required: false,
        doc: """
        Whether or not to automatically flush the buffer to disk on write.

        See [the CubDB documentation](https://hexdocs.pm/cubdb/faq.html#what-does-file-sync-mean)
        """
      ],
      name: [
        type: :atom,
        required: false,
        doc: """
        The name of the CubDB database.

        By default this is the name of the resource module, however in some
        (rare) circumstances you may wish to specifically name the database.
        """
      ]
    ]
  }

  @sections [@cubdb]

  @doc false
  @spec sections :: [Section.t()]
  def sections, do: @sections
end
