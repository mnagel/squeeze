=begin
    squeeze - a simple game.
    Copyright (C) 2009 by Michael Nagel

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=end

# TODO make independent from squeeze

class SoundEngine
  # TODO fail gracefully
  def initialize
    pre = "sfx/squeeze/#{$SFX_PATH}/"
    puts "sounds from #{pre}"
    magic_buffer_size = 512
    SDL::Mixer.open(
      frequency=SDL::Mixer::DEFAULT_FREQUENCY,
      format=SDL::Mixer::DEFAULT_FORMAT,
      cannels=SDL::Mixer::DEFAULT_CHANNELS,
      magic_buffer_size)
    @sounds = {}
    @sounds[:create] = SDL::Mixer::Wave.load("#{pre}/create.wav")
    @sounds[:crash] = SDL::Mixer::Wave.load("#{pre}/crash.wav")
    @sounds[:levelup] = SDL::Mixer::Wave.load("#{pre}/levelup.wav")
    @sounds[:highscore] = SDL::Mixer::Wave.load("#{pre}/highscore.wav")
    @sounds[:gameover] = SDL::Mixer::Wave.load("#{pre}/gameover.wav")
  end

  def play snd
    SDL::Mixer.play_channel(1, @sounds[snd], 0)
  end
end
