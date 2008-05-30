class String
  def score_for_string(test_string)
    score, location = 1.0, 0
    len = test_string.length
    self.split(//).each do |character_string|
      return 0 unless index = test_string.index(character_string)
      score -= (index - location)/test_string.length.to_f
      location = index + 1
      len = ((test_string.length - index)-1)
    end
    score -= len/test_string.length.to_f
    score
  end
end

