defmodule Support.Factory do
  @moduledoc false
  use Smokestack

  factory Support.Post do
    attribute(:title, &Support.Random.sentence/0)
    attribute(:body, &Support.Random.paragraph/0)
  end

  factory Support.Author do
    attribute(:name, &Support.Random.name/0)
  end
end
