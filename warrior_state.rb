module WarriorState
  def warrior_is_injured?
    @initial_warrior_health != @warrior.health
  end

  def update_warrior_memory_of_surroundings(direction)
    @player_surroundings.bound_enemy_directions = []
    @player_surroundings.direction_of_last_player_position = direction
  end

  def direction_warrior_moved_from
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
end
