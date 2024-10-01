# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World!"
    end

    field :pokemon_list, Types::PokemonListType, null: false do
      description "Obtener listado de Pokémon con sus tipos"
      argument :limit, Integer, required: true
      argument :offset, Integer, required: true
      argument :search, String, required: false
      argument :types, [String], required: false
    end

    def pokemon_list(limit:, offset:, search:, types: nil)
      puts "SEARCH"
      puts search
      search_value = "%#{search}%"
      puts search_value
      response = types ? PokeapiService.fetch_pokemons(limit, offset, types, search_value) : PokeapiService.fetch_pokemons(limit, offset, types, search_value)
      #response = PokeapiService.fetch_pokemons(limit, offset, types)
      
      puts "RESPONSEE"
      puts response
      {
        list: response[:pokemons], total: response[:total]
      }
    end

    field :pokemons, [Types::PokemonType], null: false do
      description "Obtener listado de Pokémon con sus tipos"
      argument :limit, Integer, required: true
      argument :offset, Integer, required: true
      argument :search, String, required: false
      argument :types, [String], required: false
    end

    def pokemons(limit:, offset:, search:, types: nil)
      puts "SEARCH"
      puts search
      search_value = "%#{search}%"
      puts search_value
      response = types ? PokeapiService.fetch_pokemons(limit, offset, types, search_value) : PokeapiService.fetch_pokemons(limit, offset, types, search_value)
      #response = PokeapiService.fetch_pokemons(limit, offset, types)
      
      puts "RESPONSEE"
      puts response
         
      response[:pokemons].map do |pokemon|
        {
          id: pokemon[:id],
          name: pokemon[:name],
          types: pokemon[:types],
          image_url: pokemon[:image_url]
        }
      end
    end

    # Query para obtener los detalles de un Pokémon específico
    field :pokemon, Types::PokemonType, null: false do
      description "Obtener detalles de un Pokémon por su ID"
      argument :id, Integer, required: false
    end

    def pokemon(id: nil)
      # Asegúrate de que se proporcione un ID o un nombre
      raise GraphQL::ExecutionError, "Se requiere un ID para buscar el Pokémon" unless id
    
      # Realizar la consulta a la API GraphQL
      response = PokeapiService.fetch_pokemon_by_id(id: id) if id
    
      # Retornar los datos del Pokémon
      response.first # Suponiendo que fetch_pokemon_by_name_or_id retorna un array
    end

    # Query para obtener la lista de tipos de Pokémon
    field :pokemon_types, [String], null: false, description: "Devuelve todos los tipos de Pokémon"

    def pokemon_types
      url = "https://pokeapi.co/api/v2/type"
      response = HTTParty.get(url)
      response["results"].map { |type| type["name"] }
    end
  end
end
