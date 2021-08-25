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
    @directions = [:forward, :right, :backward, :left]

    @occupied_spaces.each do |occupied_space|
      @captive_spaces << occupied_space if occupied_space.captive?
      @enemy_spaces << occupied_space if occupied_space.enemy?
    end

    occupied_directions = feel_around
    pp "@captive_directions"
    pp @captive_directions
    pp "@enemy_directions"
    pp @enemy_directions
    pp "occupied_directions"
    pp occupied_directions

    warrior_action
  end

  def warrior_action
    if captives_present_and_no_adjacent_enemies?
      captive_direction = @warrior.direction_of(@captive_spaces.first)
      walk_to(captive_direction)
    elsif multiple_adjacent_unbound_enemies?
      bind_enemy(@enemy_directions.first)
    elsif one_adjacent_unbound_enemy?
      attack_enemy(@captive_directions.first)
    elsif adjacent_captive?
      rescue_captive(@captive_directions.first)
    # All captives rescued and no enemies in path.
    else
      stairs_direction = @warrior.direction_of_stairs
      walk_to(stairs_direction)
    end
  end

  def captives_present_and_no_adjacent_enemies?
    @captive_spaces.any? && @captive_directions.empty? && @enemy_directions.empty?
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

  def feel_around
    @captive_directions = feel_for("captive")
    @enemy_directions = feel_for("enemy")
  end

  def feel_for(target)
    target_directions = []

    @directions.each do |direction|
      space = @warrior.feel(direction)
      enemy_present = target == "enemy" && space.enemy?
      captive_present = target == "captive" && space.captive?

      if enemy_present || captive_present
        target_directions << direction
      end
    end

    return target_directions
  end

  def bind_enemy(direction)
    @warrior.bind!(direction)
    return true
  end

  def attack_enemy(direction)
    @warrior.attack!(@enemy_directions.first)
    return true
  end

  def rescue_captive(direction)
    @warrior.rescue!(direction)
    return true
  end

  def walk_to(direction)
    @warrior.walk!(direction)
    return true
  end

end


#  ----
# |C s |
# | @ S|
# |C s>|
#  ----
