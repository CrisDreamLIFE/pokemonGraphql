module Types
  class PokemonType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :types, [String], null: true
    field :abilities, [String], null: true
    field :height, Integer, null: true
    field :weight, Integer, null: true
    field :base_experience, Integer, null: true
    field :image_url, String, null: true
  end
end