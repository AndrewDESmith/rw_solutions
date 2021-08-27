module BasicWarriorActions
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
    update_warrior_memory_of_surroundings(direction)
    @warrior.walk!(direction)
    return true
  end
end
