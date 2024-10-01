require 'graphql/client'
require 'graphql/client/http'

module PokeapiService
  HTTP = GraphQL::Client::HTTP.new("https://beta.pokeapi.co/graphql/v1beta")

  Schema = GraphQL::Client.load_schema(HTTP)
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

  GetPokemonsWithTypes = Client.parse <<-'GRAPHQL'
  query($limit: Int!, $offset: Int!, $search: String) {
    pokemon_v2_pokemon_aggregate(
      where: {name: {_ilike: $search }}
    ) {
      aggregate {
        count
      }
    }
    pokemon_v2_pokemon(
      limit: $limit,
      offset: $offset,
      where: {name: {_ilike: $search }}
    ) {
      id
      name
      pokemon_v2_pokemontypes {
        pokemon_v2_type {
          name
        }
      }
      pokemon_v2_pokemonsprites {
        sprites
      }
    }
  }
GRAPHQL

  GetPokemonById = Client.parse <<-'GRAPHQL'
  query($id: Int) {
    pokemon_v2_pokemon(where: { id: { _eq: $id }}) {
      id
      name
      height
      weight
      base_experience
      pokemon_v2_pokemontypes {
        pokemon_v2_type {
          name
        }
      }
      pokemon_v2_pokemonsprites {
        sprites
      }
    }
  }
  GRAPHQL


GetPokemonsByTypes = Client.parse <<-'GRAPHQL'
query($types: [String!], $limit: Int!, $offset: Int!, $search: String) {
  pokemon_v2_pokemon_aggregate(
    where: {
      _and: [
        { pokemon_v2_pokemontypes: { pokemon_v2_type: { name: { _in: $types } } } },
        { name: { _ilike: $search } }
      ]
    }
  ) {
    aggregate {
      count
    }
  }
  pokemon_v2_pokemon(
    where: {
      _and: [
        { pokemon_v2_pokemontypes: { pokemon_v2_type: { name: { _in: $types } } } },
        { name: { _ilike: $search } }
      ]
    },
    limit: $limit,
    offset: $offset
  ) {
    id
    name
    pokemon_v2_pokemontypes {
      pokemon_v2_type {
        name
      }
    }
    pokemon_v2_pokemonsprites {
      sprites
    }
  }
}
GRAPHQL

def self.fetch_pokemons(limit, offset, types, search)
  search_query = search.present? ? "%#{search}%" : nil

  response = if types.present?
               Client.query(GetPokemonsByTypes, variables: { types: types, limit: limit, offset: offset, search: search_query })
             else
               Client.query(GetPokemonsWithTypes, variables: { limit: limit, offset: offset, search: search_query })
             end

  raise "Error fetching pokemons: #{response.errors}" if response.errors.any?

  total_count = response.data.pokemon_v2_pokemon_aggregate.aggregate.count

  pokemons = response.data.pokemon_v2_pokemon.map do |pokemon|
    {
      id: pokemon.id,
      name: pokemon.name,
      types: pokemon.pokemon_v2_pokemontypes.map { |t| t.pokemon_v2_type.name },
      image_url: pokemon.pokemon_v2_pokemonsprites.map(&:sprites).first&.dig('other', 'home', 'front_default')
    }
  end
  { total: total_count, pokemons: pokemons }
end

  
  def self.fetch_pokemon_by_id(id = nil)
    id_value = id.is_a?(Hash) ? id[:id] : id
    response = Client.query(GetPokemonById, variables: { id: id_value})

    response.data.pokemon_v2_pokemon.map do |pokemon|
      {
        id: pokemon.id,
        name: pokemon.name,
        types: pokemon.pokemon_v2_pokemontypes.map { |t| t.pokemon_v2_type.name },
        image_url: pokemon.pokemon_v2_pokemonsprites.map(&:sprites).first&.dig('other', 'home', 'front_default'),
        height: pokemon.height,
        weight: pokemon.weight,
        base_experience: pokemon.base_experience
      }
    end
  end
end
