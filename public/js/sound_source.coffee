
class window.SoundSource

    constructor: ( value, audiolet ) ->

        @scale = new MinorScale()

        degree = Math.floor(value*32.0)
        # degree+=1 if degree % 7 is 6
        degree-=1 if degree % 7 is 1
        degree-=1 if degree % 7 is 5

        frequency = @scale.getFrequency degree, 65.4064, 1

        @wave = new Square audiolet, frequency
        @gain = new Multiply audiolet, 0
        @lfo1 = new Square audiolet, Math.pow(2,Math.floor(value*5))

        @lfopad = new Multiply audiolet, 0.05
        @sum = new Add audiolet
        @lpf = new LowPassFilter audiolet, 5000
        @pad = new Multiply audiolet, 1
        @pan = new Pan audiolet
        @env = new ADSREnvelope audiolet, 0, 0.01, 0.2, 0.2, 3.0

        @lfo2 = new Saw audiolet, Math.pow(2,Math.floor(value*5)-1)
        @lpfSideMult = new Multiply audiolet, -4000
        @lpfSideAdd = new Add audiolet, 9000

        @lfo2.connect @lpfSideMult
        @lpfSideMult.connect @lpfSideAdd
        @lpfSideAdd.connect @lpf, 0, 1

        @env.connect @sum
        @lfo1.connect @lfopad
        @lfopad.connect @sum, 0, 1
        @sum.connect @gain, 0, 1
        @wave.connect @lpf
        @lpf.connect @gain
        @gain.connect @pad
        @pad.connect @pan
        @pan.connect audiolet.output


    setVolume: (level) -> @pad.value.setValue Math.min(level,1.0)

    setPan: (pan) -> @pan.pan.setValue pan

    destroy: ->

        @wave.remove()
        @gain.remove()
        @lpfSideMult.remove()
        @lpfSideAdd.remove()
        @sum.remove()
        @lfo1.remove()
        @lfo2.remove()
        @lpf.remove()
        @pad.remove()
        @pan.remove()
        @env.remove()
