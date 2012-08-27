# -*- coding: utf-8 -*-

require 'date'

module Eraser
  module Horoscopes
    CONSTELLATIONS = [
      :capricorn,
      :aquarius,
      :pisces,
      :aries,
      :taurus,
      :gemini,
      :cancer,
      :leo,
      :virgo,
      :libra,
      :scorpius,
      :sagittarius,
    ]

    def self.astrology(date)
      i = date.strftime('%m%d').to_i
      return CONSTELLATIONS[ 0] if i <=  120
      return CONSTELLATIONS[ 1] if i <=  218
      return CONSTELLATIONS[ 2] if i <=  320
      return CONSTELLATIONS[ 3] if i <=  419
      return CONSTELLATIONS[ 4] if i <=  520
      return CONSTELLATIONS[ 5] if i <=  621
      return CONSTELLATIONS[ 6] if i <=  722
      return CONSTELLATIONS[ 7] if i <=  823
      return CONSTELLATIONS[ 8] if i <=  922
      return CONSTELLATIONS[ 9] if i <= 1023
      return CONSTELLATIONS[10] if i <= 1122
      return CONSTELLATIONS[11] if i <= 1221
      return CONSTELLATIONS[ 0] if i <= 1231
      raise 'must not happen'
    end

    def self.horoscopes(date = Date.today)
      CONSTELLATIONS.shuffle(random: Random.new(date.strftime('%Y%m%d').to_i))
    end
  end
end
