class MapSpaces
  attr_accessor :captive_spaces, :captive_spaces_with_bombs, :enemy_spaces

  def initialize(options)
    @captive_spaces = []
    @captive_spaces_with_bombs = []
    @enemy_spaces = []
    @warrior = options[:warrior]
  end

  def update_knowledge_of_spaces
    occupied_spaces = @warrior.listen

    occupied_spaces.each do |occupied_space|
      @captive_spaces << occupied_space if occupied_space.captive?
      @captive_spaces_with_bombs << occupied_space if occupied_space.ticking?
      @enemy_spaces << occupied_space if occupied_space.enemy?
    end

    [@captive_spaces, @captive_spaces_with_bombs, @enemy_spaces]
  end
end
