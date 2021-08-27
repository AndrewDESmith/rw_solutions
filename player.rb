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
    elsif enemies_present?
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
    adjacent_captive_direction = @player_surroundings.captive_directions.first
    adjacent_enemy_directions = @player_surroundings.enemy_directions - @player_surroundings.bound_enemy_directions

    if multiple_adjacent_unbound_enemies?
      bind_all_adjacent_enemies_not_in_path_of_bomb
    elsif one_adjacent_unbound_enemy?
      attack_enemy(adjacent_enemy_directions.first)
    elsif adjacent_captives?
      captive_is_an_enemy?(adjacent_captive_direction) ? attack_bound_enemy_or_rest : rescue_captive(adjacent_captive_direction)
    elsif enemies_present?
      enemy_direction = @warrior.direction_of(@enemy_spaces.first)
      walk_to(enemy_direction)
    elsif captives_present?
      return true if heal_when_injured
      captive_direction = @warrior.direction_of(@captive_spaces.first)
      walk_to(captive_direction)
    else
      walk_to(@warrior.direction_of_stairs)
    end
  end

  def bind_all_adjacent_enemies_not_in_path_of_bomb
    @player_surroundings.enemy_directions.each do |enemy_direction|
      if @warrior.direction_of(@captive_spaces_with_bombs.first) != enemy_direction
        bind_adjacent_enemy(enemy_direction)
        return true
      end
    end
  end

  def bind_adjacent_enemy(enemy_direction)
    bind_enemy(enemy_direction)
  end

  # I never thought that I'd be writing named methods like this in Ruby, but here we are.
  def rescue_captives_with_bombs
    return true if clear_path_towards_captive_with_bomb

    if captives_with_bombs?
      direction_of_captive_with_bomb = @warrior.direction_of(@captive_spaces_with_bombs.first)
      navigate_around_all_obstacles_towards(direction_of_captive_with_bomb)
    else
      seek_out_and_slay_enemies
    end
  end

  def clear_path_towards_captive_with_bomb
    enemy_directions = @player_surroundings.enemy_directions

    @player_surroundings.captive_directions.each do |captive_direction|
      if !captive_is_an_enemy?(captive_direction)
        rescue_captive(captive_direction)
        return true
      elsif multiple_adjacent_unbound_enemies?
        bind_all_adjacent_enemies_not_in_path_of_bomb
        return true
      elsif one_adjacent_unbound_enemy?
        attack_enemy(enemy_directions.first)
        return true
      end
    end

    return false
  end

  def navigate_around_all_obstacles_towards(captive_direction)
    obstacle_directions = @player_surroundings.enemy_directions + @player_surroundings.wall_directions + @player_surroundings.bound_enemy_directions

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
    elsif possible_directions.empty?
      seek_out_and_slay_enemies
    else
      walk_to(possible_directions.first)
    end
  end

  def walk_around_stairs_using(empty_directions)
    empty_directions.each do |empty_direction|
      empty_direction == @player_surroundings.stairs_direction ? next : walk_to(empty_direction)
    end
  end

  def attack_bound_enemy_or_rest
    bound_enemy_direction = @player_surroundings.bound_enemy_directions.first
    heal_when_injured ? true : attack_enemy(bound_enemy_direction)
  end
end

#  -------
# |@ Ss C>|
#  -------
