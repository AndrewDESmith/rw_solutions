require "pry"
require "awesome_print"

class Player
  def play_turn(warrior)
    @captive_directions ||= scan_around(warrior, "captive")
    @enemy_directions ||= scan_around(warrior, "enemy")

    # Bind enemies before freeing captives.
    if @enemy_directions.any?
      bind_enemy(warrior, @enemy_directions.shift)
    elsif @captive_directions.any?
      rescue_captive(warrior, @captive_directions.shift)
    else
      # Now we are free to kill bound enemies in our path to the stairway.
      clear_enemies_from_stairway_path(warrior)
    end
  end

  def clear_enemies_from_stairway_path(warrior)
    direction = warrior.direction_of_stairs
    space = warrior.feel(direction)

    if space.enemy?
      warrior.attack!(direction)
    elsif space.empty?
      warrior.walk!(direction)
    else
      warrior.attack!(direction)
    end
  end


  def scan_around(warrior, target)
    directions = [:forward, :right, :backward, :left]
    target_directions = []

    directions.each do |direction|
      space = warrior.feel(direction)
      enemy_present = target == "enemy" && space.enemy?
      captive_present = target == "captive" && space.captive?

      if enemy_present || captive_present
        target_directions << direction
      end
    end

    return target_directions
  end

  def bind_enemy(warrior, direction)
    warrior.bind!(direction)
    return true
  end

  def rescue_captive(warrior, direction)
    warrior.rescue!(direction)
    return true
  end

end


#  ---
# |>s |
# |s@s|
# | C |
#  ---
