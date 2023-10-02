defmodule AshCubDB.DataLayerTest do
  use ExUnit.Case, async: true
  alias Ash.{Error.Query.NotFound, Query}
  alias AshCubDB.Info
  alias Support.{Api, Author, Post}
  import Support.Factory
  require Query

  setup do
    on_exit(fn ->
      AshCubDB.clear(Post)
      AshCubDB.clear(Author)
    end)
  end

  describe "transformer" do
    test "it correctly infers the data directory" do
      assert {:ok, path} = Info.cubdb_directory(Post)
      assert path =~ ~r/ash_cubdb\/priv\/cubdb\/post$/
    end
  end

  describe "create" do
    test "it creates a record" do
      params = params!(Post)

      assert {:ok, post} = Post.create(params)
      assert [{key, value}] = dump(Post)
      assert key == {Ecto.UUID.dump!(post.id)}
      assert value == {nil, post.body, post.title}
    end

    test "it honours context multitenancy" do
      insert!(Author, count: 3)

      assert {:ok, author} =
               Author
               |> params!()
               |> Author.create(tenant: :tenant)

      keys =
        dump(Author)
        |> Enum.map(&elem(&1, 0))

      assert {:tenant, {Ecto.UUID.dump!(author.id)}} in keys
      assert Enum.count(keys, &(elem(&1, 0) == nil)) == 3
    end

    test "it doesn't allow IDs to conflict" do
      uuid = Ash.UUID.generate()

      params =
        params!(Post)
        |> Map.put(:id, uuid)

      assert {:ok, %{id: ^uuid}} = Post.create(params)
      assert {:error, invalid} = Post.create(params)

      assert Exception.message(invalid) =~ "id: has already been taken"
    end
  end

  describe "upsert" do
    test "it creates a record" do
      params = params!(Post)

      assert {:ok, post} = Post.create(params, upsert?: true)
      assert [{key, value}] = dump(Post)
      assert key == {Ecto.UUID.dump!(post.id)}
      assert value == {nil, post.body, post.title}
    end

    test "it updates an existing record" do
      params = params!(Post)

      assert {:ok, post} = Post.create(params)

      params =
        params
        |> Map.put(:title, Faker.Lorem.sentence())
        |> Map.put(:id, post.id)

      assert {:ok, updated} = Post.create(params, upsert?: true)
      assert updated.id == post.id
      assert updated.title == params[:title]
      assert updated.title != post.title
    end
  end

  describe "read" do
    test "non-tenant scoped read" do
      expected = insert!(Post, count: 3)

      assert {:ok, actual} = Post.read()

      assert Enum.all?(actual, &is_struct(&1, Post))

      for post <- expected do
        assert post.id in Enum.map(actual, & &1.id)
      end
    end

    test "tenant scoped read" do
      insert!(Author, count: 3)

      expected =
        Author
        |> params!(count: 3)
        |> Enum.map(&Post.create!(&1, tenant: :wat))

      assert {:ok, actual} = Post.read(tenant: :wat)

      expected_ids = expected |> Enum.map(& &1.id) |> Enum.sort()
      actual_ids = actual |> Enum.map(& &1.id) |> Enum.sort()

      assert expected_ids == actual_ids
    end

    test "filters work" do
      expected = insert!(Author, attrs: %{name: "Marty McFly"})
      insert!(Author, count: 3)

      [actual] =
        Author
        |> Query.filter(name: "Marty McFly")
        |> Api.read!()

      assert expected.id == actual.id
    end

    test "sorting" do
      insert!(Author, attrs: %{name: "Alice"})
      insert!(Author, attrs: %{name: "Mallory"})
      insert!(Author, attrs: %{name: "Bob"})

      sorted =
        Author
        |> Query.sort(name: :desc)
        |> Api.read!()

      assert Enum.map(sorted, &to_string(&1.name)) == ["Mallory", "Bob", "Alice"]
    end
  end

  describe "update" do
    test "records can be updated" do
      post = insert!(Post)
      params = Post |> params!() |> Map.take([:title])

      assert {:ok, updated} = Post.update(post, params)
      assert updated.id == post.id
      assert updated.title == params.title

      assert {:ok, updated} = Post.get(post.id)
      assert updated.id == post.id
      assert updated.title == params.title
    end
  end

  describe "destroy" do
    test "records can be destroyed" do
      post = insert!(Post)

      assert :ok = Post.destroy(post)
      assert {:error, %NotFound{}} = Post.get(post.id)
    end
  end

  defp dump(resource) do
    resource
    |> via()
    |> CubDB.select()
    |> Enum.reject(&(elem(&1, 0) == :__metadata__))
    |> Enum.to_list()
  end

  defp via(resource), do: {:via, Registry, {AshCubDB.Registry, resource}}
end
