require "pry"
require "pry-nav"
require "awesome_print"

require "player_surroundings"

class Player
  def play_turn(warrior)
    @turn ||= 0
    @turn += 1
    @initial_warrior_health ||= warrior.health
    @warrior = warrior
    @captive_spaces = []
    @enemy_spaces = []
    occupied_spaces = warrior.listen

    occupied_spaces.each do |occupied_space|
      @captive_spaces << occupied_space if occupied_space.captive?
      @enemy_spaces << occupied_space if occupied_space.enemy?
    end

    initialize_player_surroundings if @turn == 1
    survey_immediate_surroundings
    warrior_action
  end

  def initialize_player_surroundings
    options = {
      captive_directions: [],
      enemy_directions: [],
      bound_enemy_directions: [],
      stairs_direction: [],
      wall_directions: [],
      empty_directions: [],
      warrior: @warrior
    }
    @player_surroundings = PlayerSurroundings.new(options)
  end

  def survey_immediate_surroundings
    @player_surroundings.feel_around_for_units
    @player_surroundings.feel_around_for_stairs_and_walls
    @player_surroundings.feel_around_for_empty_space
  end

  def warrior_action
    enemy_direction = @player_surroundings.enemy_directions.first
    captive_direction = @player_surroundings.captive_directions.first
    stairs_direction = @warrior.direction_of_stairs

    if captives_present_and_no_adjacent_enemies?
      walk_to_captive
    elsif multiple_adjacent_unbound_enemies?
      bind_enemy(enemy_direction)
    elsif one_adjacent_unbound_enemy?
      attack_enemy(enemy_direction)
    elsif adjacent_captive?
      captive_is_an_enemy?(captive_direction) ? attack_enemy_or_rest : rescue_captive(captive_direction)
    else
      walk_to(stairs_direction)
    end
  end

  def walk_to_captive
    captive_direction = @warrior.direction_of(@captive_spaces.first)
    navigate_around_stairs_towards(captive_direction)
  end

  def navigate_around_stairs_towards(captive_direction)
    if captive_direction != @player_surroundings.stairs_direction
      walk_to(captive_direction)
    else
      @player_surroundings.empty_directions.each do |empty_direction|
        empty_direction == @player_surroundings.stairs_direction ? next : walk_to(empty_direction)
      end
    end
  end

  def captives_present_and_no_adjacent_enemies?
    @captive_spaces.any? && @player_surroundings.captive_directions.empty? && @player_surroundings.enemy_directions.empty?
  end

  def multiple_adjacent_unbound_enemies?
    @player_surroundings.enemy_directions.any? && @player_surroundings.enemy_directions.size > 1
  end

  def one_adjacent_unbound_enemy?
    @player_surroundings.enemy_directions.size == 1
  end

  def attack_enemy_or_rest
    bound_enemy_direction = @player_surroundings.bound_enemy_directions.first
    warrior_is_injured? ? @warrior.rest! : attack_enemy(bound_enemy_direction)
  end

  def warrior_is_injured?
    @initial_warrior_health != @warrior.health
  end

  def adjacent_captive?
    @player_surroundings.captive_directions.any?
  end

  def captive_is_an_enemy?(direction)
    @player_surroundings.bound_enemy_directions.each do |bound_enemy_direction|
      return true if bound_enemy_direction == direction
    end

    false
  end

  def bind_enemy(direction)
    @player_surroundings.bound_enemy_directions << direction
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
    @player_surroundings.bound_enemy_directions = []
    @warrior.walk!(direction)
    return true
  end

end


#  -----
# |    S|
# |@> SC|
#  -----
