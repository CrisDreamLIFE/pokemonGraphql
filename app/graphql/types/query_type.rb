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

     # Query para obtener una lista de Pokémon con paginación
     field :pokemons, [Types::PokemonType], null: false do
      description "Lista de Pokémon con opciones de paginación y filtros"
      argument :limit, Integer, required: false, default_value: 10
      argument :offset, Integer, required: false, default_value: 0
      argument :search, String, required: false
      argument :type, String, required: false
    end

    # Query para obtener los detalles de un Pokémon específico
    field :pokemon, Types::PokemonType, null: false do
      description "Obtener detalles de un Pokémon por su nombre o ID"
      argument :id, Integer, required: false
      argument :name, String, required: false
    end

    def pokemons(limit:, offset:, search: nil, type: nil)
      url = "https://pokeapi.co/api/v2/pokemon?limit=#{limit}&offset=#{offset}"
      response = HTTParty.get(url)
      pokemons = response["results"]

      # Filtro por nombre de Pokémon
      pokemons.select! { |pokemon| pokemon["name"].include?(search.downcase) } if search

      pokemons
    end

    # Query para obtener los detalles de un Pokémon específico
    field :pokemon, Types::PokemonType, null: false do
      description "Obtener detalles de un Pokémon por su nombre o ID"
      argument :id, Integer, required: false
      argument :name, String, required: false
    end

    def pokemon(id: nil, name: nil)
      if id
        # Obtener Pokémon por ID
        url = "https://pokeapi.co/api/v2/pokemon/#{id}"
      elsif name
        # Obtener Pokémon por nombre
        url = "https://pokeapi.co/api/v2/pokemon/#{name.downcase}"
      else
        raise GraphQL::ExecutionError, "Se requiere un ID o un nombre para buscar el Pokémon"
      end

      # Hacer la solicitud a la PokéAPI y retornar los datos
      response = HTTParty.get(url)
      {
        id: response["id"],
        name: response["name"],
        types: response["types"].map { |t| t["type"]["name"] },
        abilities: response["abilities"].map { |a| a["ability"]["name"] }
      }
    end
  end
end
