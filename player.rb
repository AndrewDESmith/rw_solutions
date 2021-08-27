require "pry"
require "pry-nav"
require "awesome_print"

require "player_surroundings"
require "map_spaces"
require "basic_warrior_actions"
require "unit_utilities"
require "warrior_state"

class Player
  include BasicWarriorActions
  include UnitUtilities
  include WarriorState

  def play_turn(warrior)
    @turn ||= 0
    @turn += 1
    @initial_warrior_health ||= warrior.health
    @warrior = warrior

    map_out_level
    initialize_player_surroundings if @turn == 1
    update_knowledge_of_surroundings
    warrior_action
  end

  private

  def map_out_level
    @map_space = MapSpaces.new(warrior: @warrior)
    @captive_spaces, @captive_spaces_with_bombs, @enemy_spaces = @map_space.update_knowledge_of_spaces
  end

  def initialize_player_surroundings
    @player_surroundings = PlayerSurroundings.new(warrior: @warrior)
  end

  def update_knowledge_of_surroundings
    @player_surroundings.feel_around_for_units
    @player_surroundings.feel_around_for_stairs_and_walls
    @player_surroundings.feel_around_for_empty_space
  end

  def warrior_action
    stairs_direction = @warrior.direction_of_stairs

    if captives_present?
      seek_out_and_rescue_captives
      return true
    end

    if enemies_present?
      seek_out_and_slay_enemies
    else
      walk_to(stairs_direction)
    end
  end

  def seek_out_and_rescue_captives
    return true if rescue_captives_with_bombs

    if !adjacent_captives? && !adjacent_enemies
      captive_direction = @warrior.direction_of(@captive_spaces.first)
      navigate_around_all_obstacles_towards(captive_direction)
    end
  end

  def seek_out_and_slay_enemies
    adjacent_enemy_direction = @player_surroundings.enemy_directions.first
    adjacent_captive_direction = @player_surroundings.captive_directions.first

    if multiple_adjacent_unbound_enemies?
      bind_enemy(adjacent_enemy_direction)
    elsif one_adjacent_unbound_enemy?
      attack_enemy(adjacent_enemy_direction)
    elsif adjacent_captives?
      captive_is_an_enemy?(adjacent_captive_direction) ? attack_enemy_or_rest : rescue_captive(adjacent_captive_direction)
    else
      enemy_direction = @warrior.direction_of(@enemy_spaces.first)
      walk_to(enemy_direction)
    end
  end

  # I never thought that I'd be writing named methods like this in Ruby, but here we are.
  def rescue_captives_with_bombs
    if @player_surroundings.captive_directions.any?
      rescue_captive(@player_surroundings.captive_directions.first)
      return true
    else
      captive_with_bomb_direction = @warrior.direction_of(@captive_spaces_with_bombs.first)
      navigate_around_all_obstacles_towards(captive_with_bomb_direction)
    end
  end

  def navigate_around_all_obstacles_towards(captive_direction)
    obstacle_directions = @player_surroundings.enemy_directions + @player_surroundings.wall_directions

    if captive_direction != @player_surroundings.stairs_direction
      obstacle_directions.include?(captive_direction) ? pathfind_towards(captive_direction) : walk_to(captive_direction)
    else
      walk_around_stairs_using(@player_surroundings.empty_directions)
    end
  end

  def pathfind_towards(captive_direction)
    possible_directions = []

    @player_surroundings.empty_directions.each do |empty_direction|
      possible_directions << empty_direction if empty_direction != direction_warrior_moved_from
    end

    if possible_directions.include?(captive_direction)
      walk_to(captive_direction)
    else
      walk_to(possible_directions.first)
    end
  end

  def walk_around_stairs_using(empty_directions)
    empty_directions.each do |empty_direction|
      empty_direction == @player_surroundings.stairs_direction ? next : walk_to(empty_direction)
    end
  end

  def attack_enemy_or_rest
    bound_enemy_direction = @player_surroundings.bound_enemy_directions.first
    warrior_is_injured? ? @warrior.rest! : attack_enemy(bound_enemy_direction)
  end
end

#  ------
# |Cs   >|
# |@  sC |
#  ------
