local AudioStreamState = require("moonloader").audiostream_state

local Sound = {
    new = function(name)
        local self = {}
        self.workingDirectory = getWorkingDirectory()
        
        self.sound = loadAudioStream(
            string.format(
                "%s/tch/resources/%s",
                self.workingDirectory,
                name
            )
        )

        self.play = function()
            setAudioStreamState(
                self.sound, 
                AudioStreamState.PLAY
            )
        end

        self.stop = function()
            setAudioStreamState(
                self.sound, 
                AudioStreamState.STOP
            )
        end

        return self
    end
}

return Sound