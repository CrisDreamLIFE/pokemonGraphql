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

    field :pokemon_list, Types::PokemonListType, null: false do
      description "Obtener listado de Pokémon con sus tipos"
      argument :limit, Integer, required: true
      argument :offset, Integer, required: true
      argument :search, String, required: false
      argument :types, [String], required: false
    end

    def pokemon_list(limit:, offset:, search:, types: nil)
      search_value = "%#{search}%"
      response = types ? PokeapiService.fetch_pokemons(limit, offset, types, search_value) : PokeapiService.fetch_pokemons(limit, offset, types, search_value)
      
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
      search_value = "%#{search}%"
      response = types ? PokeapiService.fetch_pokemons(limit, offset, types, search_value) : PokeapiService.fetch_pokemons(limit, offset, types, search_value)
               
      response[:pokemons].map do |pokemon|
        {
          id: pokemon[:id],
          name: pokemon[:name],
          types: pokemon[:types],
          image_url: pokemon[:image_url]
        }
      end
    end

    field :pokemon, Types::PokemonType, null: false do
      description "Obtener detalles de un Pokémon por su ID"
      argument :id, Integer, required: false
    end

    def pokemon(id: nil)
      raise GraphQL::ExecutionError, "Se requiere un ID para buscar el Pokémon" unless id
      response = PokeapiService.fetch_pokemon_by_id(id: id) if id
      response.first
    end

    field :pokemon_types, [String], null: false, description: "Devuelve todos los tipos de Pokémon"

    def pokemon_types
      url = "https://pokeapi.co/api/v2/type"
      response = HTTParty.get(url)
      response["results"].map { |type| type["name"] }
    end
  end
end
