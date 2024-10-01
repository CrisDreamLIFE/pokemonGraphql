module Types
  class PokemonListType  < Types::BaseObject
    field :list, [Types::PokemonType], null: false
    field :total, Integer, null: false
  end
end