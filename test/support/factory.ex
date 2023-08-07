defmodule Support.Factory do
  @moduledoc false
  use Smokestack

  factory Support.Post do
    attribute(:title, &Faker.Lorem.sentence/0)
    attribute(:body, &Faker.Lorem.paragraph/0)
  end

  factory Support.Author do
    attribute(:name, &Faker.Person.name/0)
  end
end
