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
    
      # Aquí puedes aplicar el filtro solo después de haber reducido el tamaño de la lista.
      if search.present?
        response = response.select { |pokemon| pokemon[:name].downcase.include?(search.downcase) }
      end
    
      response.map do |pokemon|
        {
          id: pokemon[:id],
          name: pokemon[:name],
          types: pokemon[:types],
          image_url: pokemon[:image_url]
        }
      end
    end

    # def pokemons(limit:, offset:, search: nil, type: nil)
    #   # Filtrar Pokémon por nombre si se proporciona `search`
    #   if search.present?
    #     response = response.select { |pokemon| pokemon[:name].downcase.include?(search.downcase) }
    #   end
    #   # Obtener Pokémon desde la API de PokeAPI
    #   response = PokeapiService.fetch_pokemons(limit, offset, type)
    
      
    
    #   response.map do |pokemon|
    #     {
    #       id: pokemon[:id],
    #       name: pokemon[:name],
    #       types: pokemon[:types],
    #       image_url: pokemon[:image_url] # Asegúrate de incluir image_url aquí
    #     }
    #   end
    # end


     # Query para obtener una lista de Pokémon con paginación
    #  field :pokemons, [Types::PokemonType], null: false do
    #   description "Lista de Pokémon con opciones de paginación y filtros"
    #   argument :limit, Integer, required: false, default_value: 10
    #   argument :offset, Integer, required: false, default_value: 0
    #   argument :search, String, required: false
    #   argument :type, String, required: false
    # end

    # def pokemons(limit:, offset:, search: nil, type: nil)
    #   if type.present?
    #     url = "https://pokeapi.co/api/v2/type/#{type}"
    #     response = HTTParty.get(url)
    #     pokemons = response["pokemon"].map { |p| p["pokemon"] }
        
    #     paginated_pokemons = pokemons[offset, limit] || []

    #   else
    #     url = "https://pokeapi.co/api/v2/pokemon?limit=#{limit}&offset=#{offset}"
    #     response = HTTParty.get(url)
    #     pokemons = response["results"]
    
    #     paginated_pokemons = pokemons
    #   end

    # end

    # Query para obtener los detalles de un Pokémon específico
    field :pokemon, Types::PokemonType, null: false do
      description "Obtener detalles de un Pokémon por su nombre o ID"
      argument :id, Integer, required: false
      argument :name, String, required: false
    end

    def pokemon(id: nil, name: nil)
      # Asegúrate de que se proporcione un ID o un nombre
      raise GraphQL::ExecutionError, "Se requiere un ID o un nombre para buscar el Pokémon" unless id || name
    
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
