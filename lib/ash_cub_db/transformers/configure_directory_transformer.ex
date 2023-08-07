defmodule AshCubDB.ConfigureDirectoryTransformer do
  @moduledoc false

  alias Spark.{Dsl, Dsl.Transformer, Error.DslError}
  use Transformer

  @doc false
  @impl true
  @spec transform(Dsl.t()) :: {:ok, Dsl.t()} | {:error, DslError.t()}
  def transform(dsl_state) do
    module = Transformer.get_persisted(dsl_state, :module)

    with nil <- Transformer.get_option(dsl_state, [:cubdb], :directory),
         nil <- Transformer.get_option(dsl_state, [:cubdb], :otp_app),
         nil <- Application.get_application(module) do
      message = """
      Unable to infer a data storage path for this resource.

      You can either set the `cubdb.directory` DSL option directly, or set the `cubdb.otp_app` option
      to use the application's priv directory for storage.
      """

      {:error, DslError.exception(module: module, path: [:cubdb], message: message)}
    else
      path when is_binary(path) ->
        verify_directory(dsl_state, path)

      otp_app when is_atom(otp_app) ->
        dsl_state =
          dsl_state
          |> Transformer.set_option([:cubdb], :otp_app, otp_app)
          |> Transformer.set_option([:cubdb], :directory, generate_directory(dsl_state))

        {:ok, dsl_state}
    end
  end

  defp generate_directory(dsl_state) do
    otp_app = Transformer.get_option(dsl_state, [:cubdb], :otp_app)

    short_name =
      dsl_state
      |> Transformer.get_persisted(:module)
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    otp_app
    |> :code.priv_dir()
    |> Path.join("cubdb")
    |> Path.join(short_name)
  end

  defp verify_directory(dsl_state, path) do
    case Path.type(path) do
      :absolute ->
        {:ok, dsl_state}

      _ ->
        {:error,
         DslError.exception(
           module: Transformer.get_persisted(dsl_state, :module),
           path: [:cubdb],
           message: "Directory must be an absolute path"
         )}
    end
  end
end
