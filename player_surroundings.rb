class PlayerSurroundings
  attr_accessor :bound_enemy_directions, :captive_directions, :direction_of_last_player_position, :enemy_directions, :empty_directions, :stairs_direction, :wall_directions
  attr_reader :directions, :warrior

  def initialize(options)
    @captive_directions = []
    @enemy_directions = []
    @bound_enemy_directions = []
    @stairs_direction = []
    @wall_directions = []
    @empty_directions = []
    @direction_of_last_player_position = []
    @warrior = options[:warrior]
  end

  def feel_around_for_stairs_and_walls
    self.stairs_direction = feel_for("stairs").first
    self.wall_directions = feel_for("wall")
  end

  def feel_around_for_empty_space
    self.empty_directions = feel_for("empty")
  end

  def feel_around_for_units
    self.captive_directions = feel_for("captive")
    self.enemy_directions = feel_for("enemy")
  end

  private

  def feel_for(target)
    target_directions = []

    directions.each do |direction|
      space = warrior.feel(direction)

      case target
      when "enemy"
        target_directions << direction if space.enemy?
      when "captive"
        target_directions << direction if space.captive? && direction != self.bound_enemy_directions
      when "stairs"
        target_directions << direction if space.stairs?
      when "wall"
        target_directions << direction if space.wall?
      when "empty"
        target_directions << direction if space.empty?
      end
    end

    return target_directions
  end

  def directions
    @directions = [:forward, :right, :backward, :left]
  end
end
