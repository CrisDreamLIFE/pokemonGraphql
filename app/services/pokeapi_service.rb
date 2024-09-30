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
    query($limit: Int!, $offset: Int!) {
      pokemon_v2_pokemon(limit: $limit, offset: $offset) {
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
  query($types: [String!], $limit: Int!, $offset: Int!) {
    pokemon_v2_pokemon(where: {pokemon_v2_pokemontypes: {pokemon_v2_type: {name: {_in: $types}}}}, limit: $limit, offset: $offset) {
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

def self.fetch_pokemons(limit, offset, types)
  puts "sdffsdjifsd"
  puts 12312312312312
  puts types
  response = if types.present?
               # Consulta con tipos filtrados y paginación
               Client.query(GetPokemonsByTypes, variables: { types: types, limit: limit, offset: offset })
             else
               # Consulta básica de Pokémon con paginación
               Client.query(GetPokemonsWithTypes, variables: { limit: limit, offset: offset })
             end

  response.data.pokemon_v2_pokemon.map do |pokemon|
    {
      id: pokemon.id,
      name: pokemon.name,
      types: pokemon.pokemon_v2_pokemontypes.map { |t| t.pokemon_v2_type.name },
      image_url: pokemon.pokemon_v2_pokemonsprites.map(&:sprites).first&.dig('other', 'home', 'front_default')
    }
  end
end

  # Método para obtener un listado de Pokémon
  # def self.fetch_pokemons(limit, offset)
  #   response = Client.query(GetPokemonsWithTypes, variables: { limit: limit, offset: offset})

  #   response.data.pokemon_v2_pokemon.map do |pokemon|
  #     {
  #       id: pokemon.id,
  #       name: pokemon.name,
  #       types: pokemon.pokemon_v2_pokemontypes.map { |t| t.pokemon_v2_type.name },
  #       image_url: pokemon.pokemon_v2_pokemonsprites.map(&:sprites).first&.dig('other', 'home', 'front_default') # Acceso a front_default
  #     }
  #   end
  # end

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



# # app/services/pokeapi_service.rb
# require 'graphql/client'
# require 'graphql/client/http'

# module PokeapiService
#   HTTP = GraphQL::Client::HTTP.new("https://beta.pokeapi.co/graphql/v1beta")

#   # Definir el esquema
#   Schema = GraphQL::Client.load_schema(HTTP)
#   Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

#   GetPokemonByNameOrId = Client.parse <<-'GRAPHQL'
#     query($id: Int, $name: String) {
#       pokemon_v2_pokemon(where: { id: { _eq: $id }, name: { _ilike: $name } }) {
#         id
#         name
#         pokemon_v2_pokemontypes {
#           pokemon_v2_type {
#             name
#           }
#         }
#         pokemon_v2_pokemonsprites {
#           sprites {
#             other {
#               home {
#                 front_default
#               }
#             }
#           }
#         }
#       }
#     }
#   GRAPHQL

#   # Definir la consulta para obtener Pokémon con tipos
#   GetPokemonsWithTypes = Client.parse <<-'GRAPHQL'
#     query($limit: Int!, $offset: Int!) {
#       pokemon_v2_pokemon(limit: $limit, offset: $offset) {
#         id
#         name
#         pokemon_v2_pokemontypes {
#           pokemon_v2_type {
#             name
#           }
#         }
#         pokemon_v2_pokemonsprites {
#           sprites # Obtén el sprite frontal por defecto
#         }
#       }
#     }
#   GRAPHQL

#   def self.fetch_pokemons(limit, offset)
#     response = Client.query(GetPokemonsWithTypes, variables: { limit: limit, offset: offset })
  
#     response.data.pokemon_v2_pokemon.map do |pokemon|
#       {
#         id: pokemon.id,
#         name: pokemon.name,
#         types: pokemon.pokemon_v2_pokemontypes.map { |t| t.pokemon_v2_type.name },
#         image_url: pokemon.pokemon_v2_pokemonsprites.map(&:sprites).first&.dig('other', 'home', 'front_default')
#       }
#     end
#   end

#   def self.fetch_pokemon_by_name_or_id(id = nil, name = nil)
#     response = Client.query(GetPokemonByNameOrId, variables: { id: id, name: name })
    
#     # Aquí procesas la respuesta para obtener el Pokémon
#     response.data.pokemon_v2_pokemon.map do |pokemon|
#       {
#         id: pokemon.id,
#         name: pokemon.name,
#         types: pokemon.pokemon_v2_pokemontypes.map { |t| t.pokemon_v2_type.name },
#         image_url: pokemon.pokemon_v2_pokemonsprites.first&.sprites&.dig('other', 'home', 'front_default')
#       }
#     end
#   end
# endvvvvvvvvvvvvvvvv
