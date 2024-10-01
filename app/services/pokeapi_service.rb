# app/services/pokeapi_service.rb
require 'graphql/client'
require 'graphql/client/http'

module PokeapiService
  HTTP = GraphQL::Client::HTTP.new("https://beta.pokeapi.co/graphql/v1beta")

  # Definir el esquema
  Schema = GraphQL::Client.load_schema(HTTP)
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

  # Definir la consulta para obtener Pokémon con tipos
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

  # Definir la consulta para obtener un Pokémon específico por ID o nombre
  GetPokemonById = Client.parse <<-'GRAPHQL'
    query($id: Int) {
      pokemon_v2_pokemon(where: { id: { _eq: $id }}) {
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

  # Manejar errores en la respuesta
  raise "Error fetching pokemons: #{response.errors}" if response.errors.any?

  total_count = response.data.pokemon_v2_pokemon_aggregate.aggregate.count # Obtener el total

  pokemons = response.data.pokemon_v2_pokemon.map do |pokemon|
    {
      id: pokemon.id,
      name: pokemon.name,
      types: pokemon.pokemon_v2_pokemontypes.map { |t| t.pokemon_v2_type.name },
      image_url: pokemon.pokemon_v2_pokemonsprites.map(&:sprites).first&.dig('other', 'home', 'front_default')
    }
  end
  puts "TOTLTAAAAAL"
  puts total_count
  { total: total_count, pokemons: pokemons } # Devolver el total junto con los Pokémon
end

  # Método para obtener un Pokémon por ID o nombre
  def self.fetch_pokemon_by_id(id = nil, name = nil)
     # Asegúrate de que 'id' sea un número entero.
    id_value = id.is_a?(Hash) ? id[:id] : id
    puts "ID a buscar: #{id_value.inspect}" # Mostrará el valor correcto del ID
    response = Client.query(GetPokemonById, variables: { id: id_value})

    puts response.to_h

    response.data.pokemon_v2_pokemon.map do |pokemon|
      {
        id: pokemon.id,
        name: pokemon.name,
        types: pokemon.pokemon_v2_pokemontypes.map { |t| t.pokemon_v2_type.name },
        image_url: pokemon.pokemon_v2_pokemonsprites.map(&:sprites).first&.dig('other', 'home', 'front_default')
      }
    end
  end
end
