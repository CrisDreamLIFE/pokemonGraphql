module Types
  class DataType < Types::BaseObject
    field :total, Integer, null: false
    field :pokemons, PokemonType.connection_type, null: false
  end
end