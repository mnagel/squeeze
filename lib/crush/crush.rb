=begin

  make a fork of squeeze and put the following code in the mouse_down event:

  def crush_game
    $engine.thing_not_to_intersect.each do |t|
      t.v += (t.pos - $engine.m.pos).unit * 0.5
    end
  end

  caveats:
  - scale for distance
  - before calling /unit/ make sure its not zero length...
=end
