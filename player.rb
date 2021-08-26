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
    @captive_spaces_with_bombs = []
    @enemy_spaces = []
    occupied_spaces = warrior.listen

    # Extract this information into a MapSpaces class?
    occupied_spaces.each do |occupied_space|
      @captive_spaces << occupied_space if occupied_space.captive?
      @enemy_spaces << occupied_space if occupied_space.enemy?
      @captive_spaces_with_bombs << occupied_space if occupied_space.ticking?
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
    pp "@player_surroundings.stairs_direction"
    pp @player_surroundings.stairs_direction
    pp "@player_surroundings.enemy_directions"
    pp @player_surroundings.enemy_directions
    pp "@player_surroundings.wall_directions"
    pp @player_surroundings.wall_directions
    pp "@player_surroundings.stairs_direction"
    pp @player_surroundings.stairs_direction
  end


  def warrior_action
    adjacent_enemy_direction = @player_surroundings.enemy_directions.first
    adjacent_captive_direction = @player_surroundings.captive_directions.first
    stairs_direction = @warrior.direction_of_stairs

    # Prioritize captive rescue over enemies.
    if captives_present?
      return true if rescue_captives_with_bombs

      if !adjacent_captives? && !adjacent_enemies
        walk_to_captive
      end
    end

    # Can now slay enemies if there are no captives with bombs left.
    if enemies_present?
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
    else
      # No enemies or captives left.
      walk_to(stairs_direction)
    end

  end

  # I never thought that I'd be writing methods like this in Ruby, but here we are.
  def rescue_captives_with_bombs
    # Rescue any immediately adjacent captives.
    if @player_surroundings.captive_directions.any?
      rescue_captive(@player_surroundings.captive_directions.first)
      return true
    else
      # Navigate around enemies and stairs towards the captive with the bomb.
      captive_with_bomb_direction = @warrior.direction_of(@captive_spaces_with_bombs.first)
      navigate_around_all_obstacles_towards(captive_with_bomb_direction)
    end
  end

  def navigate_around_all_obstacles_towards(captive_with_bomb_direction)
    navigate_around_stairs_towards(captive_with_bomb_direction)
  end

  def walk_to_captive
    captive_direction = @warrior.direction_of(@captive_spaces.first)
    navigate_around_stairs_towards(captive_direction)
  end

  def navigate_around_stairs_towards(captive_direction)
    empty_directions = @player_surroundings.empty_directions
    obstacle_directions = @player_surroundings.enemy_directions + @player_surroundings.wall_directions
    possible_directions = []

    # Head towards captive if no stairs are in the way.
    if captive_direction != @player_surroundings.stairs_direction
      # (1) Walk around enemies and walls.
      # (2) Don't walk back the way you came. (use a direction of last move variable).

      # No obstacles in the way of the captive's direction.
      if !obstacle_directions.include?(captive_direction)
        walk_to(captive_direction)
      else
        # Search for an alternative path with empty directions, but don't walk back the way you came.
        empty_directions.each do |empty_direction|
          possible_directions << empty_direction if empty_direction != direction_player_moved_from
        end

        # Prefer captive direction
        if possible_directions.include?(captive_direction)
          walk_to(captive_direction)
        else
          walk_to(possible_directions.first)
        end
      end
    else
      # Walk around stairs.
      empty_directions.each do |empty_direction|
        empty_direction == @player_surroundings.stairs_direction ? next : walk_to(empty_direction)
      end
    end
  end

  def direction_player_moved_from
    case @player_surroundings.direction_of_last_player_position
    when :forward
      :backward
    when :right
      :left
    when :backward
      :forward
    when :left
      :right
    end
  end

  def captives_present?
    @captive_spaces.any?
  end

  def enemies_present?
    @enemy_spaces.any?
  end

  def adjacent_enemies?
    @player_surroundings.enemy_directions.any?
  end

  def adjacent_captives?
    @player_surroundings.captive_directions.any?
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
    @player_surroundings.direction_of_last_player_position = direction
    pp "@player_surroundings.direction_of_last_player_position"
    pp @player_surroundings.direction_of_last_player_position
    @warrior.walk!(direction)
    return true
  end

end


#  ------
# |Cs   >|
# |@  sC |
#  ------
