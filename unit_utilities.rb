module UnitUtilities
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

  def captive_is_an_enemy?(direction)
    @player_surroundings.bound_enemy_directions.each do |bound_enemy_direction|
      return true if bound_enemy_direction == direction
    end

    false
  end

  def captives_with_bombs?
    @captive_spaces_with_bombs.any?
  end
end
