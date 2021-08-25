require "pry"
require "pry-nav"
require "awesome_print"

class Player
  def play_turn(warrior)
    @warrior = warrior
    @initial_warrior_health ||= warrior.health
    @occupied_spaces = warrior.listen
    @captive_spaces = []
    @enemy_spaces = []
    @bound_enemy_directions ||= []
    @directions = [:forward, :right, :backward, :left]

    @occupied_spaces.each do |occupied_space|
      @captive_spaces << occupied_space if occupied_space.captive?
      @enemy_spaces << occupied_space if occupied_space.enemy?
    end

    @occupied_directions = feel_around_for_units
    feel_around_for_stairs_and_walls
    feel_around_for_empty_space
    # @stairs_direction = warrior.feel.stairs
    pp "@captive_directions"
    pp @captive_directions
    pp "@enemy_directions"
    pp @enemy_directions
    pp "@occupied_directions"
    pp @occupied_directions

    warrior_action
  end

  def warrior_action
    @enemy_direction = @enemy_directions.first
    @bound_enemy_direction = @bound_enemy_directions.first
    @captive_direction = @captive_directions.first
    stairs_direction = @warrior.direction_of_stairs

    if captives_present_and_no_adjacent_enemies?
      walk_to_captives
    elsif multiple_adjacent_unbound_enemies?
      bind_enemy(@enemy_direction)
    elsif one_adjacent_unbound_enemy?
      attack_enemy(@enemy_direction)
    elsif adjacent_captive?
      captive_is_an_enemy ? attack_enemy(@bound_enemy_direction) : rescue_captive(@captive_direction)
    # All captives rescued and no enemies in path.
    else
      walk_to(stairs_direction)
    end
  end

  def walk_to_captives
    captive_direction = @warrior.direction_of(@captive_spaces.first)

    if captive_direction != @stairs_direction
      walk_to(captive_direction)
    else
      @empty_directions.each do |empty_direction|
        empty_direction == @stairs_direction ? next : walk_to(empty_direction)
      end
    end
  end

  def captives_present_and_no_adjacent_enemies?
    @captive_spaces.any? && @captive_directions.empty? && @enemy_directions.empty?
  end

  def stairs_not_in_path?
    captive_direction != @stairs_direction.first
  end

  def multiple_adjacent_unbound_enemies?
    @enemy_directions.any? && @enemy_directions.size > 1
  end

  def one_adjacent_unbound_enemy?
    @enemy_directions.size == 1
  end

  def adjacent_captive?
    @captive_directions.any?
  end

  def captive_is_an_enemy
    @bound_enemy_direction == @captive_direction
  end

  def feel_around_for_stairs_and_walls
    @stairs_direction = feel_for("stairs").first
    @wall_directions = feel_for("wall")
  end

  def feel_around_for_empty_space
    @empty_directions = feel_for("empty")
  end

  def feel_around_for_units
    @captive_directions = feel_for("captive")
    @enemy_directions = feel_for("enemy")
  end

  def feel_for(target)
    target_directions = []

    @directions.each do |direction|
      space = @warrior.feel(direction)

      case target
      when "enemy"
        target_directions << direction if space.enemy?
      when "captive"
        target_directions << direction if space.captive? && direction != @bound_enemy_directions
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

  def bind_enemy(direction)
    @bound_enemy_directions << direction
    @warrior.bind!(direction)
    return true
  end

  def attack_enemy(direction)
    @warrior.attack!(direction)
    return true
  end

  def rescue_captive(direction)
    @warrior.rescue!(direction)
    return true
  end

  def walk_to(direction)
    @bound_enemy_directions = []
    @warrior.walk!(direction)
    return true
  end

end

# class PlayerSurroundings
#   attr_accessor :bound_enemy_directions, :captive_directions, :enemy_directions, :stairs_direction, :wall_directions

#   def initialize(options)
#     @captive_directions = options[:captive_directions]
#     @enemy_directions = options[:enemy_directions]
#     @stairs_direction = options[:stairs_direction]
#     @wall_directions = options[:wall_directions]
#     @empty_directions = options[:empty_directions]
#   end
# end

#  -----
# |    S|
# |@> SC|
#  -----
